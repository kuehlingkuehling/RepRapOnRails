RepRapOnRails::Application.configure do
  # Configuring all the hardware revision specific parameters

  case config.hardware_revision_number
  when "v1.0.0"
  
	  # hardware revision
	  config.hardware_revision = "RepRap Industrial v1.0.0"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.0.0-03"

	  # chamber heater cooldown time (for safety) - in seconds
	  config.chamber_heater_cooldown_time = 180
	    
	  # print bed x/y zero position
	  config.print_bed_zero  = [ 0, 0 ]

	  # print bed leveling coordinates
    config.leveling_point_front  = [ 100,  36 ] 
    config.leveling_point_right  = [ 147, 117 ]  
    config.leveling_point_left   = [  53, 117 ]  
    config.leveling_point_center = [  71,  90 ]

	  # print head maintenance position
	  config.maintenance_position = [ 71, -30 ] 

  when "v1.1.0"

      # hardware revision
	  config.hardware_revision = "RepRap Industrial v1.1.0"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.1.0-03"

	  # chamber heater cooldown time (for safety) - in seconds
	  config.chamber_heater_cooldown_time = 10
	    
	  # print bed x/y zero position
	  config.print_bed_zero  = [ 0, 0 ]

	  # print bed leveling coordinates
	  config.leveling_point_front  = [ 100,  36 ] 
	  config.leveling_point_right  = [ 147, 117 ]  
	  config.leveling_point_left   = [  53, 117 ]  
	  config.leveling_point_center = [  71,  90 ]

	  # print head maintenance position
	  config.maintenance_position = [ 71, -30 ] 

  end
  	
end