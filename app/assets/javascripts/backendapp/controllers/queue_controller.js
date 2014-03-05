backendApp.controller('QueueController', function($scope, MyWebsocket, CommonCode, $upload){
  console.log("Running QueueController");  

  $scope.printjobs = [];
  $scope.newPrintjob = {name:'',note:''};
  $scope.uploadProgress = 0;
  $scope.isCollapsed = true;  
  $scope.file = false;  
  $scope.error = 'No Error';
  $scope.edit = {};

  $scope.$watch(function(){ return MyWebsocket.printjobs; }, function(){
    $scope.printjobs = MyWebsocket.printjobs;
  },true);  
  
  $scope.$watch(function(){ return MyWebsocket.print; }, function(newValue){
    $scope.now_printing_id = MyWebsocket.print.job_id;
  }, true);   
  
  $scope.onFileSelect = function($files) {
    //$files: an array of files selected, each file has name, size, and type.
    $scope.file = $files[0];
  };  
  
  $scope.uploadPrintjob = function() {
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
        $scope.error = "Error: Failed to upload data."
    });
  };  
  
  $scope.toggleForm = function() {
    $scope.resetForm();    
    $scope.isCollapsed = !$scope.isCollapsed;
  };
  
  $scope.resetForm = function() {
    $scope.file = false;
    $scope.fileInput = '';      
    $scope.newPrintjob.name = '';
    $scope.newPrintjob.note = '';
    $scope.uploadProgress = 0;                 
    $scope.error = '';        
  };
  
  $scope.removePrintjob = function(id) {
    if (confirm("Do you really want to remove this Printjob?")) {
      MyWebsocket.removePrintjob(id)      
    }
  };
  
  $scope.editPrintjob = function(id){
    $scope.edit[id] = true;
  };
  
  $scope.updatePrintjob = function(index){
    MyWebsocket.updatePrintjob($scope.printjobs[index]);
    $scope.edit[$scope.printjobs[index].id] = false;    
  };  
  
});