backendApp.controller('HeaderController', function($scope, $modal, $location, $timeout, MyWebsocket){
  console.log("Running HeaderController");
  
  $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    $scope.print = MyWebsocket.print;  
  }, true);  
  
  $scope.tab = $location.path();  
  $scope.go = function( tab ){
    $location.path( tab );
    $scope.tab = $location.path();
  };
  
  $scope.progress = 0;
  $scope.time_remaining = '';
  $scope.$watch(function(){ return MyWebsocket.progress; }, function(newValue){
    $scope.progress = MyWebsocket.progress;  
    $scope.time_remaining = MyWebsocket.time_remaining;  
  }, true); 

});