touchApp.factory('MyWebsocket', function($q, $location, $timeout, $rootScope) {
  var Service = {};  
  Service.log = [];
  Service.print = {
    state:0,
    job:'',
    elapsed_in_words:'',
    job_id:0,
    psu_on:false
  };
  Service.printjobs = [];
  Service.filamentPresets = [];
  Service.filamentsLoaded = {};
  Service.preheatingProfiles = [];
  Service.preheatingProfile = 0;
  Service.menuDisabled = false;  
  var deferred = $q.defer();  
  var dispatcher = new WebSocketRails(WEBSOCKET_URL);


  dispatcher.on_open = function(data) {
    console.log('WebSocket Connection has been established: ' + data);
    Service.get('status').then(function(data){
      console.log(data)
      $timeout(function(){      
        Service.print.state = data.state;
        Service.print.job = data.job;      
        Service.print.job_id = data.job_id;
        Service.print.psu_on = data.psu_on;
      });
    });     
    Service.get('logfile').then(function(data){
      $timeout(function(){
        Service.log = data;
      });
    });  
    Service.get('printjob.all').then(function(data){
      $timeout(function(){      
        Service.printjobs = data;
      });
    });
    Service.get('filament.all').then(function(data){
      $timeout(function(){
        Service.filamentPresets = data;
      });
    });
    Service.get('filament.get_loaded').then(function(data){
      $timeout(function(){
        Service.filamentsLoaded = data;
      });
    });
    Service.get('preheating_profile.all').then(function(data){
      $timeout(function(){
        Service.preheatingProfiles = data;
      });
    });
    Service.get('preheating_profile.get_selected').then(function(data){
      $timeout(function(){
        Service.preheatingProfile = data;
      });
    }); 
    Service.macro('get_temp');
    $rootScope.$apply(function(){    
      deferred.resolve(Service); 
    });    
  };    
  
  Service.online = deferred.promise;
  
  Service.get = function(event) {
    var d = $q.defer();    

    //console.log("Fetching Event \"" + event + "\" through WebSocket");
    
    var success = function(data) {
    //  console.log("Received Data for Event \"" + event + "\" through WebSocket!");
      d.resolve(data);
    };
    
    var failure = function(response) {
      console.log("Query failed: "+response.message);
      d.reject(response);
    };
    
    dispatcher.trigger(event, '', success, failure);
    //console.log("returning promise");
    return d.promise;
  };
  
  Service.sendgcode = function(gcode) {
    console.log("Sending GCODE \"" + gcode + "\" through WebSocket");
    dispatcher.trigger('sendgcode', gcode);
  }; 

  Service.macro = function(name) {
    console.log("Starting Macro \"" + name + "\" through WebSocket");
    dispatcher.trigger('macro', name);
  };  
  
  Service.move = function(coord) {
    console.log("Sending Move Coordinates \"" + coord + "\" through WebSocket");
    dispatcher.trigger('move', coord);
  };    
  
  Service.set_temp = function(params) {
    console.log("Setting Extruder Parameters to \"" + params + "\" through WebSocket");
    dispatcher.trigger('set_temp', params);
  }; 
  
  Service.extrude = function(params) {
    console.log("Sending Extrusion Parameters \"" + params + "\" through WebSocket");
    dispatcher.trigger('extrude', params);
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
    console.log('New Temp String received!');
    //console.log(message);    
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
    console.log('New Printer State received: ' + message);
    // 0: Offline
    // 1: Idle
    // 2: Printing
    // 3: Paused
    // 4: Emergency Stop
    // 5: Preheating
    $timeout(function(){
      Service.print.state = message;
    });
  });    
  printchannel.bind('job', function(message){
    console.log('New Printer Job Name String received: ' + message);
    $timeout(function(){
      Service.print.job = message.name;
      Service.print.job_id = message.job_id;
    });
  }); 
  printchannel.bind('psu', function(message){
    console.log('New PSU_on status received: ' + message);
    $timeout(function(){
      Service.print.psu_on = message;
    });
  }); 
  printchannel.bind('finished', function(message){
    console.log('New Printjob Finished Message received: ' + message.id);
    $timeout(function(){    
      Service.print.elapsed_in_words = message.elapsed;
    });
    $location.path( "/print_finished/" + message.id );
  });   
  printchannel.bind('out_of_filament', function(spool){
    console.log('Out-of-Filament Message received: ' + spool);
    $location.path( "/out_of_filament/" + spool );
  });     
  
  Service.lockscreen = {locked:false};
  lockscreenchannel = dispatcher.subscribe('lockscreen');
  lockscreenchannel.bind('toggle', function(message){
    console.log('Lockscreen toggle triggered!');
    $timeout(function(){
      Service.lockscreen.locked = !Service.lockscreen.locked;
    });
  });    
  
  Service.startprint = function(id) {
    console.log("STARTING PRINTJOB");
    dispatcher.trigger('startprint', id);
  }; 
  
  Service.abortprint = function() {
    console.log("ABORTING PRINTJOB");
    dispatcher.trigger('abortprint');
  }; 
  
  Service.pauseprint = function() {
    console.log("PAUSED PRINTJOB");
    dispatcher.trigger('pauseprint');
  }; 
  
  Service.resumeprint = function() {
    console.log("RESUMING PRINTJOB");
    dispatcher.trigger('resumeprint');
  }; 
  
  Service.shutdown = function() {
    console.log("SHUTTING DOWN THE MACHINE");
    dispatcher.trigger('shutdown');
  };   
  
  Service.removePrintjob = function(id) {
    dispatcher.trigger('printjob.remove', id);
  };  
  
  Service.calibrateOffsetPrintjob = function() {
    dispatcher.trigger("printjob.calibrate_offset");
  };
  
  Service.calibrateExtrusionPrintjob = function(ext) {
    dispatcher.trigger("printjob.calibrate_extrusion", ext);
  };  
  
  Service.setExtruderOffset = function(x, y) {
    dispatcher.trigger("set_extruder_offset", [x, y]);
  };  

  Service.preheat = function(chamber, bed) {
    dispatcher.trigger("preheat", [chamber, bed]);
  };  
  
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
  
  Service.setFilaments = function(filaments) {
    // filaments.left => ID
    // filaments.right => ID
    dispatcher.trigger('filament.set_loaded', filaments);
  };  

  preheatingchannel = dispatcher.subscribe('preheating_profiles');
  preheatingchannel.bind('reload', function(message){
    console.log('Preheating Profiles updated, reloading!');
    $timeout(function(){
      Service.get('preheating_profile.all').then(function(data){
        Service.preheatingProfiles = data;
console.log(data);
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
  
  Service.setPreheatingProfile = function(id) {
    dispatcher.trigger('preheating_profile.set_selected', id);
  };    
  
  return Service;
});