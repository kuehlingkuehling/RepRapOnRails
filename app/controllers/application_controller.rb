class ApplicationController < ActionController::Base
  protect_from_forgery
  cattr_accessor :printer, :printjob, :log_queue, :temp_logger
  
  # Our global, application-wide, persistent RepRapHost instance 
  @@printer = RepRapHost.new
  
  # Our global, application-wide, persistent current Printjob information
  @@printjob = {
    :id => nil,
    :title => ""          
  }

  # Our global, application-wide, persistent log array
  # (continously saved to db by separate thread to avoid db concurrency issues)
  @@log_queue = Queue.new

  # A dedicated logger for a history of temperature readings 
  @@temp_logger = Logger.new("#{Rails.root}/log/temperatures.log")

end
