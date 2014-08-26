touchApp.controller('WizardLevelingController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running WizardLevelingController");  

  MyWebsocket.menuDisabled = true;
  $scope.step = 1;
  $scope.bed_temp = 0;
  $scope.bed_target = 100;
  $scope.bed_preheated = false;
  
  $scope.$watch(function(){ return MyWebsocket.temp; }, function(newValue){
    if (MyWebsocket.temp.list[3]) {
      $scope.bed_temp = MyWebsocket.temp.list[3].temp;
      if ($scope.bed_temp > (0.95 * $scope.bed_target)) {
        $scope.bed_preheated = true;
      } else {
        $scope.bed_preheated = false;      
      };
    };
  }, true); 
  
  // initial commands
  MyWebsocket.macro('psu_on');
  MyWebsocket.macro('get_temp');
  MyWebsocket.macro('wizard_leveling_init');
  
  $scope.step1 = function() {
    $scope.step = 1;    
  };
  
  $scope.step2 = function() {
    $scope.step = 2;
    MyWebsocket.macro('wizard_leveling_preheat');
  };
  
  $scope.step3 = function() {
    $scope.step = 3;    
  };
  
  
  $scope.step4 = function() {
    $scope.step = 4;    
  };  
  
  $scope.step5 = function() {
    $scope.step = 5;    
  };
  
  $scope.step6 = function() {
    $scope.step = 6;
    MyWebsocket.macro('wizard_leveling_front');    
  };
  
  $scope.step7 = function() {
    $scope.step = 7;  
    MyWebsocket.macro('wizard_leveling_right');        
  };  
  
  $scope.step8 = function() {
    $scope.step = 8;  
    MyWebsocket.macro('wizard_leveling_left');        
  };    

  $scope.step9 = function() {
    $scope.step = 9;  
    MyWebsocket.macro('wizard_leveling_center');        
  };      
  
  $scope.exit = function() {
    MyWebsocket.macro('wizard_leveling_exit');
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };        
});