touchApp.controller('PausedController', function($scope, $location, $routeParams, MyWebsocket){
  console.log("Running PausedController");

  MyWebsocket.menuDisabled = false;
  
  $scope.message = $routeParams.message
  
});
