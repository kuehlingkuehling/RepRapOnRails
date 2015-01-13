require(File.join(Rails.root, "lib", "repraphost.rb"))
require(File.join(Rails.root, "lib", "useful_global_methods.rb"))

RepRapOnRails::Application.configure do
  # Configuring all the general RepRapOnRails-specific parameters
  
  # Autodetect USB Port on which the RepRap Arduino is connected
  ports = Dir['/dev/ttyUSB*'] + Dir['/dev/ttyACM*']
  config.reprap_usb_port = ports.first
  config.reprap_usb_baudrate = 115200
  
  # get hostname of this machine for showing backend-URL in touchapp
  config.hostname = `hostname`.strip
  
  # logfile configuration
  config.log_max_shown_in_touchapp = 100
  
  # static calibration gcode files
  config.gcode_calibrate_extrusion_left = File.join(Rails.root, "calibration", "calibration_extrusion_left.gcode")
  config.gcode_calibrate_extrusion_right = File.join(Rails.root, "calibration", "calibration_extrusion_right.gcode")
  config.gcode_calibrate_offset = File.join(Rails.root, "calibration", "calibration_offset.gcode")  
  
  # location of a new arduino firmware hexfile if available
  config.arduino_hexfile = File.join( Rails.root, "arduino-firmware-update", "arduino-firmware.hex" )

  # RepRapOnRails software version string
  config.software_version = "RepRapOnRails " + File.open(File.join(Rails.root, "VERSION"), &:readline).strip

  # Get hardware revision string to define which machine specific config set to load in repraponrails_02_config.rb
  config.hardware_revision_number = File.open(File.join(Rails.root, "HARDWARE_REVISION"), &:readline).strip

  # preheating parameters (M109/M190)
  config.preheat_deviation = 2  # +/- in °C
  config.preheat_stabilize_time = 3  # in sec  
end

# moving log database writing to queued background job - this task is too slow
# to execute in callbacks
log_queue = ApplicationController.log_queue
log_thread = Thread.new do
  loop do
    if log_queue.size > 0
      l = log_queue.shift
      LogEntry.create(level: l[:level], line: l[:line])
    else
      sleep 0.01
    end
  end
end

# check if arduino firmware update available
# if true (arduino-firmware.hex file was uploaded to 'arduino-firmware-update' directory)
# we will upload the new hex file via avrdude and delete the file on success.
if File.exist?( Rails.application.config.arduino_hexfile )
  log_queue.push({:level => 1, :line => 'New Arduino Firmware update available - installing...'})
  avrdude_log = `avrdude -patmega2560 -cwiring -P#{ Rails.application.config.reprap_usb_port } -b115200 -D -Uflash:w:#{ Rails.application.config.arduino_hexfile }:i 2>&1`
  exit_status = $?.to_i

  avrdude_log.each_line do |logline|
    log_queue.push({:level => 0, :line => logline})
  end

  if exit_status == 0
    arduino_updated = true  # to later issue M502+M500 commands to set EEPROM values
    log_queue.push({:level => 1, :line => 'Arduino Firmware update finished.'})
    File.delete( Rails.application.config.arduino_hexfile )    
  else  
    log_queue.push({:level => 3, :line => 'ERROR: Arduino Firmware update failed! Please reboot for another try.'})
  end    
end

