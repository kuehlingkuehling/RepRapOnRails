touchApp.controller('WizardUnloadFilamentController', function($scope, $location, $timeout, Printer){
  console.log("Running WizardUnloadFilamentController");  

  Printer.menuDisabled = true;
  $scope.step = 1;
  $scope.deviation = 3; // +/- C deviation around target temp
  $scope.filament = null;
  $scope.extruder_temp = 0;  
  $scope.extruder_preheated = false;
  $scope.extruder = null;
  
  $scope.$watch(function(){ return Printer.filamentsLoaded; }, function(newValue){
    $scope.filaments_loaded = Printer.filamentsLoaded;
  }, true);

  $scope.$watch(function(){ return Printer.isDualExtruder; }, function(){
    $scope.isDualExtruder = Printer.isDualExtruder;
    if (!$scope.isDualExtruder) {
      $scope.extruder = 'left_extruder';
    }
  },true);

  $scope.$watch(function(){ return Printer.temp; }, function(newValue){
    $scope.temp = Printer.temp;
  }, true);

  $scope.$watch(function(){ return Printer.temp; }, function(newValue){
    if ($scope.filament && ($scope.extruder != null) && Printer.temp[$scope.extruder]) {
      $scope.extruder_temp = Printer.temp[$scope.extruder].temp;
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
  Printer.psu_on();
  Printer.macro('maintenance_position');
  
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
    Printer.set_temp([$scope.extruder_number, $scope.filament.extrusion_temp]);   
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
    Printer.macro('wizard_unload_filament_exit');
    Printer.menuDisabled = false;
    $location.path( "/setup" );
  };        
});