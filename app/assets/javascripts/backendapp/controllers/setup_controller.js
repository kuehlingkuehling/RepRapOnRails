backendApp.controller('SetupController', function($scope, MyWebsocket, CommonCode){
  console.log("Running SetupController");  

  $scope.presets = [];
  $scope.newPreset = {name:'',extrusion_temp:''};
  $scope.isCollapsed = true;  
  $scope.edit = {};

  $scope.$watch(function(){ return MyWebsocket.filamentPresets; }, function(){
    $scope.presets = MyWebsocket.filamentPresets;
  },true);  
  
  $scope.toggleForm = function() {
    $scope.resetForm();    
    $scope.isCollapsed = !$scope.isCollapsed;
  };
  
  $scope.resetForm = function() {
    $scope.newPreset.name = '';
    $scope.newPreset.extrusion_temp = '';
  };
  
  $scope.deletePreset = function(id) {
    if (confirm("Do you really want to remove this Preset?")) {
      MyWebsocket.deletePreset(id);      
    }
  };

  $scope.createPreset = function() {
    MyWebsocket.createPreset($scope.newPreset);
    $scope.toggleForm();
  };
  
  $scope.editPreset = function(id){
    $scope.edit[id] = true;
  };
  
  $scope.updatePreset = function(index){
    MyWebsocket.updatePreset($scope.presets[index]);
    $scope.edit[$scope.presets[index].id] = false;    
  };     

});