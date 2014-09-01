touchApp.controller('ConfigurationController', function($scope, $location, CommonCode, MyWebsocket){
  console.log("Running ConfigurationController");  

  // init pagination
  $scope.itemsPerPage = 3;
  $scope.currentPageLeft = 1;
  $scope.currentPageRight = 1;  
  $scope.pagedFilaments = [];
  $scope.pagedPreheatingProfiles = [];
  $scope.numFilaments = 0;
  $scope.numProfiles = 0;  
  $scope.filaments = false;
  $scope.preheatingProfile = false;

  $scope.$watch(function(){ return MyWebsocket.filamentPresets; }, function(){
    // process list to pages
    $scope.numFilaments = MyWebsocket.filamentPresets.length;    
    $scope.pagedFilaments = CommonCode.groupToPages(MyWebsocket.filamentPresets, $scope.itemsPerPage);
  },true); 
  
  $scope.$watch(function(){ return MyWebsocket.filamentsLoaded; }, function(){
    $scope.filaments = MyWebsocket.filamentsLoaded;
  },true);

  $scope.$watch(function(){ return MyWebsocket.preheatingProfiles; }, function(){
    // process list to pages
    $scope.numProfiles = MyWebsocket.preheatingProfiles.length;    
    $scope.pagedPreheatingProfiles = CommonCode.groupToPages(MyWebsocket.preheatingProfiles, $scope.itemsPerPage);
  },true); 
  
  $scope.$watch(function(){ return MyWebsocket.preheatingProfile; }, function(){
    $scope.preheatingProfile = MyWebsocket.preheatingProfile;
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