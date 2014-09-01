class PreheatingProfile < ActiveRecord::Base
  attr_accessible :name, :chamber_temp, :bed_temp

  after_save :notify_change_via_websocket
  after_destroy :notify_change_via_websocket
  
  private
  
  def notify_change_via_websocket
    WebsocketRails[:preheating_profiles].trigger(:reload)
    WebsocketRails[:preheating_profiles].trigger(:reload_selected)
  end    	
end
