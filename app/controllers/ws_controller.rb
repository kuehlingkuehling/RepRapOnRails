class WsController < WebsocketRails::BaseController
  def initialize_session
    # perform application setup here
    @@printer = ApplicationController.printer
    @@printjob = ApplicationController.printjob    
    @@log_queue = ApplicationController.log_queue
  end

  def logfile
#    trigger_success LogEntry.limit(Rails.application.config.log_max_shown_in_touchapp).order('created_at desc').to_a
    trigger_success LogEntry.limit(Rails.application.config.log_max_shown_in_touchapp).order('id desc').to_a
  end
  
  def hostname
    trigger_success Rails.application.config.hostname
  end

  def firmware_version
    trigger_success "Repetier Firmware v" + Settings.firmware_version
  end

  def status
    status = { :state => @@printer.status,
               :job => @@printjob[:title],
               :job_id => @@printjob[:id],
               :psu_on => @@printer.current_params[:psu_on] } 

    trigger_success status
  end
  
  def sendgcode
    gcode = message
    @@printer.send(gcode) 
  end 
  
  def move
    coord = message
    MACROS[:relative_positioning].each do |m|
      @@printer.send(m)
    end
    @@printer.send("G1 " + coord + " F12000")
    MACROS[:absolute_positioning].each do |m|
      @@printer.send(m)
    end
  end
  
  def set_temp
    extruder = message[0]
    temp = message[1]
    @@printer.send("M104 S" + temp.to_s + " T" + extruder.to_s)
  end

  def preheat
    chamber = message[0]
    bed = message[1]    
    @@printer.send("M104 S" + chamber.to_s + " T2") if chamber >= 0  # so you can send "-1" if it should not be altered
    @@printer.send("M140 S" + bed.to_s) if bed >= 0 # so you can send "-1" if it should not be altered
  end
  
  def extrude
    extruder = message[0]
    length = message[1]
    @@printer.send("T" + extruder.to_s);        
    @@printer.send("G91");    # relative positioning
    @@printer.send("G1 E" + length.to_s + " F30");  # extrude <length> mm of filament
    @@printer.send("G90");    # back to absolute positioning    
  end  
  
  def macro
    macro = MACROS[message.to_sym]  
    if macro
      macro.each do |line|
        @@printer.send(line)
      end    
    end
  end

  def psu_on
    if not @@printer.current_params[:psu_on]
      @@printer.send("M80")
      @@printer.send("G28")
      @@printer.send("T0")
    end
  end
  
  # set EEPROM values in Repetier Firmware
  def set_eeprom
    pos = message[0]
    type = message[1]
    val = message[2]
    if type == 3
      char = "X"
      val = val.to_f
    else
      char = "S"
      val = val.to_i
    end
    @@printer.send("M206 T#{ type } P#{ pos } #{ char }#{ val }")    
  end

  def measure_backlash
    # assuming all is already set up for this task:
    # - backlash compensation deactivated on x/y axis)
    # - extruder 2 offset (x/y) set to 0
    axis = message[0].to_sym
    stepsize = message[1]        # can be positive or negative
    measurements = []
    steps = message[2]           # e.g. 100 x 0.01mm = 1mm
    repeat = 3                   # number of measurements taken
    retries = 3                  # number of retries for homing

    # select left extruder
    @@printer.send("T0")

    repeat.times do 
      backlash = 0

      retries.times do
        # home the axis to be measured
        @@printer.send("G28 #{ axis.to_s.upcase }0")
        # ẃait until all movements done
        @@printer.send("M400")
        # wait one second to debounce endstop
        @@printer.send("G4 P1000")
        # query endstop status after
        @@printer.send("M119")
        # wait for enstop status response
        begin
          Timeout::timeout(10) do
            while not @@printer.endstopstatus
              sleep 0.1
            end
          end
          if @@printer.endstopstatus[axis] == "H"
            break
          end
        rescue Timeout::Error
          trigger_failure "Measurement initialisation failed (Timeout)"
          return
        end
      end

      if not @@printer.endstopstatus[axis] == "H"
        trigger_failure "Measurement initialisation failed (unexpected endstop status)"
        return
      end


      # switch to relative positioning
      @@printer.send("G91")

      # measure backlash (move axis until endstop status changes = print head moved)
      steps.times do |step|
        # move motor a little step (in relative positioning mode)
        @@printer.send("G1 #{ axis.to_s.upcase }#{ stepsize }")
        
        # query endstop status after all movements done
        @@printer.send("M400")  
        @@printer.send("M119")

        # wait for endstop status response
        begin
          Timeout::timeout(3) do
            while not @@printer.endstopstatus
              sleep 0.1
            end
          end
        rescue Timeout::Error
          trigger_failure "Measurement failed (Timeout)"
          @@printer.send("G90")
          return
        end
        
        if @@printer.endstopstatus[axis] == "L"
          break
        else
          backlash += stepsize.abs
        end
      end

      measurements.push(backlash)
    end

    # calculate median of measurements
    sorted = measurements.sort
    mid = (sorted.length - 1) / 2.0
    median = (sorted[mid.floor] + sorted[mid.ceil]) / 2.0

    # back to absolute positioning
    @@printer.send("G90")

    # home the axis
    @@printer.send("G28 #{ axis.to_s.upcase }0")
    
    if median < (steps * stepsize.abs)
      trigger_success median 
    else
      trigger_failure "Measurement failed (backlash possibly outside measurement range)"
    end
  end
  
  def emergencystop
    @@printjob[:id] = nil
    @@printjob[:title] = ""

    @@printer.emergencystop
  end
  
  def progress
    if @@printer.printing?
      if @@printer.time_remaining
        remaining = UsefulGlobalMethods.timespan_in_words( @@printer.time_remaining ) + " left"
      else
        remaining = "(calculating print time)"
      end
    else
      remaining = ""
    end
    progress = { :percent => @@printer.progress,
                 :time_remaining => remaining }
    trigger_success progress
  end
  
  def startprint
    if @@printer.online? and not @@printer.printing?     
      job = Printjob.find(message)
      @@printjob[:id] = job.id
      @@printjob[:title] = job.name
      @@printer.start_print(job.gcodefile.current_path)
   end
  end
  
  def abortprint
    @@printer.abort_print    
  end
  
  def pauseprint
    @@printer.pause_print    
  end  
  
  def resumeprint
    @@printer.resume_print    
  end    
  
  def shutdown
    unless @@printer.printing?
      @@log_queue.push({:level => 1, :line => 'System is shutting down.'})
      system('sudo /sbin/shutdown -h now')
    end
  end

end