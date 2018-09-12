touchApp.controller('ConfigurationController', function($scope, $location, CommonCode, Printer){
  console.log("Running ConfigurationController");  

  // init pagination
  $scope.itemsPerPage = 3;
  $scope.currentPageLeft = 1;
  $scope.currentPageRight = 1;  
  $scope.filamentPresets = [];
  $scope.preheatingProfiles = [];
  $scope.numFilaments = 0;
  $scope.numProfiles = 0;  
  $scope.filaments = false;
  $scope.preheatingProfile = false;

  $scope.$watch(function(){ return Printer.filamentPresets; }, function(){
    $scope.filamentPresets = Printer.filamentPresets;
  },true); 
  
  $scope.$watch(function(){ return Printer.filamentsLoaded; }, function(){
    $scope.filaments = Printer.filamentsLoaded;
  },true);

  $scope.$watch(function(){ return Printer.preheatingProfiles; }, function(){
    $scope.preheatingProfiles = Printer.preheatingProfiles;
  },true); 
  
  $scope.$watch(function(){ return Printer.preheatingProfile; }, function(){
    $scope.preheatingProfile = Printer.preheatingProfile;
  },true);   

  $scope.$watch(function(){ return Printer.isDualExtruder; }, function(){
    $scope.isDualExtruder = Printer.isDualExtruder;
  },true);     

    
  $scope.setLeft = function(id) {
    Printer.setFilaments({
      left: id,
      right: ($scope.filaments.right ? $scope.filaments.right.id : null)
    });
    $scope.selectLeft = false;
  };
  
  $scope.setRight = function(id) {
    Printer.setFilaments({
      left: ($scope.filaments.left ? $scope.filaments.left.id : null),
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