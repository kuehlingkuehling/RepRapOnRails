touchApp.controller('PrintCheckController', function($scope, $location, $routeParams, MyWebsocket){
  console.log("Running PrintCheckController");
  
  $scope.startprint = function() {
    MyWebsocket.startprint($routeParams.printjobId);
    $location.path( "/queue" );
  };
  
  $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    if (MyWebsocket.print.state == 1) {
      $scope.idle = true;
    } else {
      $scope.idle = false;      
    };
  }, true);     
  
});
