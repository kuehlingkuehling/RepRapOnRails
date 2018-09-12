touchApp.controller('WizardCalibrateExtrusionController', function($scope, CommonCode, $location, $timeout, Printer){
  console.log("Running WizardCalibrateExtrusionController");  

  Printer.menuDisabled = true;
  
  $scope.measurement = 0.5;
  $scope.extrusion_width = 0.5;

  $scope.$watch(function(){ return Printer.isDualExtruder; }, function(){
    $scope.isDualExtruder = Printer.isDualExtruder;
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
    Printer.calibrateExtrusionPrintjob(ext);
    Printer.menuDisabled = false;    
    $location.path( "/queue" );    
  };
  
  $scope.exit = function() {
    Printer.menuDisabled = false;
    $location.path( "/setup" );
  };   

});