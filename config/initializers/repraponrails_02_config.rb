RepRapOnRails::Application.configure do
  # Configuring all the hardware revision specific parameters

  case config.hardware_revision_number
  when "v1.0.0"
  
	  # hardware revision
	  config.hardware_revision = "RepRap Industrial v1.0.0"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.0.0-03"

    # is dual extruder?
    config.is_dual_extruder = true

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
	  config.maintenance_position = [ -29, -30 ] 

  when "v1.1.0"

      # hardware revision
	  config.hardware_revision = "RepRap Industrial v1.1.0"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.1.0-04"

    # is dual extruder?
    config.is_dual_extruder = true

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
	  config.maintenance_position = [ -29, -30 ] 

  when "v1.2.0"

      # hardware revision
    config.hardware_revision = "RepRap Industrial v1.2.0"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.2.0-01"

    # is dual extruder?
    config.is_dual_extruder = true

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
    config.maintenance_position = [ -29, -30 ] 

  when "v1.3.0"

      # hardware revision
    config.hardware_revision = "RepRap Industrial v1.3.0"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.3.0-01"

    # is dual extruder?
    config.is_dual_extruder = true

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
    config.maintenance_position = [ -29, -30 ]

  when "v1.3.1"

      # hardware revision
    config.hardware_revision = "RepRap Industrial v1.3.1"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.3.1-01"

    # is dual extruder?
    config.is_dual_extruder = true    

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
    config.maintenance_position = [ -29, -30 ]

  when "v1.3.1-S300200"

    # hardware revision
    config.hardware_revision = "RepRap Industrial v1.3.1-S300200"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.3.1-S300200-02"

    # is dual extruder?
    config.is_dual_extruder = false

    # chamber heater cooldown time (for safety) - in seconds
    config.chamber_heater_cooldown_time = 10
      
    # print bed x/y zero position
    config.print_bed_zero  = [ 0, 0 ]

    # print bed leveling coordinates
    config.leveling_point_front  = [ 150,  36 ] 
    config.leveling_point_right  = [ 197, 117 ]  
    config.leveling_point_left   = [ 103, 117 ]  
    config.leveling_point_center = [ 121,  90 ]

    # print head maintenance position
    config.maintenance_position = [ 150, -30 ]    

  when "v1.3.2"

      # hardware revision
    config.hardware_revision = "RepRap Industrial v1.3.2"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.3.2-01"

    # is dual extruder?
    config.is_dual_extruder = true    

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
    config.maintenance_position = [ -29, -30 ]

  when "v1.3.3"

      # hardware revision
    config.hardware_revision = "RepRap Industrial v1.3.3"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.3.3-01"

    # is dual extruder?
    config.is_dual_extruder = true    

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
    config.maintenance_position = [ -29, -30 ]    

  when "v1.4.0-S300200"

    # hardware revision
    config.hardware_revision = "HT500 v1.4.0-S300200"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.91-rri1.4.0-S300200-01"

    # is dual extruder?
    config.is_dual_extruder = false

    # chamber heater cooldown time (for safety) - in seconds
    config.chamber_heater_cooldown_time = 10
      
    # print bed x/y zero position
    config.print_bed_zero  = [ 0, 0 ]

    # print bed leveling coordinates
    config.leveling_point_front  = [ 150,  36 ] 
    config.leveling_point_right  = [ 197, 117 ]  
    config.leveling_point_left   = [ 103, 117 ]  
    config.leveling_point_center = [ 121,  90 ]

    # print head maintenance position
    config.maintenance_position = [ 150, -30 ]  

  end
  	
end