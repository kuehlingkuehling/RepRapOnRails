touchApp.controller('LogController', function($scope, Printer, CommonCode){
  console.log("Running LogController");
  
  $scope.gcode = '';
  $scope.lastcommand = '';  
  
  // init pagination
  //$scope.itemsPerPage = 13;
  //$scope.currentPage = 1;
  //$scope.pagedLog = [];

  // process list to pages  
  $scope.$watch(function(){ return Printer.log; }, function(newValue){
    $scope.log_length = Printer.log.length;      
    $scope.log = Printer.log;
    //$scope.pagedLog = CommonCode.groupToPages(Printer.log, $scope.itemsPerPage);
  }, true);

  $scope.send = function(){
    Printer.sendgcode($scope.gcode);
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
