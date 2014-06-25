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
                :abortcb
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
    @paused = false
    @online = false
    @progress = 0
    @timejobstarted = nil
    @timeprintstarted = nil # after 30 lines preheating is usually over, so we assume print start here
    @lines = 0 # number of lines of the gcodefile that is printing
    
    # stored parameters for resume from pause
    @target_extruders = Hash.new
    @active_extruder = 0
    @last_e_position = 0
    @retraction_distance = 0
    @last_feedrate = nil

    # Status
    # 0: Offline
    # 1: Idle
    # 2: Printing
    # 3: Paused
    @status = 0  
                 
    
    # callbacks
    @tempcb = nil  # TODO!
    @recvcb = nil
    @sendcb = nil
    @errorcb = nil
    @startcb = nil
    @endcb = nil
    @onlinecb = nil
    @pausecb = nil
    @reloadcb = nil # on filament empty, deliveres :left or :right as parameter
    @abortcb = nil
    
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
          
          unless line.start_with?('Resend') or line.start_with?('ok')
            @recvcb.call(line) if @recvcb            
          end
        end
        
        # Temperature callback
        if line.start_with?('ok T:') or line.start_with?('T:')
          @tempcb.call(line) if @tempcb
        end
        
        # remember extruder target temperatures for pause/resume
        # only while printing - so no manual control actions override these
        if line.start_with?('TargetExtr') and @printing
          result = /^TargetExtr(?<extruder>\d*):(?<temp>\d+)/.match(line)
          @target_extruders[result[:extruder]] = result[:temp]
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
        
        puts ">>> " + line if @verbose and @echoreadwrite
        @sendcb.call(line) if @sendcb and execsendcb
        
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
      end
    end
  end
  
  def send(line)
    # Send a single gcode command to the printer.
    # Chooses if we can send directly (if not printing)
    # or through the @printqueue
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
      if @stop_send_thread
        @stop_send_thread = false
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
  
  def print_loop
    # loop printing from a @gcodefile, also sending
    # commands in @printqueue in between.
    # used in @print_thread
    
    @printing = true
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
      end
      
      if @paused
        @send_thread.run
        Thread.stop
      end
        
      # then continue with next line from gcode file
      self.write(line)
      
      # remember active extruder for pause/resume
      if result = /^T(?<number>\d)/.match(line)
        @active_extruder = result[:number]
      end
      
      if line.start_with?("G1")
        if result = / E(?<position>\d+\.?\d*)/.match(line)
          if @last_e_position > result[:position].to_f
            @retraction_distance = @last_e_position - result[:position].to_f
          else
            @retraction_distance = 0
          end
          
          @last_e_position = result[:position].to_f
        end
        
        if result = / F(?<feedrate>\d+\.?\d*)/.match(line)
          @last_feedrate = result[:feedrate].to_f
        end        
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
             
        @stop_send_thread = true
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
      sleep 0.1 until @print_thread.stop?
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
      @target_extruders.each do |temp| 
        self.send("M104 S#{ temp[1] } T#{ temp[0] }")
      end
      self.send("M109") unless @target_extruders.empty?
  
      # select extruder, that was active before pause
      self.send("T#{ @active_extruder }")
      
      # restore extruder retraction state
      if @retraction_distance > 0
        self.send("G92 E0")
        self.send("G1 E-#{ @retraction_distance } 70")
      end
      
      # set current extruder value to last seen value
      # so subsequent gcodes can continue from here
      self.send("G92 E#{ @last_e_position }")
      
      # move to last stored printing position
      self.send("M402")

      # restore feedrate last used
      if @last_feedrate
        self.send("G1 F#{ @last_feedrate }")
      end
      
      @stop_send_thread = true
      sleep 0.1 until @send_thread.stop?
      
      @print_thread.run
    else
      errorcb.call("Nothing to resume, printer isn't paused right now!") if @errorcb
    end
  end
  
  def abort_print
    # stops the print
    if @printing or @paused
      @print_thread.kill
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
      @target_extruders = Hash.new
      @active_extruder = 0      
    else
      @errorcb.call("Cannot abort print - not printing right now!") if @errorcb
    end
  end
  
end
