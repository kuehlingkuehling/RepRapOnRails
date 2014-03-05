backendApp.controller('LogController', function($scope, MyWebsocket, CommonCode){
  console.log("Running LogController");  

  // watch log for changes  
  $scope.$watch(function(){ return MyWebsocket.log; }, function(newValue){
    $scope.log = MyWebsocket.log;      
  }, true);   

});