touchApp.controller('FooterController', function($scope, $location, $timeout, Printer, $interval){
  console.log("Running FooterController");
 
  $scope.$watch(function(){ return Printer.filamentsLoaded; }, function(){
    $scope.filaments = Printer.filamentsLoaded;
  },true);  

  $scope.$watch(function(){ return Printer.isDualExtruder; }, function(){
    $scope.isDualExtruder = Printer.isDualExtruder;
  },true);  

  $scope.$watch(function(){ return Printer.preheatingProfile; }, function(){
    $scope.preheatingProfile = Printer.preheatingProfile;
  },true);    

  $scope.$watch(function(){ return Printer.temp; }, function(){
    $scope.temp = Printer.temp;
  },true); 


});