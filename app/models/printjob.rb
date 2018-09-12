class Printjob < ActiveRecord::Base
  validates :name, presence: true
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
      begin
        time_total = 0
        file = File.open(self.gcodefile.current_path,'r')
        file.each_line do |line|
          if line.start_with?('M73')
            begin
              prog = line.match(/M73 P\d+\sR(?<remaining>\d+).*/)
              time_total = prog[:remaining].to_i
            rescue => e
              puts "Error in M73-String RegEx"
              puts e.inspect
            end          

            break # only find first occurance of M73 statement to get total print duration
          end
        end
        file.close

        self.estimated_print_time = time_total
        self.save        
      rescue
        # do nothing - rescueing in case file is deleted before calculation finished
        #  (or non-text/ non-gcode file was uploaded for whatever reason)
      end
  end

end
