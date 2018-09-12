touchApp.controller('LockscreenController', function($scope, Printer){
  console.log("Running LockscreenController");
  
  $scope.lockscreen = Printer.lockscreen;
});