RepRapOnRails::Application.configure do
  # Configuring all the hardware revision specific parameters
  
  # hardware revision
  config.hardware_revision = "RepRap Industrial v1.1.0"

  # chamber heater cooldown time (for safety) - in seconds
  config.chamber_heater_cooldown_time = 10
    
  # print bed x/y zero position
  config.print_bed_x_zero = 0
  config.print_bed_y_zero = 0
end