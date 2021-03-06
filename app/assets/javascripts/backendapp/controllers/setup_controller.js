backendApp.controller('SetupController', function($scope, Printer, CommonCode, $timeout, $upload){
  console.log("Running SetupController");  

  $scope.presets = [];
  $scope.newPreset = {name:'',extrusion_temp:''};
  $scope.isCollapsed = true;  
  $scope.edit = {};

  $scope.preheatingProfiles = [];
  $scope.newPreheatingProfile = {name:'',chamber_temp:'',bed_temp:''};
  $scope.isCollapsedPreheating = true;  
  $scope.editPreheating = {};

  $scope.printer = Printer;
  Printer.reloadEEPROM();

  $scope.edit_eeprom = {};

  $scope.hostname = ' ';
  Printer.get('hostname').then(function(data){
    $scope.hostname = data;
  });   

  $scope.firmware_version_installed = 'n/a';
  $scope.firmware_version_compatible = 'n/a';
  $scope.model = 'n/a';
  $scope.hardware_revision = 'n/a';
  $scope.software_version = 'n/a';
  Printer.get('versions').then(function(data){
    $scope.firmware_version_installed = data.firmware_version_installed;
    $scope.firmware_version_compatible = data.firmware_version_compatible;
    $scope.model = data.model;
    $scope.hardware_revision = data.hardware_revision;
    $scope.software_version = data.software_version;
  });  

  // firmware upload form
  $scope.uploadProgress = 0;
  $scope.file = false;  
  $scope.error = '';
  
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
      Printer.deletePreset(id);      
    }
  };

  $scope.createPreset = function() {
    Printer.createPreset($scope.newPreset);
    $scope.toggleForm();
  };
  
  $scope.editPreset = function(id){
    $scope.edit[id] = true;
  };
  
  $scope.updatePreset = function(index){
    Printer.updatePreset(Printer.filamentPresets[index]);
    $scope.edit[Printer.filamentPresets[index].id] = false;    
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
      Printer.deletePreheatingProfile(id);
    }
  };

  $scope.createPreheatingProfile = function() {
    Printer.createPreheatingProfile($scope.newPreheatingProfile);
    $scope.toggleFormPreheating();
  };
  
  $scope.editPreheatingProfile = function(id){
    $scope.editPreheating[id] = true;
  };
  
  $scope.updatePreheatingProfile = function(index){
    Printer.updatePreheatingProfile(Printer.preheatingProfiles[index]);
    $scope.editPreheating[Printer.preheatingProfiles[index].id] = false;    
  };


  $scope.reloadEEPROM = function(){
    Printer.reloadEEPROM();
  };

  $scope.editEEPROM = function(pos){
    $scope.edit_eeprom[pos] = true;
  };

  $scope.updateEEPROM = function(pos){
    Printer.setEEPROM(pos, Printer.eeprom[pos].type, Printer.eeprom[pos].val);
    
    if ( Printer.eeprom[pos].type != 3) {
      Printer.eeprom[pos].val = Math.floor(Printer.eeprom[pos].val);
    };
    $scope.edit_eeprom[pos] = false;    
  };

});