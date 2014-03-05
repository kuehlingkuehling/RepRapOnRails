touchApp.controller('LockscreenController', function($scope, MyWebsocket){
  console.log("Running LockscreenController");
  
  $scope.lockscreen = MyWebsocket.lockscreen;
});