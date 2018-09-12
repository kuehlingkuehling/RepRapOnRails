touchApp.controller('PrintCheckController', function($scope, $location, $routeParams, Printer){
  console.log("Running PrintCheckController");
  
  $scope.startprint = function() {
    Printer.startprint($routeParams.printjobId);
    $location.path( "/queue" );
  };
  
  $scope.$watch(function(){ return Printer.print; }, function(newValue){
    if (Printer.print.state == 1) {
      $scope.idle = true;
    } else {
      $scope.idle = false;      
    };
  }, true);     
  
});
