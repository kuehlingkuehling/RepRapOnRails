touchApp.controller('FooterController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running FooterController");
 
  $scope.$watch(function(){ return MyWebsocket.filamentsLoaded; }, function(){
    $scope.filaments = MyWebsocket.filamentsLoaded;
    console.log($scope.filaments);
  },true);  

  $scope.$watch(function(){ return MyWebsocket.preheatingProfile; }, function(){
    $scope.preheatingProfile = MyWebsocket.preheatingProfile;
    console.log($scope.preheatingProfile);
  },true);    

  $scope.$watch(function(){ return MyWebsocket.temp; }, function(){
    $scope.temp = MyWebsocket.temp;
  },true); 
  
});