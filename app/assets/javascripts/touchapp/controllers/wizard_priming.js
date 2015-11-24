touchApp.controller('WizardPrimingController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running WizardPrimingController");  

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
    if ($scope.filament && ($scope.extruder != null) && MyWebsocket.temp[$scope.extruder]) {
      $scope.extruder_temp = MyWebsocket.temp[$scope.extruder].temp;
      if (($scope.extruder_temp > ($scope.filament.extrusion_temp - $scope.deviation)) && ($scope.extruder_temp < ($scope.filament.extrusion_temp + $scope.deviation))) {
        $scope.extruder_preheated = true;
      } else {
        $scope.extruder_preheated = false;      
      };
    };
  }, true);  

  $scope.$watch(function(){ return MyWebsocket.isDualExtruder; }, function(){
    $scope.isDualExtruder = MyWebsocket.isDualExtruder;
    if (!$scope.isDualExtruder) {
      $scope.extruder = 'left_extruder';
    }
  },true); 
    
  // initial commands
  MyWebsocket.psu_on();
  MyWebsocket.macro('maintenance_position');
  MyWebsocket.macro('wizard_priming_init');
  
  $scope.step1 = function() {
    $scope.step = 1;
    
    // when coming here back from step 2, disable extruders - just in case
    MyWebsocket.set_temp([0, 0]);    
    MyWebsocket.set_temp([1, 0]);    
  };
  
  $scope.step2 = function() {
    $scope.step = 2;
    switch ($scope.extruder) {
      case 'left_extruder':
        $scope.extruder_name = "left";
        $scope.filament = $scope.filaments_loaded.left;
        $scope.extruder_number = 0;
        MyWebsocket.macro('select_left_extruder');
        break;
      case 'right_extruder':
        $scope.extruder_name = "right";
        $scope.filament = $scope.filaments_loaded.right; 
        $scope.extruder_number = 1;     
        MyWebsocket.macro('select_right_extruder');
        break;
    }; 
    // preheat extruder
    MyWebsocket.set_temp([$scope.extruder_number, $scope.filament.extrusion_temp]);        
  };
  
  $scope.extrude = function () {
    // manually extrude 5mm
    MyWebsocket.extrude([$scope.extruder_number, 5]);
  };
  
  $scope.exit = function() {
    MyWebsocket.macro('wizard_priming_exit');
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };        
  
});