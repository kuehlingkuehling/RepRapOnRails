touchApp.controller('WizardUnloadFilamentController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running WizardUnloadFilamentController");  

  MyWebsocket.menuDisabled = true;
  $scope.step = 1;
  $scope.filament = null;
  $scope.extruder_temp = 0;  
  $scope.extruder_preheated = false;
  $scope.extruder = null;
  
  $scope.$watch(function(){ return MyWebsocket.filamentsLoaded; }, function(newValue){
    $scope.filaments_loaded = MyWebsocket.filamentsLoaded;
  }, true);

  $scope.$watch(function(){ return MyWebsocket.temp; }, function(newValue){
    if ($scope.filament && ($scope.extruder != null) && MyWebsocket.temp.list[$scope.extruder]) {
      $scope.extruder_temp = MyWebsocket.temp.list[$scope.extruder].temp;
      if ($scope.extruder_temp > (0.99 * $scope.filament.extrusion_temp)) {
        $scope.extruder_preheated = true;
      } else {
        $scope.extruder_preheated = false;      
      };
    };
  }, true); 
  
  // initial commands
  MyWebsocket.macro('psu_on');
  MyWebsocket.macro('get_temp');
  MyWebsocket.macro('maintenance_position');
  
  $scope.step1 = function() {
    $scope.step = 1;
  };
  
  $scope.step2 = function() {
    $scope.step = 2;
    switch ($scope.extruder) {
      case 0:
        $scope.extruder_name = "left";
        $scope.filament = $scope.filaments_loaded.left;
        break;
      case 1:
        $scope.extruder_name = "right";
        $scope.filament = $scope.filaments_loaded.right;      
        break;
    };
    // preheat extruder
    MyWebsocket.set_temp([$scope.extruder, $scope.filament.extrusion_temp]);   
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