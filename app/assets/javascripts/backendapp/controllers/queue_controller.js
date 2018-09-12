backendApp.controller('QueueController', function($scope, Printer, CommonCode, $upload){
  console.log("Running QueueController");  

  $scope.printjobs = [];
  $scope.newPrintjob = {name:'',note:''};
  $scope.uploadProgress = 0;
  $scope.isCollapsed = true;  
  $scope.file = false;  
  $scope.error = 'No Error';
  $scope.edit = {};

  $scope.$watch(function(){ return Printer.printjobs; }, function(){
    $scope.printjobs = Printer.printjobs;
  },true);  
  
  $scope.$watch(function(){ return Printer.print; }, function(newValue){
    $scope.now_printing_id = Printer.print.job_id;
  }, true);   
  
  $scope.onFileSelect = function($files) {
    //$files: an array of files selected, each file has name, size, and type.
    $scope.file = $files[0];
  };  
  
  $scope.submitted_but_invalid = false;
  $scope.uploadPrintjob = function() {
    if ($scope.addPrintjobForm.name.$invalid || $scope.addPrintjobForm.file.$invalid) {
      $scope.submitted_but_invalid = true;
      console.log("Form invalid!");
    } else {
      $scope.upload = $upload.upload({
        url: 'upload', //upload.php script, node.js route, or servlet url
        method: 'POST', //or PUT,
        headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
        // withCredential: true,
        data: {
          name: $scope.newPrintjob.name,
          note: $scope.newPrintjob.note     
        },
        file: $scope.file,
        fileFormDataName: 'gcodefile'
      }).progress(function (evt) {
          // get upload percentage
          console.log("uploaded percent: " + parseInt(100.0 * evt.loaded / evt.total));
          $scope.uploadProgress = parseInt(100.0 * evt.loaded / evt.total); 
      }).success(function (data, status, headers, config) {
          // file is uploaded successfully      
          console.log("Succesfully uploaded.");
          $scope.toggleForm(); 
      }).error(function (data, status, headers, config) {
          // file failed to upload
          console.log(data);
          $scope.uploadProgress = 0;        
          $scope.error = "Error: " + data.join(', ');
      });
    };
  };  
  
  $scope.toggleForm = function() {
    $scope.isCollapsed = !$scope.isCollapsed;
    $scope.resetForm();    
  };
  
  $scope.resetForm = function() {
    $scope.file = false;
    $scope.fileInput = '';  
    document.getElementById('file').value = null;    
    $scope.newPrintjob.name = '';
    $scope.newPrintjob.note = '';
    $scope.uploadProgress = 0;                 
    $scope.error = '';
    $scope.submitted_but_invalid = false;       
  };
  
  $scope.removePrintjob = function(id) {
    if (confirm("Do you really want to remove this Printjob?")) {
      Printer.removePrintjob(id)      
    }
  };
  
  $scope.editPrintjob = function(id){
    $scope.edit[id] = true;
  };
  
  $scope.updatePrintjob = function(index){
    Printer.updatePrintjob($scope.printjobs[index]);
    $scope.edit[$scope.printjobs[index].id] = false;    
  };  
  
});