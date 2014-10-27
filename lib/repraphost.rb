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
                :pausecb, :resumecb, :endcb, :onlinecb, :reloadcb,
                :abortcb, :preheatcb, :preheatedcb, :emergencystopcb,
                :psuoncb, :psuoffcb, :eepromcb
  attr_reader :online, :printing, :paused, :lastresponse, :progress,
              :current_params
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
    @timejobstarted = nil
    @timeprintstarted = nil # after 30 lines preheating is usually over, so we assume print start here
    @lines = 0 # number of lines of the gcodefile that is printing
    @current_duration = 0 # calculated duration the print must have elapsed
    @print_duration = 0 # calculated duration the print will take
    @duration_calculated = false
    
    # hide print time estimate until a sufficient number of G1 commands were taken into account
    # --> to prevent large estimate deviations at the beginning of a print
    @g1_to_skip_for_time_estimate = 30               
    @g1count = 0
    
    # for preheating: deviation around target temperature to accept as preheated
    @temp_deviation = 2           # in +/- °C
    @temp_update_interval = 1     # in sec
    @temp_stabilize_time = 3      # in sec, temp needs to stay withing deviation for this time
    
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
                 
    # callbacks
    @tempcb = nil
    @recvcb = nil
    @sendcb = nil
    @errorcb = nil
    @startcb = nil
    @endcb = nil
    @onlinecb = nil
    @pausecb = nil
    @reloadcb = nil # on filament empty, deliveres :left or :right as parameter
    @abortcb = nil
    @preheatcb = nil # on M109/M190 start
    @preheatedcb = nil # on M109/M190 target temp reached
    @emergencystopcb = nil
    @psuoncb = nil # on M80 power supply on
    @psuoffcb = nil # on M81 power supply off
    @eepromcb = nil # on response lines to M205 (show eeprom values)
    
    # thread sync
    @printer_lock = Mutex.new
    @ok_lock = Mutex.new    
    @ok = ConditionVariable.new
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
    
    puts 'Connecting to RepRap Controller' if @verbose
    @errorcb.call("Could not connect to RepRap Controller - no port defined!") if @errorcb and @port.nil?
    @errorcb.call("Could not connect to RepRap Controller - no baudrate defined!") if @errorcb and @baud.nil?    
    unless @port.nil? or @baud.nil?
      begin
        #@printer = FakeRepRap.new(@port, @baud, 8, 1, SerialPort::NONE)
        @printer = SerialPort.new(@port, @baud, 8, 1, SerialPort::NONE)
        
        while not @online
          # start read loop in seperate thread
          @read_thread.kill if @read_thread
          @read_thread = Thread.new { self.read_loop }

          # reset firmware
          self.reset
          
          # wait for successful reset
          10.times do
            break if @online
            sleep 0.5
          end
        end

        @send_thread = Thread.new { self.send_loop }
        @temp_thread = Thread.new { self.temp_loop }
      rescue Errno::ENOENT => e
        puts "Could not open file (Invalid Port?)"
#        @errorcb.call("Could not open file (Invalid Port?)") if @errorcb
      rescue IOError => e
        puts "Could not write to file"
