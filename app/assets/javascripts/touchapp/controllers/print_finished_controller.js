touchApp.controller('PrintFinishedController', function($scope, $location, $routeParams, Printer, CommonCode){
  console.log("Running PrintFinishedController");
  
  $scope.$watch(function(){ return Printer.print; }, function(){
    $scope.elapsed = Printer.print.elapsed_in_words;
  },true);   
  $scope.printjobId = $routeParams.printjobId;
  $scope.$watch(function(){ return Printer.printjobs; }, function(){
    $scope.printjob_name = CommonCode.getById(Printer.printjobs, $scope.printjobId).name;
  },true);    


  $scope.delete = function() {
console.log("removing printjob ID " + $scope.printjobId);
    Printer.removePrintjob($scope.printjobId);
    $location.path( "/queue" );
  };
  
});
