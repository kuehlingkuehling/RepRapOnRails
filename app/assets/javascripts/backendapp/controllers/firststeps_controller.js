backendApp.controller('FirststepsController', function($scope, Printer, CommonCode){
  console.log("Running FirststepsController");  

  $scope.model = 'n/a';
  Printer.get('versions').then(function(data){
    $scope.model = data.model;
  });   
});