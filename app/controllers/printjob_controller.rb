class PrintjobController < WebsocketRails::BaseController
  def initialize_session
    # perform application setup here
    @@printer = ApplicationController.printer
    @@printjob = ApplicationController.printjob    
  end
  
  def all
    # UsefulGlobalMethods.timespan_in_words( self.estimated_print_time )
    Printjob.connection.clear_query_cache
    all = Printjob.all.to_a.map {|p| 
      result = p.attributes
      result["estimated_print_time_in_words"] = (result["estimated_print_time"] > 0) ? UsefulGlobalMethods.timespan_in_words(result["estimated_print_time"] ) : "n/a"
      result["created_at_in_words"] = ActionController::Base.helpers.time_ago_in_words( p.created_at ) + " ago"
      result
    }
    trigger_success all.reverse
  end
  
  def remove
    job = message
    Printjob.destroy(job) unless job == @@printjob[:id]
  end
  
  def update
    job = message
    p = Printjob.find(job[:id])
    p.update(:name => job[:name], :note => job[:note])
  end
  
  def calibrate_extrusion
    # ext: 'left' or 'right'
    ext = message
    if (ext == 'left')
      # add left calibration
      Thread.new do
        p = Printjob.new
        p.name = Rails.application.config.is_dual_extruder ? "Extrusion Calibration (Left Extruder)" : "Extrusion Calibration"
        p.note = "NOTICE: Use ABS plastic only (265\u00B0C), nozzle 0.35mm!"
        p.gcodefile = File.open(Rails.application.config.gcode_calibrate_extrusion_left)
        p.save
      end
    elsif (ext == 'right')
      # add right calibration
      Thread.new do
        p = Printjob.new
        p.name = "Extrusion Calibration (Right Extruder)"
        p.note = "NOTICE: Use ABS plastic only (265\u00B0C), nozzle 0.35mm!"
        p.gcodefile = File.open(Rails.application.config.gcode_calibrate_extrusion_right)
        p.save      
      end
    end
  end
  
  def calibrate_offset
    # add offset calibration printjob
    Thread.new do
      p = Printjob.new
      p.name = "Extruder Offset Calibration"
      p.note = "NOTICE: Use ABS plastic only (265\u00B0C), nozzle 0.35mm!"
      p.gcodefile = File.open(Rails.application.config.gcode_calibrate_offset)
      p.save    
    end
  end
  
end