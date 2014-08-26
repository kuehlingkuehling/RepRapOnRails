touchApp.controller('HeaderController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running HeaderController");
  
  $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    $scope.print = MyWebsocket.print;  
  }, true);  
  
  $scope.$watch(function(){ return MyWebsocket.menuDisabled; }, function(newValue){
    $scope.menuDisabled = MyWebsocket.menuDisabled;  
  }, true);    
   
  $scope.$on('$locationChangeSuccess', function(event) {
    $scope.path = $location.path();
    $scope.tab = $scope.path.substr(1, $scope.path.length);
  });  
  $scope.go = function( tab ){
    $location.path( "/" + tab );
  };
  
  $scope.emergencyStop = function(){
    MyWebsocket.emergencystop();
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
  
  $scope.abortprint = function() {
    MyWebsocket.abortprint();
  };  
  
  $scope.pauseprint = function() {
    MyWebsocket.pauseprint();    
    MyWebsocket.macro("maintenance_position");    
  };    
  
  $scope.resumeprint = function() {
    MyWebsocket.resumeprint();
    $scope.go("queue");
  };

  $scope.temp = MyWebsocket.temp;    
});