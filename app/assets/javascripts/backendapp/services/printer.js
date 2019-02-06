backendApp.factory('Printer', function($q, $timeout, $modal, $rootScope) {
  var Service = {};  
  Service.log = [];
  Service.print = {
    state:0,
    job:'',
    elapsed_in_words:'',
    job_id:0,
    progress:0,
    time_remaining:''
  };
  Service.printjobs = [];
  Service.filamentPresets = [];
  Service.preheatingProfiles = [];
  Service.preheatingProfile = 0;
  Service.isDualExtruder = false;
  Service.eeprom = {};
  var deferred = $q.defer();  
  var dispatcher = new WebSocketRails(WEBSOCKET_URL);


  dispatcher.on_open = function(data) {
    console.log('WebSocket Connection has been established: ' + data);
    $rootScope.$apply(function(){    
      deferred.resolve(Service); 
    });    
    Service.get('logfile').then(function(data){
      Service.log = data;
    });  
    Service.get('is_dual_extruder').then(function(data){
      $timeout(function(){
        Service.isDualExtruder = data;
      });
    });
    Service.get('status').then(function(data){
      console.log(data)
      $timeout(function(){      
        Service.print.state = data.state;
        Service.print.job = data.job;      
        Service.print.job_id = data.job_id;
      });
    });       
    Service.get('printjob.all').then(function(data){
      Service.printjobs = data;
    });         
    Service.get('filament.all').then(function(data){
      Service.filamentPresets = data;
    });    
    Service.get('filament.get_loaded').then(function(data){
      $timeout(function(){
        Service.filamentsLoaded = data;
      });
    });  
    Service.get('preheating_profile.all').then(function(data){
      Service.preheatingProfiles = data;
    });  
    Service.get('preheating_profile.get_selected').then(function(data){
      $timeout(function(){
        Service.preheatingProfile = data;
      });
    }); 
  };  
    
  // bind to disconnect event - show "please reload page" modal
  dispatcher.bind('connection_closed', function() {
    console.log("WebSocket connection_closed event triggered!");
    var reloadModal = $modal.open({
      templateUrl: 'reloadpage_modal.html', // statically included in backendapp.html.erb
      controller: 'ReloadPageModalController',
      backdrop: 'static'
    });
  });

  
  
  Service.online = deferred.promise;
  
  Service.get = function(event) {
    var d = $q.defer();    

//    console.log("Fetching Event \"" + event + "\" through WebSocket");
    
    var success = function(data) {
//      console.log("Received Data for Event \"" + event + "\" through WebSocket!");
      d.resolve(data);
    };
    
    var failure = function(response) {
      console.log("Query failed: "+response.message);
      d.reject(response);
    };
    
    dispatcher.trigger(event, '', success, failure);
//    console.log("returning promise");
    return d.promise;
  };
  
  Service.sendgcode = function(gcode) {
    console.log("Sending GCODE \"" + gcode + "\" through WebSocket");
    dispatcher.trigger('sendgcode', gcode);
  }; 
  
  Service.emergencystop = function() {
    console.log("EMERGENCY STOP - resetting printer");
    dispatcher.trigger('emergencystop');
  }; 
  

  logchannel = dispatcher.subscribe('log');
  logchannel.bind('new', function(message){
    console.log('New Log Message: ' + message);
    $timeout(function(){
      Service.log.unshift(message);
      //make sure we only keep a maximum of 100 lines in log   
      while (Service.log.length > 100) {
        Service.log.pop(); 
      }
    });
  });

  Service.temp = {};
  tempchannel = dispatcher.subscribe('temp');
  tempchannel.bind('new', function(message){
    console.log('New Temp String received: ' + message);
    $timeout(function(){
      Service.temp = message;
    });
  });  
  
  jobchannel = dispatcher.subscribe('printjobs');
  jobchannel.bind('reload', function(message){
    console.log('Queue updated, reloading!');
    $timeout(function(){
      Service.get('printjob.all').then(function(data){
        Service.printjobs = data;
      }); 
    });
  });    
  
  printchannel = dispatcher.subscribe('print');
  printchannel.bind('state', function(message){
    console.log('New Printer State String received: ' + message);
    $timeout(function(){
      Service.print.state = message;
    });
  }); 
  printchannel.bind('progress', function(message){
    console.log('New Progress update received: ' + message);
    $timeout(function(){
      Service.print.progress = message.percent;
      Service.print.time_remaining = message.time_remaining;
    });
  });     
  printchannel.bind('job', function(message){
    console.log('New Printer Job Name String received: ' + message);
    $timeout(function(){
      Service.print.job = message.name;
      Service.print.job_id = message.job_id;
    });
  });   
  
  Service.lockscreen = {locked:false};
  lockscreenchannel = dispatcher.subscribe('lockscreen');
  lockscreenchannel.bind('toggle', function(message){
    console.log('Lockscreen toggle triggered!');
    $timeout(function(){
      Service.lockscreen.locked = !Service.lockscreen.locked;
    });
  });    
  
  Service.shutdown = function() {
    console.log("SHUTTING DOWN THE MACHINE");
    dispatcher.trigger('shutdown');
  };   
  
  Service.removePrintjob = function(id) {
    dispatcher.trigger('printjob.remove', id);
  }; 
  
  Service.updatePrintjob = function(job) {
    dispatcher.trigger('printjob.update', job);
  };  

  // Filament Profiles
  filamentchannel = dispatcher.subscribe('filaments');
  filamentchannel.bind('reload', function(message){
    console.log('Filaments updated, reloading!');
    $timeout(function(){
      Service.get('filament.all').then(function(data){
        Service.filamentPresets = data;
      }); 
    });
  });     
  filamentchannel.bind('reload_loaded', function(message){
    console.log('Loaded Filaments changed, reloading!');
    $timeout(function(){
      Service.get('filament.get_loaded').then(function(data){
        Service.filamentsLoaded = data;
      }); 
    });
  });
  
  
  Service.createPreset = function(preset) {
    dispatcher.trigger('filament.create', preset);
  }
  
  Service.deletePreset = function(id) {
    dispatcher.trigger('filament.delete', id);
  }
  
  Service.updatePreset = function(preset) {
    dispatcher.trigger('filament.update', preset);
  }   
  
  // Preheating Profiles
  preheatingchannel = dispatcher.subscribe('preheating_profiles');
  preheatingchannel.bind('reload', function(message){
    console.log('Preheating Profiles updated, reloading!');
    $timeout(function(){
      Service.get('preheating_profile.all').then(function(data){
        Service.preheatingProfiles = data;   
      }); 
    });
  });     
  preheatingchannel.bind('reload_selected', function(message){
    console.log('Loaded Preheating Profile changed, reloading!');
    $timeout(function(){
      Service.get('preheating_profile.get_selected').then(function(data){
        Service.preheatingProfile = data;
      }); 
    });
  });   
  
  
  Service.createPreheatingProfile = function(preset) {
    dispatcher.trigger('preheating_profile.create', preset);
  }
  
  Service.deletePreheatingProfile = function(id) {
    dispatcher.trigger('preheating_profile.delete', id);
  }
  
  Service.updatePreheatingProfile = function(preset) {
    dispatcher.trigger('preheating_profile.update', preset);
  }   


  eepromchannel = dispatcher.subscribe('eeprom');
  eepromchannel.bind('line', function(config){
    $timeout(function(){
      Service.eeprom[config.pos] = {
        type:config.type,
        val:config.val,        
        name:config.name
      };
    });
  });

  Service.reloadEEPROM = function() {
    Service.eeprom = {};
    dispatcher.trigger('macro', 'reload_eeprom');
  };   

  Service.setEEPROM = function(pos, type, val) {
    dispatcher.trigger("set_eeprom", [pos, type, val]);
  };  

  return Service;
});