touchApp.controller('DialogShutdownController', function($scope, $timeout, $modalInstance, CommonCode, MyWebsocket){
  console.log("Running DialogShutdownController");  

  $scope.seconds = 180;
  $scope.countdown = CommonCode.formatSeconds($scope.seconds);
  $scope.title = "Please wait";
  
  MyWebsocket.macro("cooldown");
  $scope.onTimeout = function(){
    $scope.seconds--;
    $scope.countdown = CommonCode.formatSeconds($scope.seconds);    
    if ($scope.seconds > 0) {
      mytimeout = $timeout($scope.onTimeout,1000);
    } else {
      $scope.title = "Good Bye!";      
      MyWebsocket.macro("before_shutdown");      
      MyWebsocket.shutdown();
    }
  };
  var mytimeout = $timeout($scope.onTimeout, 1000);  

  $scope.cancelshutdown = function() {
    $timeout.cancel(mytimeout);
    $modalInstance.close();
  };

});