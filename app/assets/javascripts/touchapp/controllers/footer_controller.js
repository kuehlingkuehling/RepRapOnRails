touchApp.controller('FooterController', function($scope, $location, $timeout, Printer, $interval){
  console.log("Running FooterController");
 
  $scope.printer = Printer;

});