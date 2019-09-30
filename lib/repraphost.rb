require 'rubygems'
require 'serialport'
require 'thread'
require 'gcode'
require 'fakereprap'
require 'matrix'

# credits
# inspired by 
#    RepRapArduinoSender.py
#    https://github.com/ErikDeBruijn/ReplicatorG-Erik5D
#    Erik de Bruijn
#
#    printcore.py
#    https://github.com/kliment/Printrun/blob/master/printcore.py
#    Kliment

Thread.abort_on_exception = true 

class RepRapHost
  attr_accessor :verbose, :echoreadwrite, :temp_deviation, :temp_stabilize_time,
                :tempcb, :recvcb, :sendcb, :errorcb, :startcb, 
                :pausecb, :resumecb, :endcb, :onlinecb, :progresscb,
                :abortcb, :preheatcb, :preheatedcb, :emergencystopcb,
                :psuoncb, :psuoffcb, :eepromcb, :fwcb, :autolevelfailcb, :doorcb,
                :maintenance_position
  attr_reader :online, :printing, :paused, :lastresponse, :progress,
              :current_params, :endstopstatus, :time_remaining
  alias :online? :online
  alias :printing? :printing
  alias :paused? :paused
  
  def initialize(port = nil, baud = nil)  
    # Initializes a printer instance. Pass the port and baud rate to connect immediately
    @baud = nil
    @port = nil
    @printer = nil #Serial instance connected to the printer, nil when disconnected
    @verbose = true
    @echoreadwrite = false # print all sent commands and received messages on stdout
    @lastresponse = ""
    @printqueue = Array.new
    @gcodefile = nil
    @printing = false
    @preheating = false
    @paused = false
    @online = false
    @progress = 0
    @time_remaining = nil
    @timejobstarted = nil
    @lines = 0 # number of lines of the gcodefile that is printing
    @current_duration = 0 # calculated duration the print must have elapsed
    @print_duration = 0 # calculated duration the print will take
    @duration_calculated = false
    @serialport_read_timeout = 0

    # hide print time estimate until a sufficient number of G1 commands were taken into account
    # --> to prevent large estimate deviations at the beginning of a print
    @g1_to_skip_for_time_estimate = 30               
    @g1count = 0
    
    # for preheating: deviation around target temperature to accept as preheated
    @temp_deviation = 2           # in +/- °C
    @temp_update_interval = 1     # in sec
    @temp_stabilize_time = 3      # in sec, temp needs to stay withing deviation for this time

    @maintenance_position = { :x => 0,
                              :y => 0,
                              :z => 10000 }  # just a large number in case this value is not set
                                             # during initialization (it should!)
    
    # current parameters of printer 
    @current_params = Hash.new   
    @current_params[:current_temps] = {
      :T0 => 0,
      :T1 => 0,
      :T2 => 0,
      :B  => 0 }
    @current_params[:target_temps] = {
      :T0 => 0,
      :T1 => 0,
      :T2 => 0,
      :B  => 0 }
    @current_params[:active_extruder] = :T0
    @current_params[:e_position] = 0
    @current_params[:retraction_distance] = 0
    @current_params[:feedrate] = nil   
    @current_params[:psu_on] = false 

    # snapshot of current params for resume
    @params_for_resume = nil  

    # enstop status from last M119 response. Is set to after sending M119 while waiting for new response
    @endstopstatus = nil
                 
    # callbacks
    @tempcb = nil
    @recvcb = nil
    @sendcb = nil
    @errorcb = nil
    @startcb = nil
    @endcb = nil
    @onlinecb = nil
    @pausecb = nil
    @abortcb = nil
    @preheatcb = nil # on M109/M190 start
    @preheatedcb = nil # on M109/M190 target temp reached
    @emergencystopcb = nil
    @psuoncb = nil # on M80 power supply on
    @psuoffcb = nil # on M81 power supply off
    @eepromcb = nil # on response lines to M205 (show eeprom values)
    @fwcb = nil # on response to M115 (capabilities string including firmware version)
    @autolevelfailcb = nil # on G32 autolevel errors
    @doorcb = nil # on DoorSwitch open/close info from firmware
    @progresscb = nil

    # thread sync and helpers
    @ok_queue = Queue.new
    @stop_send_thread = false
  
    unless port.nil? or baud.nil?
      self.connect(port, baud)
    end    
  end
  
  def connect(port = nil, baud = nil)
    # Set port and baudrate if given, then connect to printer
    self.disconnect if @printer
    @port = port unless port.nil?
    @baud = baud unless baud.nil?
    
    Rails.logger.info "Connecting to RepRap Controller (#{@port})" if @verbose
    @errorcb.call("Could not connect to RepRap Controller - no port defined!") if @errorcb and @port.nil?
    @errorcb.call("Could not connect to RepRap Controller - no baudrate defined!") if @errorcb and @baud.nil?    
    unless @port.nil? or @baud.nil?
      begin
        # export "SIMULATE=true" as ENV variable to the rails server in order to start the simulated
        # serial link - otherwise connect via serial as usual
        if ENV['SIMULATE']
          @printer = FakeRepRap.new(@port, @baud, 8, 1, SerialPort::NONE)
        else
          @printer = SerialPort.new(@port, @baud, 8, 1, SerialPort::NONE)
          @printer.read_timeout= @serialport_read_timeout
        end
        
        tries = 0
        while not @online
          # start read loop in seperate thread
          @read_thread.kill if @read_thread
          @read_thread = Thread.new { self.read_loop }

          # reset firmware
          if tries < 5
            tries += 1
            self.reset
          else
            raise "Could not connect, Firmware not responding"
          end
          
          # wait for successful reset
          10.times do
            break if @online
            sleep 0.5
          end
        end

        @send_thread = Thread.new { self.send_loop }
        @temp_thread = Thread.new { self.temp_loop }
      rescue Errno::ENOENT => e
        Rails.logger.error "Could not open file (Invalid Port?)"
