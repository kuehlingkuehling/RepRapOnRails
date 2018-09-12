backendApp.controller('HeaderController', function($scope, $modal, $location, $timeout, Printer){
  console.log("Running HeaderController");
  
  $scope.$watch(function(){ return Printer.print; }, function(newValue){
    $scope.print = Printer.print;  
  }, true);  
  
  $scope.tab = $location.path();  
  $scope.go = function( tab ){
    $location.path( tab );
    $scope.tab = $location.path();
  };
  
  $scope.progress = 0;
  $scope.time_remaining = '';
  $scope.$watch(function(){ return Printer.progress; }, function(newValue){
    $scope.progress = Printer.progress;  
    $scope.time_remaining = Printer.time_remaining;  
  }, true); 

});