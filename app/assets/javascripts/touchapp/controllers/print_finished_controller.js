touchApp.controller('PrintFinishedController', function($scope, $location, $routeParams, MyWebsocket){
  console.log("Running PrintFinishedController");
  
  $scope.elapsed = MyWebsocket.print.elapsed_in_words;
  $scope.printjobId = $routeParams.printjobId
  
  $scope.delete = function() {
    MyWebsocket.removePrintjob($scope.printjobId);
    $location.path( "/queue" );
  };
  
});
