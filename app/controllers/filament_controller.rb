class FilamentController < WebsocketRails::BaseController
  def initialize_session
    # perform application setup here
    @@printer = ApplicationController.printer
    @@printjob = ApplicationController.printjob    
  end
  
  def all
    trigger_success Filament.all
  end
  
  def create
    f = message
    Filament.create(
      :name => f[:name],
      :extrusion_temp => f[:extrusion_temp].to_i
    )
  end
  
  def delete
    f = message
    Filament.destroy(f)
  end
  
  def update
    f = message
    filament = Filament.find(f[:id])
    filament.update(
      :name => f[:name],
      :extrusion_temp => f[:extrusion_temp].to_i
    )
  end   
  
  def get_loaded
    # return temp presets for left and right extruder
    currently_loaded = {
      :left => ( Settings.filament_left ? Filament.find(Settings.filament_left) : 0 ),
      :right => ( Settings.filament_right ? Filament.find(Settings.filament_right) : 0)
    }
    trigger_success currently_loaded
  end
  
  def set_loaded
    # set loaded preset for left and right extruder
    Settings.filament_left = message[:left]
    Settings.filament_right = message[:right]

    WebsocketRails[:filaments].trigger(:reload_loaded)
  end
  
end