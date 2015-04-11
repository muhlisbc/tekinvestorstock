(function() {
  
  setTimeout(function(){

      if($('li.current-user').length > 0) { loggedIn = true; } else { loggedIn = false;  }

      getUsersFavoriteStocks();
      addStockToUsersFavoriteStocks();
  
  }, 2000);

  function getUsersFavoriteStocks() {
    if(loggedIn){
      Discourse.ajax("/stock/get_users_favorite_stocks", {
        type: "GET",
      }).then(function(data) {
        console.log('users fav stocks: ');
        console.log(data);
      });
    }
  } 

  function addStockToUsersFavoriteStocks() {
    if(loggedIn){
        Discourse.ajax("/stock/add_stock_to_users_favorite_stocks?ticker=funcom.ol", {
        type: "GET",
      });
    }
  } 

})();
