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
    "G28",
    "M42 P35 S0"],
  :after_pause => [              # deprecated - now implemented in repraphost.rb
    "M104 S0 T0",
    "M104 S0 T1",
    "G28"],
  :maintenance_position => [
    "T0",
    "G1 X%d Y%d F12000" % [ Rails.application.config.maintenance_position[0], Rails.application.config.maintenance_position[1] ]],
  :home_all => [
    "G28"],
  :relative_positioning => [
    "G91"],
  :absolute_positioning => [
    "G90"],
  :psu_on => [],                  # deprecated - now implemented in ws_controller.rb
  :psu_off => [
    "M104 S0 T0",    
    "M104 S0 T1",
    "M104 S0 T2",
    "M140 S0",
    "M42 P35 S0",   # vacuum off
    "M42 P48 S0",   # lights off
    "M81"],
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
