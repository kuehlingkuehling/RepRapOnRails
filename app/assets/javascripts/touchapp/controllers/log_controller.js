touchApp.controller('LogController', function($scope, MyWebsocket, CommonCode){
  console.log("Running LogController");
  
  $scope.gcode = '';
  $scope.lastcommand = '';  
  
  // init pagination
  //$scope.itemsPerPage = 13;
  //$scope.currentPage = 1;
  //$scope.pagedLog = [];

  // process list to pages  
  $scope.$watch(function(){ return MyWebsocket.log; }, function(newValue){
    $scope.log_length = MyWebsocket.log.length;      
    $scope.log = MyWebsocket.log;
    //$scope.pagedLog = CommonCode.groupToPages(MyWebsocket.log, $scope.itemsPerPage);
  }, true);

  $scope.send = function(){
    MyWebsocket.sendgcode($scope.gcode);
    $scope.lastcommand = $scope.gcode;     
    $scope.gcode = '';
  }; 
  
  $scope.last = function(){
    $scope.gcode = $scope.lastcommand;
  };
  
  $scope.add = function(key){
    console.log("adding key: " + key);
    $scope.gcode = $scope.gcode + key;
  };
  
  $scope.backspace = function(){
    $scope.gcode = $scope.gcode.substring(0, $scope.gcode.length - 1);
  };  
});
