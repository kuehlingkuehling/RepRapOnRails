require 'rubygems'
require 'serialport'
require 'thread'

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
  attr_accessor :verbose, :echoreadwrite,
                :tempcb, :recvcb, :sendcb, :errorcb, :startcb, 
                :pausecb, :resumecb, :endcb, :onlinecb, :reloadcb,
                :abortcb, :preheatcb, :preheatedcb
  attr_reader :online, :printing, :paused, :lastresponse, :progress,
              :status
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
    
    # for preheating: deviation around target temperature to accept as preheated
    # in +/- °C
    @temp_deviation = 2
    @temp_update_interval = 1

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

    # snapshot of current params for resume
    @params_for_resume = nil

    # Status
    # 0: Offline
    # 1: Idle
    # 2: Printing
    # 3: Paused
    # 4: Emergency Stop
    # 5: Preheating
    @status = 0  
                 
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
        @printer = SerialPort.new(@port, @baud, 8, 1, SerialPort::NONE)
        
        while not @online
          # start read loop in seperate thread
          @read_thread.kill if @read_thread
          @read_thread = Thread.new { self.read_loop }

          # reset firmware
          self.reset
          
          # wait for successful reset
          sleep 5
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
    @status = 0
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
          @status = 1               
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
            t0 = line.scan(/T0:\-?\s*\d+\.\d+/)[0]
            t1 = line.scan(/T1:\-?\s*\d+\.\d+/)[0]
            t2 = line.scan(/T2:\-?\s*\d+\.\d+/)[0]
            b = line.scan(/B:\-?\s*\d+\.\d+/)[0]
            @current_params[:current_temps] = {
              :T0 => t0.match(/:(\-?\s*\d+\.\d+)/)[1].to_f,
              :T1 => t1.match(/:(\-?\s*\d+\.\d+)/)[1].to_f,
              :T2 => t2.match(/:(\-?\s*\d+\.\d+)/)[1].to_f,
              :B => b.match(/:(\-?\s*\d+\.\d+)/)[1].to_f
            }
          rescue => e
            puts "Error in Temp-String RegEx"
            puts e.inspect
          end          

          @tempcb.call(@current_params[:current_temps], @current_params[:target_temps]) if @tempcb
        end

        # remember extruder target temperatures
        if line.start_with?('TargetExtr')
          result = /^TargetExtr(?<extruder>\d*):(?<temp>\d+)/.match(line)
          heater = ( 'T' + result[:extruder] ).to_sym
          @current_params[:target_temps][heater] = result[:temp].to_i
        end

        # remember bed target temperature
        if line.start_with?('TargetBed')
          result = /^TargetBed:(?<temp>\d+)/.match(line)
          @current_params[:target_temps][:B] = result[:temp].to_i
        end
        
        
        # act on out-of-filament messages
        if line.start_with?('OutOfFilament')
          result = /^OutOfFilament:(?<spool>\w+)/.match(line)
          @reloadcb.call(result[:spool]) if @reloadcb and @printing
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
            preheat = true
          end
          
          line.sub!("M109", "M104")          
        end
        if line.start_with?("M190")
          target_temp = line.match(/.*S(\d+).*/)

          if target_temp and target_temp[1] and target_temp[1].to_i > 0
            target_temp = target_temp[1].to_i
            heater = :B
            preheat = true
          end

          line.sub!("M190", "M140")         
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
          @preheatcb.call if @preheatcb
          @preheat_thread = Thread.new(heater, target_temp) { |h,t| self.preheat_loop(h, t) }
        end
      end
    end
  end

  def preheat_loop(heater, target_temp)
    # loop waiting for preheat target temperatures to be reached
    # @print_thread or @send_thread are on hold for the moment and resume afterwards
    # used in @preheat_thread

    target_range = (target_temp - @temp_deviation)..(target_temp + @temp_deviation)
    while not target_range.include?(@current_params[:current_temps][heater])
      break if @paused or @aborted
      # get temperatures
      self.write("M105")
      sleep @temp_update_interval
    end

    @preheating = false
    @preheatedcb.call if @preheatedcb

    # restart send_thread or print_thread
    if @printing
      @print_thread.run
    else
      @send_thread.run
    end
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

        if @preheating
          Thread.stop
        end        
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
      
      sleep @temp_update_interval
    end
  end
  
  def print_loop
    # loop printing from a @gcodefile, also sending
    # commands from @printqueue in between.
    # used in @print_thread
    
    @progress = 0
    
    # count number of lines
    @lines = 0
    @gcodefile.each_line do
      @lines += 1
    end
    # go back to first line
    @gcodefile.rewind
    
    # the actual loop
    while line = @gcodefile.gets
            
      # send commands from print queue first
      while cmd = @printqueue.shift
        self.write(cmd, true)
        
        if @preheating
          Thread.stop
        end        
      end
      
      if @aborted
        @send_thread.run        
        Thread.kill
      end

      if @paused
        @send_thread.run
        Thread.stop
      end
        
      # then continue with next line from gcode file
      self.write(line)

      if @preheating
        Thread.stop
      end        
        
      # recalculate progress
      @progress = ((@gcodefile.lineno.to_f / @lines.to_f) * 100).to_i
      
      # save time when actual printing started (after preheating etc)
      # we asume after 30 lines of gcode the preheat should be done...
      @timeprintstarted = Time.now if @gcodefile.lineno == 150
    end
    
    @progress = 0
    @timeprintstarted = nil
    @printing = false
    @gcodefile.close
    @gcodefile = nil
    @lines = 0
    puts "Print finished!" if @verbose
    @endcb.call(self.time_elapsed) if @endcb
    @send_thread.run
    @status = 1
  end
  
  def time_remaining
    if @printing and @timeprintstarted
      ( Time.now - @timeprintstarted ) / ( @gcodefile.lineno - 150 ) * ( @lines - @gcodefile.lineno )
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
        @status = 2
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
      @printing = false
      sleep 0.1 until @preheat_thread.stop? if @preheating
      sleep 0.1 until @print_thread.stop?

      @params_for_resume = @current_params.clone
      @send_thread.run
      
      @pausecb.call if @pausecb
      @status = 3
      
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
      
      @resumecb.call if @resumecb
      @status = 2
      
      # home all axes
      self.send("G28")
      
      # reset all extruder temperatures to stored values 
      @params_for_resume[:target_temps].each do |temp| 
        self.send("M104 S#{ temp[1] } T#{ temp[0] }")
      end
      self.send("M109") unless @params_for_resume[:target_temps].empty?
  
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
      
      @printing = true
      sleep 0.1 until @send_thread.stop?
      
      @print_thread.run
    else
      errorcb.call("Nothing to resume, printer isn't paused right now!") if @errorcb
    end
  end
  
  def abort_print
    # stops the print
    if @printing or @paused
      @aborted = true
      sleep 0.1 until @preheat_thread.stop? if @preheating
      sleep 0.1 until @print_thread.stop?
      @aborted = false
      @send_thread.run
      @printing = false
      @paused = false
      @gcodefile.close
      @gcodefile = nil
      @abortcb.call if @abortcb
      @endcb.call(self.time_elapsed) if @endcb 
      @status = 1
      @progress = 0
      @timejobstarted = nil
      @timeprintstarted = nil     
    else
      @errorcb.call("Cannot abort print - not printing right now!") if @errorcb
    end
  end
  
end
