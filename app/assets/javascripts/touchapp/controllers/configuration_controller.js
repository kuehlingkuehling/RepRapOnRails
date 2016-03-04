touchApp.controller('ConfigurationController', function($scope, $location, CommonCode, MyWebsocket){
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

  $scope.$watch(function(){ return MyWebsocket.filamentPresets; }, function(){
    $scope.filamentPresets = MyWebsocket.filamentPresets;
  },true); 
  
  $scope.$watch(function(){ return MyWebsocket.filamentsLoaded; }, function(){
    $scope.filaments = MyWebsocket.filamentsLoaded;
  },true);

  $scope.$watch(function(){ return MyWebsocket.preheatingProfiles; }, function(){
    $scope.preheatingProfiles = MyWebsocket.preheatingProfiles;
  },true); 
  
  $scope.$watch(function(){ return MyWebsocket.preheatingProfile; }, function(){
    $scope.preheatingProfile = MyWebsocket.preheatingProfile;
  },true);   

  $scope.$watch(function(){ return MyWebsocket.isDualExtruder; }, function(){
    $scope.isDualExtruder = MyWebsocket.isDualExtruder;
  },true);     

    
  $scope.setLeft = function(id) {
    MyWebsocket.setFilaments({
      left: id,
      right: ($scope.filaments.right ? $scope.filaments.right.id : null)
    });
    $scope.selectLeft = false;
  };
  
  $scope.setRight = function(id) {
    MyWebsocket.setFilaments({
      left: ($scope.filaments.left ? $scope.filaments.left.id : null),
      right: id
    });  
    $scope.selectRight = false;
  }; 

  $scope.setChamberBed = function(id) {
    MyWebsocket.setPreheatingProfile(id);  
    $scope.selectChamberBed = false;
  };   
  
  $scope.exit = function() {
    $location.path( "/setup" );
  };    
});