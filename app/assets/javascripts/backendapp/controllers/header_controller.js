backendApp.controller('HeaderController', function($scope, $modal, $location, $timeout, Printer){
  console.log("Running HeaderController");
  
  $scope.printer = Printer;
  
  $scope.tab = $location.path();  
  $scope.go = function( tab ){
    $location.path( tab );
    $scope.tab = $location.path();
  };

});