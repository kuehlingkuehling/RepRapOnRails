WebsocketRails::EventMap.describe do
  # You can use this file to map incoming events to controller actions.
  # One event can be mapped to any number of controller actions. The
  # actions will be executed in the order they were subscribed.
  #
  # Uncomment and edit the next line to handle the client connected event:
  #   subscribe :client_connected, :to => Controller, :with_method => :method_name
  #
  # Here is an example of mapping namespaced events:
  #   namespace :product do
  #     subscribe :new, :to => ProductController, :with_method => :new_product
  #   end
  # The above will handle an event triggered on the client like `product.new`.

  namespace :print do
    subscribe :start, :to => WsController, :with_method => :startprint
  end
  
  namespace :printjob do  
    subscribe :all, :to => PrintjobController, :with_method => :all
    subscribe :remove, :to => PrintjobController, :with_method => :remove
    subscribe :update, :to => PrintjobController, :with_method => :update
    subscribe :calibrate_offset, :to => PrintjobController, :with_method => :calibrate_offset
    subscribe :calibrate_extrusion, :to => PrintjobController, :with_method => :calibrate_extrusion    
  end
  
  namespace :filament do  
    subscribe :all, :to => FilamentController, :with_method => :all
    subscribe :create, :to => FilamentController, :with_method => :create    
    subscribe :delete, :to => FilamentController, :with_method => :delete
    subscribe :update, :to => FilamentController, :with_method => :update
    subscribe :get_loaded, :to => FilamentController, :with_method => :get_loaded
    subscribe :set_loaded, :to => FilamentController, :with_method => :set_loaded   
  end  

  namespace :preheating_profile do  
    subscribe :all, :to => PreheatingProfileController, :with_method => :all
    subscribe :create, :to => PreheatingProfileController, :with_method => :create    
    subscribe :delete, :to => PreheatingProfileController, :with_method => :delete
    subscribe :update, :to => PreheatingProfileController, :with_method => :update
    subscribe :get_selected, :to => PreheatingProfileController, :with_method => :get_selected
    subscribe :set_selected, :to => PreheatingProfileController, :with_method => :set_selected   
  end    

  subscribe :sendgcode, :to => WsController, :with_method => :sendgcode  
  subscribe :emergencystop, :to => WsController, :with_method => :emergencystop
  subscribe :progress, :to => WsController, :with_method => :progress
  subscribe :startprint, :to => WsController, :with_method => :startprint
  subscribe :abortprint, :to => WsController, :with_method => :abortprint  
  subscribe :pauseprint, :to => WsController, :with_method => :pauseprint  
  subscribe :resumeprint, :to => WsController, :with_method => :resumeprint 
  subscribe :shutdown, :to => WsController, :with_method => :shutdown  
  subscribe :hostname, :to => WsController, :with_method => :hostname
  subscribe :firmware_version, :to => WsController, :with_method => :firmware_version
  subscribe :logfile, :to => WsController, :with_method => :logfile  
  subscribe :status, :to => WsController, :with_method => :status
  subscribe :macro, :to => WsController, :with_method => :macro  
  subscribe :move, :to => WsController, :with_method => :move    
  subscribe :set_temp, :to => WsController, :with_method => :set_temp 
  subscribe :preheat, :to => WsController, :with_method => :preheat
  subscribe :psu_on, :to => WsController, :with_method => :psu_on
  subscribe :extrude, :to => WsController, :with_method => :extrude 
  subscribe :set_eeprom, :to => WsController, :with_method => :set_eeprom
 
end