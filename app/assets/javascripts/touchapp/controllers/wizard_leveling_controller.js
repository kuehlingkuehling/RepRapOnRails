touchApp.controller('WizardLevelingController', function($scope, $location, $timeout, MyWebsocket){
  console.log("Running WizardLevelingController");  

  MyWebsocket.menuDisabled = true;
  $scope.step = 1;
  $scope.deviation = 3; // +/- °C around target
  $scope.bed_temp = 0;
  $scope.bed_preheated = false;

  $scope.$watch(function(){ return MyWebsocket.preheatingProfile; }, function(){
    $scope.bed_target = MyWebsocket.preheatingProfile.bed_temp;
    if (typeof $scope.bed_target === 'undefined') {
      $scope.noPreheatingProfileSelected = true;
    } else {
      $scope.noPreheatingProfileSelected = false;
    }
  },true);

  $scope.temps_to_restore = {};
  
  $scope.$watch(function(){ return MyWebsocket.temp; }, function(newValue){
    // copy temp object only once as soon as it is not empty
    if (Object.keys($scope.temps_to_restore).length == 0) {
      $scope.temps_to_restore = angular.copy(MyWebsocket.temp);
    };
    $scope.temp = MyWebsocket.temp;
    if (MyWebsocket.temp.bed) {
      $scope.bed_temp = MyWebsocket.temp.bed.temp;
      if ((($scope.bed_temp > ($scope.bed_target - $scope.deviation)) && ($scope.bed_temp < ($scope.bed_target + $scope.deviation))) || ($scope.bed_target == 0)) {
        $scope.bed_preheated = true;
        if ($scope.step == 2) {
          $scope.step = 21;
        }
      } else {
        $scope.bed_preheated = false;      
      };
    };
  }, true); 
  
  // initial commands
  MyWebsocket.psu_on();
  MyWebsocket.macro('wizard_leveling_init');

  $scope.move_up = function() {
    MyWebsocket.macro('wizard_leveling_moveup');
  };
  
  $scope.step1 = function() {
    $scope.step = 1;    
  };
  
  $scope.step2 = function() {
    $scope.step = 2;
    if ($scope.noPreheatingProfileSelected == false) {
      MyWebsocket.preheat(-1, $scope.bed_target);
    }

  };

  $scope.step21 = function() {
    $scope.step = 21;
  };
  
  
  $scope.step3 = function() {
    $scope.step = 3;  
    switch ($scope.extruder) {
      case 'left_extruder':
        $scope.primary_extruder_name = "left";
        $scope.secondary_extruder_name = "right";
        MyWebsocket.macro('select_left_extruder');
        break;
      case 'right_extruder':
        $scope.primary_extruder_name = "right";
        $scope.secondary_extruder_name = "left";     
        MyWebsocket.macro('select_right_extruder');
        break;
    };       
  };
  
  $scope.step5 = function() {
    $scope.step = 5;    
    MyWebsocket.macro('wizard_leveling_front');    
  };
  
  $scope.step6 = function() {
    $scope.step = 6;
    MyWebsocket.macro('wizard_leveling_right');    
  };
  
  $scope.step7 = function() {
    $scope.step = 7;  
    MyWebsocket.macro('wizard_leveling_left');     

    // in case of returning from step9
    switch ($scope.extruder) {
      case 'left_extruder':
        MyWebsocket.macro('select_left_extruder');
        break;
      case 'right_extruder':
        MyWebsocket.macro('select_right_extruder');
        break;
    };     
  };  

  $scope.step9 = function() {
    $scope.step = 9;  
    MyWebsocket.macro('select_left_extruder');
    MyWebsocket.macro('wizard_leveling_center');        
  };      
  
  $scope.exit = function() {
    MyWebsocket.macro('wizard_leveling_exit');
    // restore chamber/bed settings as they were before starting wizard
    if ($scope.noPreheatingProfileSelected == false) {
      MyWebsocket.preheat($scope.temps_to_restore.chamber.target, $scope.temps_to_restore.bed.target);
    }
    MyWebsocket.menuDisabled = false;
    $location.path( "/setup" );
  };        
});