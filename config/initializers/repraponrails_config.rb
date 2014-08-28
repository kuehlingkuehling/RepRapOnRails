RepRapOnRails::Application.configure do
  # Configuring all the hardware revision specific parameters
  
  # chamber heater cooldown time (for safety)
  config.chamber_heater_cooldown_time = 180
    
  # print bed x/y zero position
  config.print_bed_x_zero = 0
  config.print_bed_y_zero = 0
end