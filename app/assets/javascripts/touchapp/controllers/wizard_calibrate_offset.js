touchApp.controller('WizardCalibrateOffsetController', function($scope, CommonCode, $location, $timeout, MyWebsocket){
  console.log("Running WizardCalibrateOffsetController");

  MyWebsocket.menuDisabled = true;

  $scope.config_loaded = false;

  MyWebsocket.reloadEEPROM();
  $scope.$watch(function(){ return MyWebsocket.eeprom; }, function(newValue){
    $scope.eeprom = MyWebsocket.eeprom;  

    if ( $scope.eeprom[3] && $scope.eeprom[7] && $scope.eeprom[331] && $scope.eeprom[335] ){
      $scope.x_steps_per_mm = $scope.eeprom[3].val;
      $scope.y_steps_per_mm = $scope.eeprom[7].val;
      $scope.x_offset = $scope.eeprom[331].val;
      $scope.y_offset = $scope.eeprom[335].val;

      $scope.config_loaded = true;
    }
  }, true); 
  
  $scope.calibration_delta = 0.1; // in mm
  
  $scope.line_x = 0;
  $scope.line_y = 0;  
  

  $scope.generate_printjob = function() {
    MyWebsocket.calibrateOffsetPrintjob();
    MyWebsocket.menuDisabled = true;    
    $location.path( "/queue" );    
  };
  
  $scope.save = function() {
    $steps_x = Math.round( $scope.x_offset - ( $scope.line_x * $scope.calibration_delta * $scope.x_steps_per_mm ));
    $steps_y = Math.round( $scope.y_offset - ( $scope.line_y * $scope.calibration_delta * $scope.y_steps_per_mm ));
    //$steps_x = Math.round(( $scope.x_offset + ( $scope.line_x * $scope.calibration_delta )) * $scope.x_steps_per_mm );
    //$steps_y = Math.round(( $scope.y_offset + ( $scope.line_y * $scope.calibration_delta )) * $scope.y_steps_per_mm );        
    MyWebsocket.setEEPROM(331, $scope.eeprom[331].type, $steps_x); // Ext2 X Offset in steps
    MyWebsocket.setEEPROM(335, $scope.eeprom[335].type, $steps_y); // Ext2 X Offset in steps
    $scope.exit();
  };  
  
  $scope.dec_x = function() {
    $scope.line_x -= 1;
  };
  
  $scope.dec_y = function() {
    $scope.line_y -= 1;    
  };
  
  $scope.inc_x = function() {
    $scope.line_x += 1;    
  };
  
  $scope.inc_y = function() {
    $scope.line_y += 1;    
  };

  $scope.exit = function() {
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };    

});