# starting RepRap Connection
unless File.basename($0) == "rake"  # do not initiate reprap during rake tasks
  printer = ApplicationController.printer
  printjob = ApplicationController.printjob

  Settings.filament_left = nil if not Settings.all.has_key?("filament_left")
  Settings.filament_right = nil if not Settings.all.has_key?("filament_right")
  Settings.preheating_profile = nil if not Settings.all.has_key?("preheating_profile")
  Settings.firmware_version = nil if not Settings.all.has_key?("firmware_version")

  begin
    if printer.is_a?(RepRapHost) and not printer.online?

      # assign online callback
      printer.onlinecb = Proc.new do
        WebsocketRails[:print].trigger(:state, printer.status)                              
        log_queue.push({:level => 1, :line => 'RepRap Controller is online!'})
      end
  
      # assign receive callback
      printer.recvcb = Proc.new do |line| 
        log_queue.push({:level => 0, :line => 'RECV: ' + line.delete("\n")})
      end                                        
      
      # assign send callback
      printer.sendcb = Proc.new do |line| 
       log_queue.push({:level => 0, :line => 'SENT: ' + line.delete("\n")})
      end
                        
      # assign start callback
      printer.startcb = Proc.new do |line|
        WebsocketRails[:print].trigger(:state, printer.status)
        WebsocketRails[:print].trigger(:job, { :name => printjob[:title], :job_id => printjob[:id] })
        log_queue.push({:level => 1, :line => "Printjob started: \"#{printjob[:title]}\""})
      end
                        
      # assign pause callback                      
      printer.pausecb = Proc.new do |line|
        WebsocketRails[:print].trigger(:state, printer.status) # paused
        log_queue.push({:level => 1, :line => 'Printjob paused'})
      end  
                        
      # assign pause callback                      
      printer.resumecb = Proc.new do |line| 
        WebsocketRails[:print].trigger(:state, printer.status) # printing
        log_queue.push({:level => 1, :line => 'Printjob resumed'})                      
      end                      
  
      # assign end callback
      printer.endcb = Proc.new do |elapsed|
        WebsocketRails[:print].trigger(:state, printer.status)        
        WebsocketRails[:print].trigger(:job, { :name => "", :job_id => 0 })
        WebsocketRails[:print].trigger(:finished, {:id => printjob[:id], :elapsed => UsefulGlobalMethods.timespan_in_words( elapsed )})
        log_queue.push({:level => 1, :line => "Printjob \"#{printjob[:title]}\" finished after " + UsefulGlobalMethods.timespan_in_words( elapsed )})
        printjob[:id] = nil
        printjob[:title] = ""
      end  

      # assign abort callback
      printer.abortcb = Proc.new do 
        log_queue.push({:level => 2, :line => 'Printjob aborted!'})
      end                        
      
      # assign error callback                      
      printer.errorcb = Proc.new do |line|
        if line
          log_queue.push({:level => 3, :line => 'ERROR: ' + line.delete("\n")})
        end
      end         
  
      # assign temp callback                      
      printer.tempcb = Proc.new do |temps, targets| 
        message = { 
          :left_extruder  => { :temp   => temps[:T0],
                               :target => targets[:T0] },
          :right_extruder => { :temp   => temps[:T1],
                               :target => targets[:T1] },
          :chamber        => { :temp   => temps[:T2],
                               :target => targets[:T2] },
          :bed            => { :temp   => temps[:B],
                               :target => targets[:B] }
        }

        WebsocketRails[:temp].trigger(:new, message)
      end  
                        
      # assign out of filament callback                      
      printer.reloadcb = Proc.new do |spool|
        if printer.printing?
          WebsocketRails[:print].trigger(:state, printer.status)  # paused
          WebsocketRails[:print].trigger(:out_of_filament, spool)
          log_queue.push({:level => 2, :line => "Out of Filament: Please reload #{ spool } spool!"})
        end
      end   

      # assign preheating start callback                      
      printer.preheatcb = Proc.new do |line|
        WebsocketRails[:print].trigger(:state, printer.status) # preheating
      end  
                        
      # assign preheating done callback                      
      printer.preheatedcb = Proc.new do |line| 
        WebsocketRails[:print].trigger(:state, printer.status)                          
      end

      # assign emergency stop callback
      printer.emergencystopcb = Proc.new do |line| 
        WebsocketRails[:print].trigger(:state, printer.status)                          
        log_queue.push({:level => 2, :line => "Emergency Stop triggered!"})
      end  

      # assign psu ON callback
      printer.psuoncb = Proc.new do |line| 
        WebsocketRails[:print].trigger(:psu, printer.current_params[:psu_on])                          
        log_queue.push({:level => 1, :line => "Build Chamber activated"})
      end

      # assign psu OFF callback
      printer.psuoffcb = Proc.new do |line| 
        WebsocketRails[:print].trigger(:psu, printer.current_params[:psu_on])                          
        log_queue.push({:level => 1, :line => "Build Chamber deactivated"})
      end

      # assign EEPROM value callback
      printer.eepromcb = Proc.new do |config| 
        WebsocketRails[:eeprom].trigger(:line, config)                          
      end 

      # assign Firmware version callback
      printer.fwcb = Proc.new do |version|
        Settings.firmware_version = version
      end


      # debugging in development environment
      if Rails.env.development?
        printer.echoreadwrite = true
        printer.verbose = true
      end

      # set preheating parameters (M109/M190)
      printer.temp_deviation = Rails.application.config.preheat_deviation
      printer.temp_stabilize_time = Rails.application.config.preheat_stabilize_time
      
      log_queue.push({:level => 1, :line => 'Connecting to RepRap Controller...'})      
      printer.connect(Rails.application.config.reprap_usb_port, Rails.application.config.reprap_usb_baudrate)

      # load firmware configuration values into EEPROM after arduino firmware update
      if arduino_updated
        printer.send("M502") # load settings from firmware config
        printer.send("M500") # store loaded values in EEPROM
      end

      # request firmware version capabilities string from Arduino
      printer.send("M115")
    end
  rescue => error
    puts 'Could not connect to RepRap Controller: ' + error.message
    LogEntry.create(level: 3, line: 'ERROR: Could not connect to RepRap Controller: ' + error.message)
    printer.close unless printer.nil? or not printer.online?
  end

end #unless  