#        @errorcb.call("Could not write to file") if @errorcb
      rescue => e
        puts "Other Error:"
        puts e
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
    self.abort_print if @printing
    @online = false
  
    # setting DTR line high to initiate a firmware reboot
    puts 'resetting firmware' if @verbose
    @printer.dtr = 1
    sleep 1
    @printer.dtr = 0    
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
          self.abort_print if @printing              
          @online = true             
          @onlinecb.call if @onlinecb
        end
  
        if line.start_with?('ok') or line.start_with?('wait')
          # signal waiting thread that 'ok' was received              
          @ok_lock.synchronize {                  
            @ok.signal
          }              
        end

        unless (line.length == 0) or line.start_with?('wait') or (@printing and line.start_with?('ok'))
          puts "<<< " + line if @verbose and @echoreadwrite
          @lastresponse = line
          
          unless line.start_with?('Resend') or line.start_with?('ok') or line.start_with?('ok T:') or line.start_with?('T:')
            @recvcb.call(line) if @recvcb            
          end
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
            puts "Error in Temp-String RegEx"
            puts e.inspect
          end          

          @tempcb.call(@current_params[:current_temps], @current_params[:target_temps]) if @tempcb
        end
       
        # act on out-of-filament messages
        if line.start_with?('OutOfFilament')
          result = /^OutOfFilament:(?<spool>\w+)/.match(line)
          @reloadcb.call(result[:spool]) if @reloadcb and @printing
        end

        # check for responses containing EEPROM config values
        if line.start_with?('EPR:')
          result = /^EPR:(?<type>\d) (?<pos>\d+) (?<val>-?\d+(\.\d+)?) (?<name>.+)/.match(line)

          if result[:type] and result[:pos] and result[:val] and result[:name]
            config = {
              :type => result[:type].to_i,
              :pos => result[:pos].to_i,
              :val => result[:val].to_f,
              :name => result[:name]
            }
            @eepromcb.call(config) if @eepromcb
          end
        end
      rescue EOFError => e
        puts "DEBUG: EOF from serialport readline"
        # do nothing - sometimes serialport sends EOF when done sending stuff
        puts e.inspect
        @errorcb.call("EOF from serialport readline") if @errorcb
        return nil
      rescue ArgumentError => e
        puts "While reading from Printer: ArgumentError"
        # do nothing - sometimes serialport sends EOF when done sending stuff
        puts e.inspect
        @errorcb.call(e.to_s) if @errorcb        
      rescue => e
        puts "Can't read from printer (disconnected?)."
        puts e.inspect
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

        unless line.start_with?("M105")
          puts ">>> " + line if @verbose and @echoreadwrite
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
        @ok_lock.synchronize {        
          @ok.wait(@ok_lock)
        }

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

    # calculate printjob duration in background thread
    @print_duration = 0
    @current_duration = 0

    @calc_duration_thread = Thread.new do
      last_coord = nil
      new_coord = [0, 0, 0]
      feedrate = nil
      g1_count = 0
      file = File.open(@gcodefile.path,'r')# @gcodefile.dup
      file.each_line do |line|
        gcode = Gcode.new(line)
        feedrate = gcode.f if gcode.f
      
        if gcode.g?(1) and feedrate and ( gcode.x or gcode.y or gcode.z )
          g1_count += 1
          new_coord[0] = gcode.x if gcode.x
          new_coord[1] = gcode.y if gcode.y
          new_coord[2] = gcode.z if gcode.z

          if last_coord and g1_count > @g1_to_skip_for_time_estimate
            segment = Vector.elements([
              new_coord[0] - last_coord[0],
              new_coord[1] - last_coord[1],
              new_coord[2] - last_coord[2]])
         
            segment_duration = segment.norm / (feedrate / 60)
            @print_duration += segment_duration
          end
          last_coord = new_coord.dup
          Thread.pass
        end
      end
      file.close
      @duration_calculated = true
    end

    last_coord = nil
    new_coord = [0, 0, 0]
    feedrate = nil
    @g1count = 0
    
 
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

      # calculate progress
      gcode = Gcode.new(line)
      feedrate = gcode.f if gcode.f
      if gcode.valid and gcode.g?(1) and feedrate and ( gcode.x or gcode.y or gcode.z )
        @g1count += 1
        new_coord[0] = gcode.x if gcode.x
        new_coord[1] = gcode.y if gcode.y
        new_coord[2] = gcode.z if gcode.z

        if last_coord and @g1count > @g1_to_skip_for_time_estimate
          segment = Vector.elements([
            new_coord[0] - last_coord[0],
            new_coord[1] - last_coord[1],
            new_coord[2] - last_coord[2]])
       
          segment_duration = segment.norm / (feedrate / 60)
          @current_duration += segment_duration
        end
        last_coord = new_coord.dup
      end

      # get time of "real" print start - after first lines of preheating and priming etc
      if @g1count == @g1_to_skip_for_time_estimate
        @timeprintstarted = Time.now
      end

      # recalculate progress
      if @duration_calculated and ( @print_duration > 0 )
        @progress = ((@current_duration / @print_duration) * 100).to_i      
      end

      if @preheating
        Thread.stop
      end      

      if @aborted
        @printing = false
        @send_thread.run    
        @calc_duration_thread.kill    
        Thread.exit
      end

      if @paused
        @printing = false
        @send_thread.run
        Thread.stop
      end
      
    end
    
    @calc_duration_thread.kill
    @duration_calculated = false
    @progress = 0
    @timeprintstarted = nil
    @printing = false
    @gcodefile.close
    @gcodefile = nil
    @lines = 0
    puts "Print finished!" if @verbose
    @endcb.call(self.time_elapsed) if @endcb
    @send_thread.run
  end
  
  def time_remaining
    if @printing and @timeprintstarted and @duration_calculated and ( @current_duration > 0 )
      ( Time.now - @timeprintstarted ) / @current_duration * ( @print_duration - @current_duration )
    else
      nil
    end
  end
  
  def time_elapsed
    if @timejobstarted
      ( Time.now - @timejobstarted )
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
        puts "Error while starting print of file " + (gcodefilename ? gcodefilename : "NO FILE SUPPLIED")
        puts e
        @errorcb.call("Error opening GCODE file " + (gcodefilename ? gcodefilename : "NO FILE SUPPLIED")) if @errorcb
        @errorcb.call(e.to_s) if @errorcb
      end      
    end
  end
  
  def pause_print
    if @printing and not @paused
      # invoke a thread stop inside @print_thread
      @paused = true 
      sleep 0.1 until not @printing

      # deep-copy printer parameters for resume
      @params_for_resume = Marshal.load(Marshal.dump(@current_params))
      @pausecb.call if @pausecb
      
      # store last printing position
      self.send("M400")
      self.send("M401")

      # home all axes and turn off both extruders, bed and chamber stay untouched
      self.send("G28")
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

      # home all axes
      self.send("G28")
      
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
    if @printing or @paused
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
      @timeprintstarted = nil     

      # home all axes
      self.send("G28")
      
      # disable extruders
      self.send("M104 S0 T0")
      self.send("M104 S0 T1")
          
    else
      @errorcb.call("Cannot abort print - not printing right now!") if @errorcb
    end
  end

  def emergencystop
    @emergencystop = true
    @emergencystopcb.call if @emergencystopcb
    self.reset
    @current_params[:psu_on] = false
    @psuoffcb.call if @psuoffcb
    @emergencystop = false    
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
      elsif @printing
        status = 2 # printing
      elsif @paused
        status = 3 # paused
      else
        status = 1 # idle
      end
    end

    status    
  end

end

