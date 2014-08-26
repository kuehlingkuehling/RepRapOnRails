touchApp.controller('FooterController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running FooterController");
 
  $scope.temp = MyWebsocket.temp;    
});