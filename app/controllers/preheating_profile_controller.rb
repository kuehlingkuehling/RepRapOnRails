class PreheatingProfileController < WebsocketRails::BaseController
  def initialize_session
    # perform application setup here
    @@printer = ApplicationController.printer
    @@printjob = ApplicationController.printjob    
  end
  
  def all
    trigger_success PreheatingProfile.all
  end
  
  def create
    f = message
    PreheatingProfile.create(
      :name => f[:name],
      :chamber_temp => f[:chamber_temp].to_i,
      :bed_temp => f[:bed_temp].to_i      
    )
  end
  
  def delete
    f = message
    PreheatingProfile.destroy(f)
  end
  
  def update
    f = message
    profile = PreheatingProfile.find(f[:id])
    profile.update(
      :name => f[:name],
      :chamber_temp => f[:chamber_temp].to_i,
      :bed_temp => f[:bed_temp].to_i 
    )
  end   
  
  def get_selected
    # return temp profile for chamber/bed preheating
    trigger_success Settings.preheating_profile ? PreheatingProfile.find(Settings.preheating_profile) : 0
  end
  
  def set_selected
    # set loaded preset for left and right extruder
    # set temp profile for chamber/bed preheating
    Settings.preheating_profile = message

    WebsocketRails[:preheating_profiles].trigger(:reload_selected)
  end
  
end