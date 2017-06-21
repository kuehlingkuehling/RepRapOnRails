RepRapOnRails::Application.configure do
  # Configuring all the hardware revision specific parameters

  # Get hardware revision string to define which machine specific config set to load
  config.hardware_revision_number = File.open(File.join(Rails.root, "HARDWARE_REVISION"), &:readline).strip
  
  case config.hardware_revision_number
  
  when "vp75-op-1.0.0"

    # model
    config.model_name = "VP75 OP"

    # hardware revision
    config.hardware_revision = "1.0.0"

    # customized interface design
    config.header_background_image = "rodin4d-background.jpg"
    #config.brand_color = "#7FFF00"
    config.brand_color = "#d9534f"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.92-vp75-1.0.0-04"

    # is dual extruder?
    config.is_dual_extruder = false

    # chamber heater cooldown time (for safety) - in seconds
    config.chamber_heater_cooldown_time = 120

    # print bed x/y zero position
    config.print_bed_zero  = [ 0, 0 ]

    # print head maintenance position
    config.maintenance_position = [ 0, -200, 600 ]

  when "vp75-1.0.0"

    # model
    config.model_name = "VP75"

    # hardware revision
    config.hardware_revision = "1.0.0"

    # customized interface design
    config.header_background_image = "blurry-autumn-background.jpg"
    config.brand_color = "#7FFF00"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.92-vp75-1.0.0-04"

    # is dual extruder?
    config.is_dual_extruder = false

    # chamber heater cooldown time (for safety) - in seconds
    config.chamber_heater_cooldown_time = 120

    # print bed x/y zero position
    config.print_bed_zero  = [ 0, 0 ]

    # print head maintenance position
    config.maintenance_position = [ 0, -200, 600 ]

  when "vp75-1.1.0"

    # model
    config.model_name = "VP75"

    # hardware revision
    config.hardware_revision = "1.1.0"

    # customized interface design
    config.header_background_image = "blurry-autumn-background.jpg"
    config.brand_color = "#7FFF00"

    # compatible Arduino Firmware version
    config.arduino_firmware_version = "Repetier Firmware v0.92-vp75-1.1.0-02"

    # is dual extruder?
    config.is_dual_extruder = false

    # chamber heater cooldown time (for safety) - in seconds
    config.chamber_heater_cooldown_time = 120

    # print bed x/y zero position
    config.print_bed_zero  = [ 0, 0 ]

    # print head maintenance position
    config.maintenance_position = [ 0, -200, 600 ]

  end


  	
end