require(File.join(Rails.root, "lib", "repraphost.rb"))
require(File.join(Rails.root, "lib", "useful_global_methods.rb"))

RepRapOnRails::Application.configure do
  # Configuring all the RepRapOnRails-specific parameters
  
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
end

# moving log database writing to queued background job - this task is too slow
# to execute in callbacks
log_queue = []
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

# starting RepRap Connection
unless File.basename($0) == "rake"  # do not initiate reprap during rake tasks
  printer = ApplicationController.printer
  printjob = ApplicationController.printjob

  begin
    if printer.is_a?(RepRapHost) and not printer.online?
      # assign online callback
      printer.onlinecb = Proc.new do
                             WebsocketRails[:print].trigger(:state, 1)                              
                             #LogEntry.create(level: 1, line: 'RepRap Controller is online!')                            
                             log_queue.push({:level => 1, :line => 'RepRap Controller is online!'})
                           end
  
      # assign receive callback
      printer.recvcb = Proc.new do |line| 
                           #LogEntry.create(level: 0, line: 'RECV: ' + line.delete("\n"))
                          log_queue.push({:level => 0, :line => 'RECV: ' + line.delete("\n")})
                           #WebsocketRails[:log].trigger(:new, 'RECV: ' + line.delete("\n"))
                        end                                        
      
      # assign send callback
      printer.sendcb = Proc.new do |line| 
                           #LogEntry.create(level: 0, line: 'SENT: ' + line.delete("\n"))
                          log_queue.push({:level => 0, :line => 'SENT: ' + line.delete("\n")})
                           #WebsocketRails[:log].trigger(:new, 'SENT: ' + line.delete("\n"))
                         end
                        
      # assign start callback
      printer.startcb = Proc.new do |line|
                             WebsocketRails[:print].trigger(:state, 2)
                             WebsocketRails[:print].trigger(:job, { :name => printjob[:title], :job_id => printjob[:id] })
                             log_queue.push({:level => 1, :line => 'Printjob started'})
                             #LogEntry.create(level: 1, line: 'Printjob started')
                         end
                        
      # assign pause callback                      
      printer.pausecb = Proc.new do |line|
                            WebsocketRails[:print].trigger(:state, 3)
                            log_queue.push({:level => 1, :line => 'Printjob paused'})
                            #LogEntry.create(level: 1, line: 'Printjob paused')
                        end  
                        
      # assign pause callback                      
      printer.resumecb = Proc.new do |line| 
                            WebsocketRails[:print].trigger(:state, 2)
                            log_queue.push({:level => 1, :line => 'Printjob resumed'})
                            #LogEntry.create(level: 1, line: 'Printjob resumed')                            
                        end                      
  
      # assign end callback
      printer.endcb = Proc.new do |elapsed|
                          WebsocketRails[:print].trigger(:state, 1)
                          WebsocketRails[:print].trigger(:job, { :name => "", :job_id => 0 })
                          WebsocketRails[:print].trigger(:finished, {:id => printjob[:id], :elapsed => UsefulGlobalMethods.timespan_in_words( elapsed )})
                          printjob[:id] = nil
                          printjob[:title] = ""
                          log_queue.push({:level => 1, :line => 'Printjob finished after ' + UsefulGlobalMethods.timespan_in_words( elapsed )})
                          #LogEntry.create(level: 1, line: 'Printjob finished after ' + UsefulGlobalMethods.timespan_in_words( elapsed ))
                      end  

      # assign abort callback
      printer.abortcb = Proc.new do 
                          log_queue.push({:level => 2, :line => 'Printjob aborted!'})
                      end                        
      
      # assign error callback                      
      printer.errorcb = Proc.new do |line|
                          if line
                            log_queue.push({:level => 3, :line => 'ERROR: ' + line.delete("\n")})
                            #LogEntry.create(level: 3, line: 'ERROR: ' + line.delete("\n"))
                          end
                           #WebsocketRails[:log].trigger(:new, 'ERROR: ' + line.delete("\n"))
                         end         
  
      # assign temp callback                      
      printer.tempcb = Proc.new do |line| 
                            # marlin temp string parser
                            #temps = line.scan(/T\d:\s*\d+\.\d+\s*\/\s*\d+\.\d+/)
                            #temps += line.scan(/B:\s*\d+\.\d+\s*\/\s*\d+\.\d+/)
                            #temps.map! do |t|
                            #  { :name => t.match(/(T\d):/) ? t.match(/(T\d):/)[1] : t.match(/(B):/)[1],
                            #    :current => t.match(/:\s*(\d+\.\d+)/)[1],
                            #    :target => t.match(/\/\s*(\d+\.\d+)/)[1] }
                            #end
                            begin
                              left = line.scan(/T0:\-?\s*\d+\.\d+/)[0]
                              right = line.scan(/T1:\-?\s*\d+\.\d+/)[0]
                              chamber = line.scan(/T2:\-?\s*\d+\.\d+/)[0]
                              bed = line.scan(/B:\-?\s*\d+\.\d+/)[0]
                              temps = [ 
                                { :name => 'Left Extruder',
                                  :temp => left.match(/:(\-?\s*\d+\.\d+)/)[1] },
                                { :name => 'Right Extruder',
                                  :temp => right.match(/:(\-?\s*\d+\.\d+)/)[1] },
                                { :name => 'Chamber',
                                  :temp => chamber.match(/:(\-?\s*\d+\.\d+)/)[1] },
                                { :name => 'Bed',
                                  :temp => bed.match(/:(\-?\s*\d+\.\d+)/)[1] }
                              ]
     
                              WebsocketRails[:temp].trigger(:new, temps)
                            rescue => e
                              logger.warn "Error in Temp-String RegEx"
                              logger.warn e.inspect
                            end
                         end  
                        
      # assign error callback                      
      printer.reloadcb = Proc.new do |spool|
                           if printer.printing?
                             printer.pause_print
                             WebsocketRails[:print].trigger(:state, 3)  
                             WebsocketRails[:print].trigger(:out_of_filament, spool)
                             log_queue.push({:level => 2, :line => "Out of Filament: Please reload #{ spool } spool!"})
                           end
                         end         
                        
      # debugging in development environment
      if Rails.env.development?
        printer.echoreadwrite = true
        printer.verbose = true
      end
      
      # write first log line to ensure LogEntry class is loaded - otherwise we occasionally get
      # "circular dependency" issues due to multiple concurrent logging-threads all
      # trying to load the class
      LogEntry.create(level: 1, line: "Connecting to RepRap Controller...")      
      printer.connect(Rails.application.config.reprap_usb_port, Rails.application.config.reprap_usb_baudrate)                      
  
    end
  rescue => error
    puts 'Could not connect to RepRap Controller: ' + error.message
    LogEntry.create(level: 3, line: 'ERROR: Could not connect to RepRap Controller: ' + error.message)
    printer.close unless printer.nil? or not printer.online?
  end
  
  Settings.filament_left = nil if not Settings.all.has_key?("filament_left")
  Settings.filament_right = nil if not Settings.all.has_key?("filament_right")

end #unless  

