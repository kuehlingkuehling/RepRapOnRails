touchApp.factory('CommonCode', function() {
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
  
  CommonCode.formatSeconds = function (seconds) {
    var mm = Math.floor(seconds / 60) % 60,
        ss = Math.floor(seconds) % 60;
    return mm + ":" + (ss < 10 ? "0" : "") + ss
  };
  
  CommonCode.getById = function(input, id) {
    var i=0, len=input.length;
    for (; i<len; i++) {
      if (+input[i].id == +id) {
        return input[i];
      }
    }
    return null;
  }
  
  return CommonCode; 
});