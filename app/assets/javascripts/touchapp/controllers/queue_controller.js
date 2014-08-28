touchApp.controller('QueueController', function($scope, $modal, MyWebsocket, CommonCode){
  console.log("Running QueueController");  

  MyWebsocket.menuDisabled = false; 

 $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    if (( MyWebsocket.print.state == 2) || ( MyWebsocket.print.state == 5 )) {
      $scope.printing = true;
    } else {
      $scope.printing = false;      
    }    
  }, true);    
  
  // init pagination
  $scope.itemsPerPage = 3;
  $scope.currentPage = 1;
  $scope.pagedPrintjobs = [];
  $scope.numPrintjobs = 0;
  
  $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    if (MyWebsocket.print.state == 1) {
      $scope.idle = true;
    } else {
      $scope.idle = false;      
    }    
  }, true);   
  

  $scope.$watch(function(){ return MyWebsocket.printjobs; }, function(){
    // process list to pages
    $scope.numPrintjobs = MyWebsocket.printjobs.length;    
    $scope.pagedPrintjobs = CommonCode.groupToPages(MyWebsocket.printjobs, $scope.itemsPerPage);
  },true);  


  $scope.macro = function( name ){
    MyWebsocket.macro(name);    
  };   
  
  $scope.psu_off = function(state){
    // open cooldown dialog
    var cooldownModal = $modal.open({
      templateUrl: '<%= asset_path("touchapp/templates/dialog_cooldown.html") %>', // statically included in backendapp.html.erb
      controller: 'DialogCooldownController',
      backdrop: 'static'
    });       
  };
     
});