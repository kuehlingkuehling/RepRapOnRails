touchApp.controller('WizardLevelingController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running WizardLevelingController");  

  MyWebsocket.menuDisabled = true;
  $scope.step = 1;
  $scope.deviation = 3; // +/- °C around target
  $scope.bed_temp = 0;
  $scope.bed_preheated = false;

  $scope.$watch(function(){ return MyWebsocket.preheatingProfile; }, function(){
    $scope.bed_target = MyWebsocket.preheatingProfile.bed_temp;
  },true);
  
  $scope.$watch(function(){ return MyWebsocket.temp; }, function(newValue){
    $scope.temp = MyWebsocket.temp;
    if (MyWebsocket.temp.bed) {
      $scope.bed_temp = MyWebsocket.temp.bed.temp;
      if (($scope.bed_temp > ($scope.bed_target - $scope.deviation)) && ($scope.bed_temp < ($scope.bed_target + $scope.deviation))) {
        $scope.bed_preheated = true;
        if ($scope.step == 2) {
          $scope.step = 3;
        }
      } else {
        $scope.bed_preheated = false;      
      };
    };
  }, true); 
  
  // initial commands
  MyWebsocket.macro('psu_on');
  MyWebsocket.macro('wizard_leveling_init');
  
  $scope.step1 = function() {
    $scope.step = 1;    
  };
  
  $scope.step2 = function() {
    $scope.step = 2;
    MyWebsocket.preheat(0, $scope.bed_target);
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