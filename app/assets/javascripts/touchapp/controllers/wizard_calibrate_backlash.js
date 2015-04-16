touchApp.controller('WizardCalibrateBacklashController', function($scope, CommonCode, $location, $timeout, MyWebsocket){
  console.log("Running WizardCalibrateBacklashController");

  MyWebsocket.menuDisabled = true;

  $scope.config_loaded = false;
  $scope.calibrating = false;
  $scope.x_is_calibrating = false;
  $scope.y_is_calibrating = false;
  $scope.backlash_x = null;
  $scope.backlash_y = null;
  $scope.is_saving = false;
  $scope.done = false;
  $scope.error_message = null;

  // activate build chamber
  MyWebsocket.psu_on();

  MyWebsocket.reloadEEPROM();
  $scope.$watch(function(){ return MyWebsocket.eeprom; }, function(newValue){
    $scope.eeprom = MyWebsocket.eeprom;  

    if ( $scope.eeprom[157] && $scope.eeprom[161] && $scope.eeprom[331] && $scope.eeprom[335] ){
      $scope.backlash_x_backup = $scope.eeprom[157].val;
      $scope.backlash_y_backup = $scope.eeprom[161].val;
      $scope.extr2_x_offset = $scope.eeprom[331].val;
      $scope.extr2_y_offset = $scope.eeprom[335].val;

      $scope.config_loaded = true;
    }
  }, true); 
  
  $scope.start_calibration = function() {
    console.log("starting calibration");
    $scope.calibrating = true;
    // set extruder 2 offset values to zero
    MyWebsocket.setEEPROM(331, $scope.eeprom[331].type, 0); // Ext2 X Offset
    MyWebsocket.setEEPROM(335, $scope.eeprom[335].type, 0); // Ext2 Y Offset  

    // set backlash calibration to zero
    MyWebsocket.setEEPROM(157, $scope.eeprom[157].type, $scope.backlash_x); // X Backlash
    MyWebsocket.setEEPROM(161, $scope.eeprom[161].type, $scope.backlash_y); // Y Backlash              

    // start calibration sequence
    MyWebsocket.macro('home_all');    
    $scope.calibrate_x();
  };

  $scope.calibrate_x = function() {
    $scope.x_is_calibrating = true;
    MyWebsocket.get("measure_backlash", ["x", 0.01, 100]).then(function(response){
        // success handling
        $scope.backlash_x = +(Math.round(response + "e+2")  + "e-2"); // rounded to 2 decimal places
        $scope.calibrate_y();
      }, function(response){
        // error handling
        $scope.error_message = response;
        $scope.reset();
      });
  };

  $scope.calibrate_y = function() {
    $scope.y_is_calibrating = true;
    MyWebsocket.get("measure_backlash", ["y", -0.01, 100]).then(function(response){
        // success handling
        $scope.backlash_y = +(Math.round(response + "e+2")  + "e-2"); // rounded to 2 decimal places
        $scope.save();
      }, function(response){
        // error handling
        $scope.error_message = response;
        $scope.reset();
      });
  };
  
  $scope.save = function() {
    $scope.is_saving = true;
    // save measured backlash values to EEPROM
    MyWebsocket.setEEPROM(157, $scope.eeprom[157].type, $scope.backlash_x); // X Backlash
    MyWebsocket.setEEPROM(161, $scope.eeprom[161].type, $scope.backlash_y); // Y Backlash

    // set extruder 2 offset values again in EEPROM
    MyWebsocket.setEEPROM(331, $scope.eeprom[331].type, $scope.extr2_x_offset); // Ext2 X Offset
    MyWebsocket.setEEPROM(335, $scope.eeprom[335].type, $scope.extr2_y_offset); // Ext2 Y Offset     

    MyWebsocket.macro('home_all');
    $scope.done = true;
  };  
  
  $scope.reset = function() {
    if ($scope.config_loaded) {
      // save measured backlash values to EEPROM
      MyWebsocket.setEEPROM(157, $scope.eeprom[157].type, $scope.backlash_x_backup); // X Backlash
      MyWebsocket.setEEPROM(161, $scope.eeprom[161].type, $scope.backlash_y_backup); // Y Backlash

      // set extruder 2 offset values again in EEPROM
      MyWebsocket.setEEPROM(331, $scope.eeprom[331].type, $scope.extr2_x_offset); // Ext2 X Offset
      MyWebsocket.setEEPROM(335, $scope.eeprom[335].type, $scope.extr2_y_offset); // Ext2 Y Offset    
    };
    
    MyWebsocket.macro('home_all');
  }

  $scope.cancel = function() {
    $scope.reset();
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };   

  $scope.ok = function() {
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };      

});