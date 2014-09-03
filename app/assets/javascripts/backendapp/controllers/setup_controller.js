backendApp.controller('SetupController', function($scope, MyWebsocket, CommonCode, $timeout, $upload){
  console.log("Running SetupController");  

  $scope.presets = [];
  $scope.newPreset = {name:'',extrusion_temp:''};
  $scope.isCollapsed = true;  
  $scope.edit = {};

  $scope.preheatingProfiles = [];
  $scope.newPreheatingProfile = {name:'',chamber_temp:'',bed_temp:''};
  $scope.isCollapsedPreheating = true;  
  $scope.editPreheating = {};

  $scope.eeprom = null;
  MyWebsocket.reloadEEPROM();
  $scope.$watch(function(){ return MyWebsocket.eeprom; }, function(newValue){
    $scope.eeprom = MyWebsocket.eeprom;  
  }, true); 
  $scope.edit_eeprom = {};

  // firmware upload form
  $scope.uploadProgress = 0;
  $scope.file = false;  
  $scope.error = '';

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
    if (confirm("Do you really want to remove this Profile?")) {
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
  
  $scope.onFileSelect = function($files) {
    //$files: an array of files selected, each file has name, size, and type.
    $scope.file = $files[0];
  };  
  
  $scope.uploadPrintjob = function() {
    $scope.upload = $upload.upload({
      url: 'firmware', //upload.php script, node.js route, or servlet url
      method: 'POST', //or PUT,
      headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
      // withCredential: true,
      //data: {},
      file: $scope.file,
      fileFormDataName: 'hexfile'
    }).progress(function (evt) {
        // get upload percentage
        console.log("uploaded percent: " + parseInt(100.0 * evt.loaded / evt.total));
        $scope.uploadProgress = parseInt(100.0 * evt.loaded / evt.total); 
    }).success(function (data, status, headers, config) {
        // file is uploaded successfully      
        console.log("Succesfully uploaded.");
        $timeout(function(){
          $scope.uploadProgress = 0;
          $scope.file = false;        
          $scope.fileInput = '';                   
        }, 2000);
    }).error(function (data, status, headers, config) {
        // file failed to upload
        console.log(data);
        $scope.uploadProgress = 0;        
        $scope.error = "Error: Failed to upload data."
    });
  };   

  // Preheating Profiles
  $scope.$watch(function(){ return MyWebsocket.preheatingProfiles; }, function(){
    $scope.preheatingProfiles = MyWebsocket.preheatingProfiles;
  },true);  

  $scope.toggleFormPreheating = function() {
    $scope.resetFormPreheating();    
    $scope.isCollapsedPreheating = !$scope.isCollapsedPreheating;
  };
  
  $scope.resetFormPreheating = function() {
    $scope.newPreheatingProfile.name = '';
    $scope.newPreheatingProfile.chamber_temp = '';
    $scope.newPreheatingProfile.bed_temp = '';
  };
  
  $scope.deletePreheatingProfile = function(id) {
    if (confirm("Do you really want to remove this Profile?")) {
      MyWebsocket.deletePreheatingProfile(id);
    }
  };

  $scope.createPreheatingProfile = function() {
    MyWebsocket.createPreheatingProfile($scope.newPreheatingProfile);
    $scope.toggleFormPreheating();
  };
  
  $scope.editPreheatingProfile = function(id){
    $scope.editPreheating[id] = true;
  };
  
  $scope.updatePreheatingProfile = function(index){
    MyWebsocket.updatePreheatingProfile($scope.preheatingProfiles[index]);
    $scope.editPreheating[$scope.preheatingProfiles[index].id] = false;    
  };


  $scope.reloadEEPROM = function(){
    MyWebsocket.reloadEEPROM();
  };

  $scope.editEEPROM = function(pos){
    $scope.edit_eeprom[pos] = true;
  };

  $scope.updateEEPROM = function(pos){
    MyWebsocket.setEEPROM(pos, $scope.eeprom[pos].type, $scope.eeprom[pos].val);
    
    if ( $scope.eeprom[pos].type != 3) {
      $scope.eeprom[pos].val = Math.floor($scope.eeprom[pos].val);
    };
    $scope.edit_eeprom[pos] = false;    
  };

});