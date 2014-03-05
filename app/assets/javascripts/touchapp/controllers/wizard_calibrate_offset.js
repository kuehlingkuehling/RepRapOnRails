touchApp.controller('WizardCalibrateOffsetController', function($scope, CommonCode, $location, $timeout, MyWebsocket){
  console.log("Running WizardCalibrateOffsetController");  

  MyWebsocket.menuDisabled = true;
  
  $scope.x_steps_per_mm = 71.1111;
  $scope.y_steps_per_mm = 106.6667;
  $scope.default_x_offset = 58.05; // in mm
  $scope.default_y_offset = 0; // in mm
  
  $scope.calibration_delta = 0.1 // in mm
  
  $scope.line_x = 0;
  $scope.line_y = 0;  
  

  $scope.generate_printjob = function() {
    $steps_x = Math.round( $scope.default_x_offset * $scope.x_steps_per_mm );
    $steps_y = Math.round( $scope.default_y_offset * $scope.y_steps_per_mm );    
    MyWebsocket.setExtruderOffset($steps_x, $steps_y);    
    MyWebsocket.calibrateOffsetPrintjob();
    MyWebsocket.menuDisabled = true;    
    $location.path( "/queue" );    
  };
  
  $scope.save = function() {
    $steps_x = Math.round(( $scope.default_x_offset + ( $scope.line_x * $scope.calibration_delta )) * $scope.x_steps_per_mm );
    $steps_y = Math.round(( $scope.default_y_offset + ( $scope.line_y * $scope.calibration_delta )) * $scope.y_steps_per_mm );        
    MyWebsocket.setExtruderOffset($steps_x, $steps_y);
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