touchApp.controller('PrintCheckController', function($scope, $location, $routeParams, Printer, CommonCode){
  console.log("Running PrintCheckController");
  
  $scope.printjobId = $routeParams.printjobId;
  $scope.$watch(function(){ return Printer.printjobs; }, function(){
    $scope.printjob = CommonCode.getById(Printer.printjobs, $scope.printjobId);
  },true);   

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
