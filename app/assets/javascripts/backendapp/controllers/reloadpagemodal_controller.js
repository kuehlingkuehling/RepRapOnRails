backendApp.controller('ReloadPageModalController', function($scope, $modalInstance){
  console.log("Running ReloadPageModalController");
   
  $scope.reloadpage = function(){
    location.reload();
  };
 
});