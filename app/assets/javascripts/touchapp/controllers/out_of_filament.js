touchApp.controller('OutOfFilamentController', function($scope, $location, $routeParams, MyWebsocket){
  console.log("Running OutOfFilamentController");

  MyWebsocket.menuDisabled = false;
  
  $scope.spool = $routeParams.spool
  
});
