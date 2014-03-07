touchApp.controller('PrintFinishedController', function($scope, $location, $routeParams, MyWebsocket){
  console.log("Running PrintFinishedController");
  
  $scope.$watch(function(){ return MyWebsocket.print; }, function(){
    $scope.elapsed = MyWebsocket.print.elapsed_in_words;
  },true);   
  $scope.printjobId = $routeParams.printjobId;
  
  $scope.delete = function() {
console.log("removing printjob ID " + $scope.printjobId);
    MyWebsocket.removePrintjob($scope.printjobId);
    $location.path( "/queue" );
  };
  
});
