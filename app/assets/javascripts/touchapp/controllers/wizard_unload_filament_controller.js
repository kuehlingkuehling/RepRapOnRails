touchApp.controller('WizardUnloadFilamentController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running WizardUnloadFilamentController");  

  MyWebsocket.menuDisabled = true;
  $scope.step = 1;
  $scope.deviation = 3; // +/- C deviation around target temp
  $scope.filament = null;
  $scope.extruder_temp = 0;  
  $scope.extruder_preheated = false;
  $scope.extruder = null;
  
  $scope.$watch(function(){ return MyWebsocket.filamentsLoaded; }, function(newValue){
    $scope.filaments_loaded = MyWebsocket.filamentsLoaded;
  }, true);

  $scope.$watch(function(){ return MyWebsocket.temp; }, function(newValue){
    $scope.temp = MyWebsocket.temp;
  }, true);

  $scope.$watch(function(){ return MyWebsocket.temp; }, function(newValue){
    if ($scope.filament && ($scope.extruder != null) && MyWebsocket.temp[$scope.extruder]) {
      $scope.extruder_temp = MyWebsocket.temp[$scope.extruder].temp;
      if (($scope.extruder_temp > ($scope.filament.extrusion_temp - $scope.deviation)) && ($scope.extruder_temp < ($scope.filament.extrusion_temp + $scope.deviation))) {
        $scope.extruder_preheated = true;
        if ($scope.step == 2) {
          $scope.step = 3;
        }
      } else {
        $scope.extruder_preheated = false;      
      };
    };
  }, true); 
  
  // initial commands
  MyWebsocket.psu_on();
  MyWebsocket.macro('maintenance_position');
  
  $scope.step1 = function() {
    $scope.step = 1;
  };
  
  $scope.step2 = function() {
    $scope.step = 2;
    switch ($scope.extruder) {
      case 'left_extruder':
        $scope.extruder_name = "left";
        $scope.filament = $scope.filaments_loaded.left;
        $scope.extruder_number = 0;
        break;
      case 'right_extruder':
        $scope.extruder_name = "right";
        $scope.filament = $scope.filaments_loaded.right;      
        $scope.extruder_number = 1;
        break;
    };
    // preheat extruder
    MyWebsocket.set_temp([$scope.extruder_number, $scope.filament.extrusion_temp]);   
  };
  
  $scope.step3 = function() {
    $scope.step = 3;
  };
  
  $scope.step4 = function() {
    $scope.step = 4;
  };  
  
  $scope.step5 = function() {
    $scope.step = 5;
  };    
  
  $scope.exit = function() {
    MyWebsocket.macro('wizard_unload_filament_exit');
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };        
});