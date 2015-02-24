touchApp.filter('startFrom', function() {
  return function(arr, start) {
    return arr.slice(start);
  };
});