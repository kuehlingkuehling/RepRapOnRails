class Printjob < ActiveRecord::Base
  attr_accessible :gcodefile, :name, :note
  mount_uploader :gcodefile, GcodefileUploader

  after_save :notify_change_via_websocket
  after_destroy :notify_change_via_websocket
  
  private
  
  def notify_change_via_websocket
    WebsocketRails[:printjobs].trigger(:reload)
  end  
end
