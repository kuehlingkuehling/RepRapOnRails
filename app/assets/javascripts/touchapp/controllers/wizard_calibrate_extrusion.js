touchApp.controller('WizardCalibrateExtrusionController', function($scope, CommonCode, $location, $timeout, MyWebsocket){
  console.log("Running WizardCalibrateExtrusionController");  

  MyWebsocket.menuDisabled = true;
  
  $scope.measurement = 0.5;
  $scope.extrusion_width = 0.5;

  $scope.$watch(function(){ return MyWebsocket.isDualExtruder; }, function(){
    $scope.isDualExtruder = MyWebsocket.isDualExtruder;
  },true);

  $scope.calculate = function() {
    $scope.multiplier = ( $scope.extrusion_width / parseFloat($scope.measurement) ).toFixed(2);
  };      
  
  $scope.calculate();
  
  $scope.add = function(i) {
    $scope.measurement = (parseFloat($scope.measurement) + i).toFixed(2);
    $scope.calculate();
  };
  
  $scope.del = function(j) {
    $scope.measurement = (parseFloat($scope.measurement) - j).toFixed(2);
    $scope.calculate();    
  };
  
  $scope.generate_printjob = function(ext) {
    // ext: 'left' or 'right'
    MyWebsocket.calibrateExtrusionPrintjob(ext);
    MyWebsocket.menuDisabled = false;    
    $location.path( "/queue" );    
  };
  
  $scope.exit = function() {
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };   

});