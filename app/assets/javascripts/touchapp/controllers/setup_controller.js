touchApp.controller('SetupController', function($scope, Printer,$interval){
  console.log("Running SetupController");  

  Printer.menuDisabled = false;
  
  $scope.backendurl = ' ';
  Printer.get('hostname').then(function(data){
    $scope.backendurl = 'http://' + data + '/';
  });   

  $scope.firmware_version_installed = 'n/a';
  $scope.firmware_version_compatible = 'n/a';
  $scope.model = 'n/a';
  $scope.hardware_revision = 'n/a';
  $scope.software_version = 'n/a';
  $scope.ip_address = 'n/a';
  Printer.get('versions').then(function(data){
    $scope.firmware_version_installed = data.firmware_version_installed;
    $scope.firmware_version_compatible = data.firmware_version_compatible;
    $scope.model = data.model;
    $scope.hardware_revision = data.hardware_revision;
    $scope.software_version = data.software_version;
    $scope.ip_address = data.ip_address;
  });   

  // some wizards are only available on dual extruder setups  
  $scope.$watch(function(){ return Printer.isDualExtruder; }, function(){
    $scope.isDualExtruder = Printer.isDualExtruder;
  },true); 

  $scope.idle = false;
  $scope.paused = false;
  
  // some wizards are only available in specific print states
  $scope.$watch(function(){ return Printer.print; }, function(newValue){
    if (Printer.print.state == 1) {
      $scope.idle = true;
    } else {
      $scope.idle = false;      
    };
    
    if (Printer.print.state == 3) {
      $scope.paused = true;
    } else {
      $scope.paused = false;
    };
  }, true);   

  // show system clock in Footer
  $scope.clock = Date.now();$interval(function () { $scope.clock = Date.now(); }, 1000);
  
});