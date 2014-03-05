touchApp.controller('SetupController', function($scope, MyWebsocket){
  console.log("Running SetupController");  

  MyWebsocket.menuDisabled = false;
  
  $scope.backendurl = ' ';
  MyWebsocket.get('hostname').then(function(data){
    $scope.backendurl = 'http://' + data + '/';
  });   
  
  $scope.idle = false;
  $scope.paused = false;
  
  // some wizards are only available in specific print states
  $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    if (MyWebsocket.print.state == 1) {
      $scope.idle = true;
    } else {
      $scope.idle = false;      
    };
    
    if (MyWebsocket.print.state == 3) {
      $scope.paused = true;
    } else {
      $scope.paused = false;
    };
  }, true);   
  
});