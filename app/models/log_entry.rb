class LogEntry < ActiveRecord::Base
  # Types:
  #    0 - Default
  #    1 - Success
  #    2 - Warning
  #    3 - Error  
  
  attr_accessible :line, :level
  
  before_create :send_line_via_websocket
  
  private
  
  def send_line_via_websocket
    WebsocketRails[:log].trigger(:new, self)
  end
end
