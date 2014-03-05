backendApp.factory('CommonCode', function() {
  var CommonCode = {};  
  
  CommonCode.groupToPages = function (items, itemsPerPage) {
      pagedItems = [];
      
      for (var i = 0; i < items.length; i++) {
          items[i].pos = i + 1;
          if (i % itemsPerPage === 0) {
              pagedItems[Math.floor(i / itemsPerPage)] = [ items[i] ];
          } else {
              pagedItems[Math.floor(i / itemsPerPage)].push(items[i]);
          }
      }
      
      return pagedItems;
  };
  
  return CommonCode; 
});