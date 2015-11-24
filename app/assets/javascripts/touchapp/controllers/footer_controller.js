touchApp.controller('FooterController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running FooterController");
 
  $scope.$watch(function(){ return MyWebsocket.filamentsLoaded; }, function(){
    $scope.filaments = MyWebsocket.filamentsLoaded;
  },true);  

  $scope.$watch(function(){ return MyWebsocket.isDualExtruder; }, function(){
    $scope.isDualExtruder = MyWebsocket.isDualExtruder;
  },true);  

  $scope.$watch(function(){ return MyWebsocket.preheatingProfile; }, function(){
    $scope.preheatingProfile = MyWebsocket.preheatingProfile;
  },true);    

  $scope.$watch(function(){ return MyWebsocket.temp; }, function(){
    $scope.temp = MyWebsocket.temp;
  },true); 
  
});