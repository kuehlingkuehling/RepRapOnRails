touchApp.controller('SetupController', function($scope, MyWebsocket){
  console.log("Running SetupController");  

  MyWebsocket.menuDisabled = false;
  
  $scope.backendurl = ' ';
  MyWebsocket.get('hostname').then(function(data){
    $scope.backendurl = 'http://' + data + '/';
  });   

  $scope.firmware_version_installed = 'n/a';
  $scope.firmware_version_compatible = 'n/a';
  $scope.hardware_revision = 'n/a';
  $scope.software_version = 'n/a';
  MyWebsocket.get('versions').then(function(data){
    $scope.firmware_version_installed = data.firmware_version_installed;
    $scope.firmware_version_compatible = data.firmware_version_compatible;
    $scope.hardware_revision = data.hardware_revision;
    $scope.software_version = data.software_version;
  });   

  // some wizards are only available on dual extruder setups  
  $scope.$watch(function(){ return MyWebsocket.isDualExtruder; }, function(){
    $scope.isDualExtruder = MyWebsocket.isDualExtruder;
  },true); 

  $scope.idle = false;
  $scope.paused = false;
  
  // some wizards are only available in specific print states
  $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    if (MyWebsocket.print.state == 1) {
      $scope.idle = true;
    } else {
      $scope.idle = false;      
    };
    
    if (MyWebsocket.print.state == 3) {
      $scope.paused = true;
    } else {
      $scope.paused = false;
    };
  }, true);   
  
});