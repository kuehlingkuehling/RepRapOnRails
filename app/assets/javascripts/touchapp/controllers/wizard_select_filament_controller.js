touchApp.controller('WizardSelectFilamentController', function($scope, $location, CommonCode, MyWebsocket){
  console.log("Running WizardSelectFilamentController");  

  // init pagination
  $scope.itemsPerPage = 2;
  $scope.currentPageLeft = 1;
  $scope.currentPageRight = 1;  
  $scope.pagedFilaments = [];
  $scope.numFilaments = 0;
  $scope.filaments = false;

  $scope.$watch(function(){ return MyWebsocket.filamentPresets; }, function(){
    // process list to pages
    $scope.numFilaments = MyWebsocket.filamentPresets.length;    
    $scope.pagedFilaments = CommonCode.groupToPages(MyWebsocket.filamentPresets, $scope.itemsPerPage);
  },true); 
  
  $scope.$watch(function(){ return MyWebsocket.filamentsLoaded; }, function(){
    $scope.filaments = MyWebsocket.filamentsLoaded;
  },true);   
  
  $scope.setLeft = function(id) {
    MyWebsocket.setFilaments({
      left: id,
      right: ($scope.filaments.right ? $scope.filaments.right.id : null)
    });
  };
  
  $scope.setRight = function(id) {
    MyWebsocket.setFilaments({
      left: ($scope.filaments.left ? $scope.filaments.left.id : null),
      right: id
    });    
  }; 
  
  $scope.exit = function() {
    $location.path( "/setup" );
  };    
});