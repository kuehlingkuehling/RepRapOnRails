class WsController < WebsocketRails::BaseController
  def initialize_session
    # perform application setup here
    @@printer = ApplicationController.printer
    @@printjob = ApplicationController.printjob    
  end

  def logfile
#    trigger_success LogEntry.limit(Rails.application.config.log_max_shown_in_touchapp).order('created_at desc').to_a
    trigger_success LogEntry.limit(Rails.application.config.log_max_shown_in_touchapp).order('id desc').to_a
  end
  
  def hostname
    trigger_success Rails.application.config.hostname
  end

  def status
    status = { :state => @@printer.status,
               :job => @@printjob[:title],
               :job_id => @@printjob[:id] } 

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
    @@printer.send("G1 " + coord)
    MACROS[:absolute_positioning].each do |m|
      @@printer.send(m)
    end
  end
  
  def set_temp
    extruder = message[0]
    temp = message[1]
    @@printer.send("M104 S" + temp.to_s + " T" + extruder.to_s)
  end
  
  def extrude
    extruder = message[0]
    length = message[1]
    @@printer.send("T" + extruder.to_s);        
    @@printer.send("G92 E0");
    @@printer.send("G1 E" + length.to_s + " F70");
  end
  
  def macro
    macro = MACROS[message.to_sym]  
    if macro
      macro.each do |line|
        @@printer.send(line)
      end    
    end
  end
  
  # right extruder offset calibration
  # x and y are steps
  def set_extruder_offset
    x = message[0]
    y = message[1]
    @@printer.send("M206 T2 P331 S" + x.to_s)
    @@printer.send("M206 T2 P335 S" + y.to_s)    
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
      system('sudo /sbin/shutdown -h now')
    end
  end

end