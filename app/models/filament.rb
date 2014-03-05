class Filament < ActiveRecord::Base
  attr_accessible :name, :extrusion_temp

  after_save :notify_change_via_websocket
  after_destroy :notify_change_via_websocket
  
  private
  
  def notify_change_via_websocket
    WebsocketRails[:filaments].trigger(:reload)
  end    
end
