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
  
  $scope.nominal= 20;
  $scope.x1= 10;
  $scope.x2= 30;
  $scope.y1= 10;
  $scope.y2= 30;
  
  $scope.save = function() {
    deviation_x = (($scope.x2 + $scope.x1) * 0.5) - $scope.nominal;
    deviation_y = (($scope.y2 + $scope.y1) * 0.5) - $scope.nominal;

    $steps_x = Math.round( $scope.x_offset - ( deviation_x * $scope.x_steps_per_mm ));
    $steps_y = Math.round( $scope.y_offset - ( deviation_y * $scope.y_steps_per_mm ));

    MyWebsocket.setEEPROM(331, $scope.eeprom[331].type, $steps_x); // Ext2 X Offset in steps
    MyWebsocket.setEEPROM(335, $scope.eeprom[335].type, $steps_y); // Ext2 X Offset in steps
    $scope.exit();
  };  
  

  $scope.adjust_nominal = function(val) {
    $scope.nominal += val;
  };

  $scope.adjust_x1 = function(val) {
    $scope.x1 += val;
  };

  $scope.adjust_x2 = function(val) {
    $scope.x2 += val;
  };

  $scope.adjust_y1 = function(val) {
    $scope.y1 += val;
  };

  $scope.adjust_y2 = function(val) {
    $scope.y2 += val;
  };


  $scope.exit = function() {
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };    

});