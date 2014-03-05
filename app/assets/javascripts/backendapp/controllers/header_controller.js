backendApp.controller('HeaderController', function($scope, $modal, $location, $timeout, MyWebsocket){
  console.log("Running HeaderController");
  
  $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    $scope.print = MyWebsocket.print;  
  }, true);  
  
  $scope.tab = 'firststeps';
  $location.path( "/" + $scope.tab );  
  $scope.go = function( tab ){
    $location.path( "/" + tab );
    $scope.tab = tab;
  };
  
  $scope.progress = 0;

  // update progress every 3s
  (function update_progress() {
      MyWebsocket.get('progress').then(function(data){
        $scope.progress = data.percent;
        $scope.time_remaining = data.time_remaining;
        //console.log("The received Progress is:" + data)
        $timeout(update_progress, 3000);        
      });  
  })(); 

});