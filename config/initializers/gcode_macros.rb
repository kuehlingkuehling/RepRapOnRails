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
    "G1 X112 Y90"],
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
  :psu_on => [
    "M80",
    "G28",
    "T0"],
  :psu_off => [
    "M104 S0 T0",    
    "M104 S0 T1",
    "M104 S0 T2",
    "M140 S0",    
    "M81"],
  :get_temp => [
    "M105"],
  :motors_off => [
    "M84"],
  :wizard_leveling_init => [
    "T0",
    "G1 X112 Y213 Z100 F12000"],
  :wizard_leveling_preheat => [
    "M140 S100"],
  :wizard_leveling_front => [
    "G1 X140 Y150 Z20 F12000",
    "G1 Z0 F6000"],
  :wizard_leveling_right => [
    "G1 X192 Y238 Z20 F12000",
    "G1 Z0 F6000"],
  :wizard_leveling_left => [
    "G1 X86 Y238 Z20 F12000",
    "G1 Z0 F6000"],
  :wizard_leveling_center => [
    "G1 X112 Y213 Z20 F12000",
    "G1 Z0 F6000"],
  :wizard_leveling_exit => [
    "M140 S0",
    "G28"],
  :wizard_unload_filament_exit => [
    "M104 S0 T0",
    "M104 S0 T1",    
    "G28",
    "T0"],    
  :wizard_priming_init => [
    "T0",
    "G92 E0",
    "G1 F70 E0.05"],    
  :wizard_priming_exit => [
    "M104 S0 T0",
    "M104 S0 T1",    
    "G28",
    "T0"],
  :select_left_extruder => [
    "T0"],
  :select_right_extruder => [
    "T1"] 
}
