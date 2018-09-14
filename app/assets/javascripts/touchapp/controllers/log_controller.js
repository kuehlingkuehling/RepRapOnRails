touchApp.controller('LogController', function($scope, Printer, CommonCode){
  console.log("Running LogController");
  
  $scope.gcode = '';
  $scope.lastcommand = '';  

  $scope.printer = Printer;

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
