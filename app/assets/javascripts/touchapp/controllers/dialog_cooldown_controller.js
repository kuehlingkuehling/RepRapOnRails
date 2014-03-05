touchApp.controller('DialogCooldownController', function($scope, $timeout, $modalInstance, CommonCode, MyWebsocket){
  console.log("Running DialogCooldownController");  

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
      MyWebsocket.macro("psu_off");      
      $modalInstance.close();
    }
  };
  var mytimeout = $timeout($scope.onTimeout, 1000);  

  $scope.cancelshutdown = function() {
    $timeout.cancel(mytimeout);
    $modalInstance.close();
  };

});