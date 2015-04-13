MACROS = {
  :cooldown => [
    "M104 S0 T0",
    "M104 S0 T1",
    "M104 S0 T2",
    "M140 S0"],
  :before_shutdown => [
    "M81"],
  :after_abort => [              # deprecated - now implemented in repraphost.rb
    "M104 S0 T0",
    "M104 S0 T1",
    "G28"],
  :after_pause => [              # deprecated - now implemented in repraphost.rb
    "M104 S0 T0",
    "M104 S0 T1",
    "G28"],
  :maintenance_position => [
    "T0",
    "G1 X%d Y%d F12000" % [ Rails.application.config.maintenance_position[0], Rails.application.config.maintenance_position[1] ]],
  :home_all => [
    "G28"],
  :home_x => [
    "G28 X0"],
  :home_y => [
    "G28 Y0"],
  :home_z => [
    "G28 Z0"],  
  :relative_positioning => [
    "G91"],
  :absolute_positioning => [
    "G90"],
  :preheat_on => [
    "M104 S70 T2",
    "M140 S100"],
  :preheat_off => [
    "M104 S0 T2",
    "M140 S0"],
  :psu_on => [],                  # deprecated - now implemented in ws_controller.rb
  :psu_off => [
    "M104 S0 T0",    
    "M104 S0 T1",
    "M104 S0 T2",
    "M140 S0",    
    "M81"],
  :get_temp => [],                # deprecated - repraphost has an internal temp refresh loop running now
  :motors_off => [],               # deprecated - never ever used anymore to prevent damage from positioning misalignments
  :wizard_leveling_init => [
    "G28 Z0",
    "G1 X%d Y%d Z100 F12000" % [ Rails.application.config.leveling_point_center[0], Rails.application.config.leveling_point_center[1] ] ],
  :wizard_leveling_moveup => [
    "G1 Z0 F6000"],
  :wizard_leveling_preheat => [],    # deprecated - now managed by preheating profiles
  :wizard_leveling_front => [
    "G1 X%d Y%d Z20 F12000" % [ Rails.application.config.leveling_point_front[0], Rails.application.config.leveling_point_front[1] ] ],
  :wizard_leveling_right => [
    "G1 X%d Y%d Z20 F12000" % [ Rails.application.config.leveling_point_right[0], Rails.application.config.leveling_point_right[1] ] ],
  :wizard_leveling_left => [
    "G1 X%d Y%d Z20 F12000" % [ Rails.application.config.leveling_point_left[0], Rails.application.config.leveling_point_left[1] ] ],
  :wizard_leveling_center => [
    "G1 Z20 F6000",
    "T0",
    "G1 X%d Y%d Z20 F12000" % [ Rails.application.config.leveling_point_center[0], Rails.application.config.leveling_point_center[1] ],
    "G1 Z0 F6000"],
  :wizard_leveling_exit => [
    "G28"],
  :wizard_unload_filament_exit => [
    "M104 S0 T0",
    "M104 S0 T1",    
    "G28",
    "T0"],    
  :wizard_priming_init => [
    "T0"],    
  :wizard_priming_exit => [
    "M104 S0 T0",
    "M104 S0 T1",    
    "G28",
    "T0"],
  :select_left_extruder => [
    "T0"],
  :select_right_extruder => [
    "T1"],
  :reload_eeprom => [
    "M205"] 
}
