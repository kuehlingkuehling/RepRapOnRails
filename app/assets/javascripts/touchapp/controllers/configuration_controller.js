touchApp.controller('ConfigurationController', function($scope, $location, CommonCode, Printer){
  console.log("Running ConfigurationController");  

  $scope.printer = Printer;
    
  $scope.setLeft = function(id) {
    Printer.setFilaments({
      left: id,
      right: (Printer.filamentsLoaded.right ? Printer.filamentsLoaded.right.id : null)
    });
    $scope.selectLeft = false;
  };
  
  $scope.setRight = function(id) {
    Printer.setFilaments({
      left: (Printer.filamentsLoaded.left ? Printer.filamentsLoaded.left.id : null),
      right: id
    });  
    $scope.selectRight = false;
  }; 

  $scope.setChamberBed = function(id) {
    Printer.setPreheatingProfile(id);  
    $scope.selectChamberBed = false;
  };   
  
  $scope.exit = function() {
    $location.path( "/setup" );
  };    
});