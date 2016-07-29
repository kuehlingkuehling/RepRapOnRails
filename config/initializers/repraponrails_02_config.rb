RepRapOnRails::Application.configure do
  # Configuring all the hardware revision specific parameters

  case config.hardware_revision_number
  when "v1.4.1"

      # hardware revision
    config.hardware_revision = "HT500 v1.4.1"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.92-ht500-1.4.1-01"

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

  when "v1.4.2"

      # hardware revision
    config.hardware_revision = "HT500 v1.4.2"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.92-ht500-1.4.2-01"

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
    
  when "v1.4.3"

      # hardware revision
    config.hardware_revision = "HT500 v1.4.3"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.92-ht500-1.4.3-02"

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

  when "v1.4.4"

      # hardware revision
    config.hardware_revision = "HT500 v1.4.4"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.92-ht500-1.4.4-01"

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

  when "v1.4.5"

      # hardware revision
    config.hardware_revision = "HT500 v1.4.5"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.92-ht500-1.4.5-01"

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
  end
  	
end