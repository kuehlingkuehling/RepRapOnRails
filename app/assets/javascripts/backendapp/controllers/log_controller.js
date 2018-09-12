backendApp.controller('LogController', function($scope, Printer, CommonCode){
  console.log("Running LogController");  

  // watch log for changes  
  $scope.$watch(function(){ return Printer.log; }, function(newValue){
    $scope.log = Printer.log;      
  }, true);   

});