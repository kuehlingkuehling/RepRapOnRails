class Printjob < ActiveRecord::Base
  attr_accessible :gcodefile, :name, :note
  mount_uploader :gcodefile, GcodefileUploader

  after_destroy :notify_change_via_websocket
  after_create :calculate_print_time_estimate
  after_save :notify_change_via_websocket

  private
  
  def notify_change_via_websocket
    WebsocketRails[:printjobs].trigger(:reload)
  end

  def calculate_print_time_estimate
    calc_thread = Thread.new do
      last_coord = nil
      new_coord = [0, 0, 0]
      feedrate = nil
      print_duration = 0
      begin
        file = File.open(self.gcodefile.current_path,'r')
        file.each_line do |line|
          gcode = Gcode.new(line)
          feedrate = gcode.f if gcode.f
        
          if gcode.g?(1) and feedrate and ( gcode.x or gcode.y or gcode.z )
            new_coord[0] = gcode.x if gcode.x
            new_coord[1] = gcode.y if gcode.y
            new_coord[2] = gcode.z if gcode.z

            if last_coord
              segment = Vector.elements([
                new_coord[0] - last_coord[0],
                new_coord[1] - last_coord[1],
                new_coord[2] - last_coord[2]])
           
              segment_duration = segment.norm / (feedrate / 60)
              print_duration += segment_duration
            end
            last_coord = new_coord.dup
          end
          Thread.pass
        end
        file.close
      rescue
        return nil # do nothing - rescueing in case file is deleted before calculation finished
      end
      self.estimated_print_time = print_duration * 1.2
      self.save
    end
    calc_thread.priority = -2
  end

end
