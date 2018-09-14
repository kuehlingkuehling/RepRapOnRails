backendApp.controller('LogController', function($scope, Printer, CommonCode){
  console.log("Running LogController");  

  $scope.printer = Printer;
});