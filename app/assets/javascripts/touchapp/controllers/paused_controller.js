touchApp.controller('PausedController', function($scope, $location, $routeParams, Printer){
  console.log("Running PausedController");

  Printer.menuDisabled = false;
  
  $scope.message = $routeParams.message
  
});