#        @errorcb.call("Could not open file (Invalid Port?)") if @errorcb
      rescue IOError => e
        Rails.logger.error "Could not write to file"
#        @errorcb.call("Could not write to file") if @errorcb
      rescue => e
        Rails.logger.error "Other Error:"
        Rails.logger.error e
#        @errorcb.call(e.to_s) if @errorcb
      end
    end
  end
  
  def disconnect
    # Disconnects from printer
    self.abort_print if @printing
    @online = false
    @send_thread.kill
    @read_thread.kill
    if @printer
      @printer.close
    end
    @printer = nil
    @printqueue = Array.new
  end
  
  def reset
    initiate_abort_thread = Thread.new do
      self.abort_print if @printing
    end    
    
    @online = false
  
    # send M112 to initiate a firmware reboot
    Rails.logger.info 'resetting firmware' if @verbose
#    begin
#      @printer.write("M112\n") if @printer
#    rescue => e
#      Rails.logger.error "failed to reset firmware:"
#      Rails.logger.error e
#    end

    # Toggle KILL pin on Repetier Firmware via shared GPIO (gpio32 <--> pin 40)
    output = `echo 0 > /sys/class/gpio/gpio32/value`
    sleep 0.1
    output = `echo 1 > /sys/class/gpio/gpio32/value`

  end
  
  def read_loop
    loop do
      begin
        line = @printer.readline 
        # soemtimes the start string occurs as "\u0000start\n" on first connect             
        line.delete!("\0")
        # strip all leading whitespaces
        line.lstrip!

        if line.start_with?('start')
          if @printing
            abort_on_reset_thread = Thread.new do
                self.abort_print
            end
          end              
          @online = true   
          @onlinecb.call if @onlinecb

          # make sure build chamber is deactivated after a reset
          self.send("M81\n")        
        end
  
        if line.start_with?('ok') or line.start_with?('wait')
          # signal waiting thread that 'ok' was received              
          @ok_queue.push :ok if @ok_queue.empty?
        end

        unless (line.length == 0) or line.start_with?('wait') or (@printing and line.start_with?('ok'))
          Rails.logger.debug "<<< " + line if @verbose and @echoreadwrite
          @lastresponse = line
          
          unless line.start_with?('Resend') or line.start_with?('ok') or line.start_with?('ok T:') or line.start_with?('T:')
            @recvcb.call(line) if @recvcb            
          end
        end

        if line.start_with?('fatal:G32 leveling failed!')
          if @printing
            autolevelfail_abort_thread = Thread.new do
                self.abort_print
            end
          end
          
          @autolevelfailcb.call if @autolevelfailcb

          # unlock fatal state with M999
          self.send("M999\n")
          # make sure motors are activated again and home axes
          self.send("M80\n")
          self.send("M99 X0 Y0 Z0 S0\n")
          self.send("G4 P2000\n")
          self.send("G28\n")
        end

        # trigger callback if door is opened
        if line.start_with?('DoorSwitch:open')
          @doorcb.call(:open) if @doorcb
        elsif line.start_with?('DoorSwitch:closed')
          @doorcb.call(:closed) if @doorcb
        end


        # Temperature parsing and callback
        if line.start_with?('ok T:') or line.start_with?('T:')
          begin
            t0 = line.scan(/T0:\-?\s*\d+\.\d+\s\/\d+/)[0]
            t1 = line.scan(/T1:\-?\s*\d+\.\d+\s\/\d+/)[0]
            t2 = line.scan(/T2:\-?\s*\d+\.\d+\s\/\d+/)[0]
            b = line.scan(/B:\-?\s*\d+\.\d+\s\/\d+/)[0]

            t0_temps = t0.match(/T0:(?<temp>\-?\s*\d+\.\d+)\s\/(?<target>\d+)/)
            t1_temps = t1.match(/T1:(?<temp>\-?\s*\d+\.\d+)\s\/(?<target>\d+)/)
            t2_temps = t2.match(/T2:(?<temp>\-?\s*\d+\.\d+)\s\/(?<target>\d+)/)
            b_temps = b.match(/B:(?<temp>\-?\s*\d+\.\d+)\s\/(?<target>\d+)/)

            @current_params[:current_temps] = {
              :T0 => t0_temps[:temp].to_f,
              :T1 => t1_temps[:temp].to_f,
              :T2 => t2_temps[:temp].to_f,
              :B => b_temps[:temp].to_f
            }

            @current_params[:target_temps] = {
              :T0 => t0_temps[:target].to_i,
              :T1 => t1_temps[:target].to_i,
              :T2 => t2_temps[:target].to_i,
              :B => b_temps[:target].to_i
            }
          rescue => e
            Rails.logger.error "Error in Temp-String RegEx"
            Rails.logger.error e.inspect
          end          

          @tempcb.call(@current_params[:current_temps], @current_params[:target_temps]) if @tempcb
        end

        if line.start_with?('important:Extruder jam detected')
          # unlock jam state with M513 (mark all extruders unjammed)
          self.send("M513\n")
        end
       
        # act on firmware initiated pause requests (like filament jam messages)
        if line.start_with?('RequestPause:')
          result = /^RequestPause:(?<message>.*)/.match(line)
          if @printing and result
            # initiate pause_print from within its own thread to keep the read_thread spinning
            # (otherwise the reactivated send_thread will stall, naturally)
            initiate_pause_thread = Thread.new do
              self.pause_print(result[:message])
            end
          end
        end

        # check for responses containing EEPROM config values
        if line.start_with?('EPR:')
          result = /^EPR:(?<type>\d) (?<pos>\d+) (?<val>-?\d+(\.\d+)?) (?<name>.+)/.match(line)

          if result and result[:type] and result[:pos] and result[:val] and result[:name]
            config = {
              :type => result[:type].to_i,
              :pos => result[:pos].to_i,
              :val => result[:val].to_f,
              :name => result[:name]
            }
            @eepromcb.call(config) if @eepromcb
          end
        end

        # check if firmware capabilities string was sent (response to M115)
        if line.start_with?('FIRMWARE_NAME')
          result = /KUEHLINGKUEHLING_FIRMWARE_VERSION:(?<version>\S*)/.match(line)
          if result and result[:version]
            @fwcb.call(result[:version]) if @fwcb
          end
        end

        # parse for M119 Endstop status response
        if line.start_with?('endstops hit:')
          result = /^endstops hit: x_min:(?<x>[LH]).*y_max:(?<y>[LH]).*z_max:(?<z>[LH])/.match(line)
          if result and result[:x] and result[:y] and result[:z]
            @endstopstatus = {:x => result[:x],
                              :y => result[:y],
                              :z => result[:z]}
          end
        end
      rescue EOFError => e
        Rails.logger.error "DEBUG: EOF from serialport readline"
        # do nothing - sometimes serialport sends EOF when done sending stuff
        Rails.logger.error e.inspect
        @errorcb.call("EOF from serialport readline") if @errorcb
        return nil
      rescue ArgumentError => e
        Rails.logger.error "While reading from Printer: ArgumentError"
        # do nothing - sometimes serialport sends EOF when done sending stuff
        Rails.logger.error e.inspect
        @errorcb.call(e.to_s) if @errorcb        
      rescue => e
        Rails.logger.error "Can't read from printer (disconnected?)."
        Rails.logger.error e.inspect
        @errorcb.call("Can't read from printer (disconnected?).") if @errorcb
        @errorcb.call(e.to_s) if @errorcb
        return nil
      end      
    end
    line
  end
  
  def write(line, execsendcb = false)
    # sends a gcode command to the printer
    # ! do not use directly, as this would interfere
    # ! with a running printjob.
    # ! use 'send' insted.

    unless line.nil? or line.start_with?("ok")
      if line = line.split(";")[0] # remove comments
      
        line.lstrip! # remove whitespace from start
        line.rstrip! # remove whitespace from end
    
        return if line.length == 0    
        
        line = line.upcase
        
        return unless line.start_with?("M", "G", "T")

        # catch M73 progress information. Issue the callback and do not
        # send this to the firmware
        # Progress parsing and callback
        if line.start_with?('M73')
          begin
            prog = line.match(/M73 P(?<percent>\d+)\sR(?<remaining>\d+).*/)
            @progress = prog[:percent].to_i
            @time_remaining = prog[:remaining].to_i
          rescue => e
            Rails.logger.error "Error in Progress-String RegEx"
            Rails.logger.error e.inspect
          end          

          @progresscb.call(@progress, @time_remaining) if @progresscb
          return
        end

        # catch M190/M109 and its parameters and substitute
        # with M140/M104 to avoid arduino locking up during preheating
        # (preheating is instead implemented in @preheat_thread)
        if line.start_with?("M109")
          target_temp = line.match(/.*S(\d+).*/)
          heater = line.match(/.*(T\d).*/)

          if target_temp and target_temp[1] and target_temp[1].to_i > 0
            if heater and heater[1]
              heater = heater[1].to_sym
            else
              heater = @current_params[:active_extruder]
            end

            target_temp = target_temp[1].to_i
            preheat = true if @printing
          end
          
          line.sub!("M109", "M104")          
        end
        if line.start_with?("M190")
          target_temp = line.match(/.*S(\d+).*/)

          if target_temp and target_temp[1] and target_temp[1].to_i > 0
            target_temp = target_temp[1].to_i
            heater = :B
            preheat = true if @printing
          end

          line.sub!("M190", "M140")         
        end        
        # for M109 and M190 we need to wait for empty command buffer (M400) on arduino
        # so we know exactly when temperatures will be set - for timing the @preheat_thread
        if preheat
          self.write("M400", execsendcb)
        end        

        # remember PSU state (on/off) from M80/M81
        if line.start_with?("M80")
          @current_params[:psu_on] = true
          @psuoncb.call if @psuoncb
        end
        if line.start_with?("M81")
          @current_params[:psu_on] = false
          @psuoffcb.call if @psuoffcb
        end

        # remember active extruder
        if result = /^(?<extruder>T\d)/.match(line)
          @current_params[:active_extruder] = result[:extruder].to_sym
        end
        
        # remember current extruder position and current feedrate
        if line.start_with?("G1")
          if result = / E(?<position>\d+\.?\d*)/.match(line)
            if @current_params[:e_position] > result[:position].to_f
              @current_params[:retraction_distance] = @current_params[:e_position] - result[:position].to_f
            else
              @current_params[:retraction_distance] = 0
            end
            
            @current_params[:e_position] = result[:position].to_f
          end
          
          if result = / F(?<feedrate>\d+\.?\d*)/.match(line)
            @current_params[:feedrate] = result[:feedrate].to_f
          end        
        end

        if line.start_with?("M119")
          @endstopstatus = nil # to indicate that we are waiting for a new response
        end

        unless line.start_with?("M105")
          Rails.logger.debug ">>> " + line if @verbose and @echoreadwrite
          @sendcb.call(line) if @sendcb and execsendcb
        end
        
        # write command to arduino
        begin
          @printer.write(line + "\n")
        rescue => e
          @errorcb.call("Can't write to printer!") if @errorcb
          @errorcb.call(e.to_s) if @errorcb
        end
    
        # wait for read_loop thread to signal that 'ok' was received    
        @ok_queue.pop

        # start @preheat_thread for M109/M190
        if preheat               
          @preheating = true # to stop send_thread or print_thread
          @preheat_thread = Thread.new(heater, target_temp) { |h,t| self.preheat_loop(h, t) }
        end
      end
    end
  end

  def preheat_loop(heater, target_temp)
    # loop waiting for preheat target temperatures to be reached
    # @print_thread or @send_thread are suspended by @preheating and resume afterwards
    # used in @preheat_thread

    @preheatcb.call if @preheatcb    
    
    stabilize_cycles = 0
    target_range = (target_temp - @temp_deviation)..(target_temp + @temp_deviation)
    while not (stabilize_cycles >= (@temp_stabilize_time / @temp_update_interval ))
      if target_range.include?(@current_params[:current_temps][heater])
        stabilize_cycles += 1
      else
        stabilize_cycles = 0
      end

      break if @paused or @aborted

      # get temperatures
      self.write("M105")
      sleep @temp_update_interval
    end

    @preheating = false
    @preheatedcb.call if @preheatedcb

    # restart print_thread
    @print_thread.run
    Thread.exit
  end

  def send(line)
    # Send a single gcode command to the @printqueue

    if @online
        if line.start_with?("M119")
          @endstopstatus = nil # to indicate that we are waiting for a new response
        end      
      @printqueue.push(line)
    else
      @errorcb.call("Cannot send command - RepRap Controller not online!") if @errorcb      
    end
  end
  
  def send_loop
    # loop sending commands from @printqueue if not printing
    # used in @send_thread
    
    loop do
      if @printing
        Thread.stop
      end
      
      if @printqueue.length > 0
        line = @printqueue.shift

        self.write(line, true)      
      else
        sleep 0.1
      end
    end
  end

  def temp_loop
    # loop sending M105 to receive current temperatures
    # once every second - unless another M105 is still in @printqueue
    # used in @temp_thread
    
    loop do
      @printqueue.push("M105") unless @printqueue.include?("M105")
      
      if @printing
        # reduce serial bandwidth usage during print - only update every 3 seconds
        sleep 3
      else
        sleep @temp_update_interval
      end
    end
  end
  
  def print_loop
    # loop printing from a @gcodefile, also sending
    # commands from @printqueue in between.
    # used in @print_thread
    
    @progress = 0
    @duration_calculated = false

    # the actual loop
    while line = @gcodefile.gets

      # send commands from print queue first
      while cmd = @printqueue.shift
        self.write(cmd, true)
        
        if @preheating
          Thread.stop
        end        
      end

      # then continue with next line from gcode file
      self.write(line) unless line.start_with?("M206")  # NEVER set M206 EEPROM values from within print job!

      if @preheating
        Thread.stop
      end      

      if @aborted
        @printing = false
        @send_thread.run            
        Thread.exit
      end

      if @paused
        @printing = false
        @send_thread.run
        Thread.stop
      end
      
    end
    
    @progress = 0
    @time_remaining = nil
    @progresscb.call(@progress, @time_remaining)
    @printing = false
    @gcodefile.close
    @gcodefile = nil
    @lines = 0
    Rails.logger.debug "Print finished!" if @verbose
    @endcb.call(self.time_elapsed) if @endcb
    @send_thread.run
  end
  
  def time_elapsed
    if @timejobstarted
      (( Time.now - @timejobstarted ) / 60 )
    else
      nil
    end
  end
  
  def start_print(gcodefilename)
    # Opens a file for printing as @gcodefile File object.
    # The @print_thread then steps through the gcode file line by line
    if not @online
      @errorcb.call("Cannot start the printjob - RepRap Controller not online!") if @errorcb
    elsif @printing
      @errorcb.call("Cannot start the printjob - already printing!") if @errorcb
    else
      begin
        @timejobstarted = Time.now
        @gcodefile = File.open(gcodefilename, 'r')
        # start seperate thread for printing
             
        @printing = true
        sleep 0.1 until @send_thread.stop?

        @print_thread = Thread.new { self.print_loop }
        @startcb.call if @startcb
      rescue => e
        Rails.logger.error "Error while starting print of file " + (gcodefilename ? gcodefilename : "NO FILE SUPPLIED")
        Rails.logger.error e
        @errorcb.call("Error opening GCODE file " + (gcodefilename ? gcodefilename : "NO FILE SUPPLIED")) if @errorcb
        @errorcb.call(e.to_s) if @errorcb
      end      
    end
  end
  
  def pause_print(message="")
    if @printing and not @paused
      # invoke a thread stop inside @print_thread
      @paused = true 
      sleep 0.1 until not @printing

      # deep-copy printer parameters for resume
      @params_for_resume = Marshal.load(Marshal.dump(@current_params))
      @pausecb.call(message) if @pausecb
      
      # store last printing position
      self.send("M400")
      self.send("M401")

      # move print head away from object, print head to maintenance position,
      #  and turn off extruders, bed and chamber stay untouched
      self.send("G1 Z#{@maintenance_position[:z]} F12000.0")
      self.send("G1 X#{@maintenance_position[:x]} Y#{@maintenance_position[:y]} F12000.0")
      self.send("M104 S0 T0")
      self.send("M104 S0 T1")
    else
      errorcb.call("Nothing to pause, printer isn't printing right now!") if @errorcb
    end
  end
  
  def resume_print
    if @paused and not @printing
      @paused = false
      @printing = true
      sleep 0.1 until @send_thread.stop?

      @resumecb.call if @resumecb
      
      # reset all extruder temperatures and bed temp to stored values 
      @params_for_resume[:target_temps].each do |heater, temp| 
        if heater == :B
          self.send("M190 S#{ temp }")
        elsif heater == :T2   # do not wait for chamber temp
          self.send("M104 S#{ temp } #{ heater.to_s }")
        else
          self.send("M109 S#{ temp } #{ heater.to_s }")
        end
      end

      # select extruder, that was active before pause
      self.send(@params_for_resume[:active_extruder].to_s)
      
      # restore extruder retraction state
      if @params_for_resume[:retraction_distance] > 0
        self.send("G92 E0")
        self.send("G1 E-#{ @params_for_resume[:retraction_distance] } 70")
      end
      
      # set current extruder value to last seen value
      # so subsequent gcodes can continue from here
      self.send("G92 E#{ @params_for_resume[:e_position] }")
      
      # move to last stored printing position
      self.send("G1 F6000.0")
      self.send("M402")

      # restore feedrate last used
      if @params_for_resume[:feedrate]
        self.send("G1 F#{ @params_for_resume[:feedrate] }")
      end

      @print_thread.run
    else
      errorcb.call("Nothing to resume, printer isn't paused right now!") if @errorcb
    end
  end
  
  def abort_print
    # stops the print
    if (@printing or @paused) and not @aborted
      @aborted = true
      sleep 0.1 until not @printing
      @aborted = false
      @paused = false
      @gcodefile.close
      @gcodefile = nil
      @abortcb.call if @abortcb
      @endcb.call(self.time_elapsed) if @endcb 
      @progress = 0
      @timejobstarted = nil
      @time_remaining = nil
      @progresscb.call(@progress, @time_remaining)   

      # home all axes
      self.send("G28")
      
      # disable extruders
      self.send("M104 S0 T0")
      self.send("M104 S0 T1")

      # disable vacuum
      self.send("M42 P35 S0")      
          
    else
      @errorcb.call("Cannot abort print - not printing right now!") if @errorcb
    end
  end

  def emergencystop
    if not @emergencystop
      @emergencystop = true
      @emergencystopcb.call if @emergencystopcb
      @emergencystop = false    

      self.reset
      
      @current_params[:psu_on] = false
      @psuoffcb.call if @psuoffcb
    end
  end

  def status
    # Status
    # 0: Offline
    # 1: Idle
    # 2: Printing
    # 3: Paused
    # 4: Emergency Stop
    # 5: Preheating

    status = 0 # offline

    if @emergencystop
      status = 4 # emergency stop      
    elsif @online
      if @preheating    
        status = 5 # preheating      
      elsif @paused
        status = 3 # paused
      elsif @printing
        status = 2 # printing        
      else
        status = 1 # idle
      end
    end

    status    
  end

end

