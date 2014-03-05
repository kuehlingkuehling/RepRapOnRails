touchApp.controller('QueueController', function($scope, MyWebsocket, CommonCode){
  console.log("Running QueueController");  

  MyWebsocket.menuDisabled = false;  
  
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
     
});