backendApp.controller('FirststepsController', function($scope, MyWebsocket, CommonCode){
  console.log("Running FirststepsController");  

  $scope.model = 'n/a';
  MyWebsocket.get('versions').then(function(data){
    $scope.model = data.model;
  });   
});