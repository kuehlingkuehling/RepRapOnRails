touchApp.controller('WizardNozzleChangeController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running WizardNozzleChangeController");  

  MyWebsocket.menuDisabled = true;
  $scope.step = 1;
  
  // initial commands
  MyWebsocket.psu_on();
  MyWebsocket.macro('maintenance_position');  
  
  $scope.step1 = function() {
    $scope.step = 1;
  };
  
  $scope.step2 = function() {
    $scope.step = 2;
  };
  
  $scope.step3 = function() {
    $scope.step = 3;
    MyWebsocket.macro('wizard_leveling_center');
  };
  
  $scope.exit = function() {
    MyWebsocket.macro('home_all');
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };    
});