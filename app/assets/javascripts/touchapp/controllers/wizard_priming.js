touchApp.controller('WizardPrimingController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running WizardPrimingController");  

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
  
  // get temperatures every 3s
  $scope.update_temps = function() {
    MyWebsocket.macro('get_temp');
    $scope.update_temps_timeout = $timeout($scope.update_temps, 3000);        
  };
  $scope.update_temps_timeout = $timeout($scope.update_temps, 3000);  
  
  // initial commands
  MyWebsocket.macro('psu_on');
  MyWebsocket.macro('maintenance_position');
  
  $scope.step1 = function() {
    $scope.step = 1;
    
    // when coming here back from step 2, disable extruders - just in case
    MyWebsocket.set_temp([0, 0]);    
    MyWebsocket.set_temp([1, 0]);    
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
  
  $scope.extrude = function () {
    // manually extrude 5mm
    MyWebsocket.extrude([$scope.extruder, 5]);
  };
  
  $scope.exit = function() {
    MyWebsocket.macro('wizard_priming_exit');
    MyWebsocket.menuDisabled = false;
    $timeout.cancel($scope.update_temps_timeout);
    $location.path( "/setup" );
  };        
  
  $scope.select_profiles = function() {
    MyWebsocket.macro('wizard_priming_exit');
    MyWebsocket.menuDisabled = false;
    $timeout.cancel($scope.update_temps_timeout);
    $location.path( "/wizard_select_filament" );
  };     
});