touchApp.controller('WizardLoadFilamentController', function($scope, $location, $timeout, Printer){
  console.log("Running WizardLoadFilamentController");  

  Printer.menuDisabled = true;
  $scope.step = 1;
  
  // initial commands
  Printer.psu_on();
  Printer.macro('maintenance_position');
  
  $scope.step1 = function() {
    $scope.step = 1;
  };
  
  $scope.step2 = function() {
    $scope.step = 2;
  };
  
  $scope.step3 = function() {
    $scope.step = 3;
  };
  
  $scope.step4 = function() {
    $scope.step = 4;
  }; 
  
  $scope.exit = function() {
    Printer.macro('home_all');
    Printer.menuDisabled = false;
    $location.path( "/setup" );
  };     

});