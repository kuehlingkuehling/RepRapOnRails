class ApplicationController < ActionController::Base
  protect_from_forgery
  cattr_accessor :printer, :printjob
  
  # Our global, application-wide, persistent RepRapHost instance 
  @@printer = RepRapHost.new
  
  # Our global, application-wide, persistent current Printjob information
  @@printjob = {
    :id => nil,
    :title => ""          
  }

end
