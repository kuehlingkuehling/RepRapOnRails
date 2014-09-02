touchApp.controller('PrintFinishedController', function($scope, $location, $routeParams, MyWebsocket, CommonCode){
  console.log("Running PrintFinishedController");
  
  $scope.$watch(function(){ return MyWebsocket.print; }, function(){
    $scope.elapsed = MyWebsocket.print.elapsed_in_words;
  },true);   
  $scope.printjobId = $routeParams.printjobId;
  $scope.$watch(function(){ return MyWebsocket.printjobs; }, function(){
    $scope.printjob_name = CommonCode.getById(MyWebsocket.printjobs, $scope.printjobId).name;
  },true);    


  $scope.delete = function() {
console.log("removing printjob ID " + $scope.printjobId);
    MyWebsocket.removePrintjob($scope.printjobId);
    $location.path( "/queue" );
  };
  
});
