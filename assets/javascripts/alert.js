(function() {
  
  setTimeout(function(){

      if($('li.current-user').length > 0) { loggedIn = true; } else { loggedIn = false;  }
      
      if(loggedIn){
        addStockToUsersFavoriteStocks();
        displayUsersFavoriteStocks();
      }

  }, 2000);


  function displayUsersFavoriteStocks() {

     if($('#stock_data').length == 0) { // stock data has not already been loaded

        Discourse.ajax("/stock/get_users_favorite_stocks", {
          type: "GET",
        }).then(function(data) {
          
          //data = JSON.parse(data);
          console.log('users fav stocks: ');
          console.log(data.stock);

          //console.log(data[0].length);

          template = '';

          for (var i = data.stock.length - 1; i >= 0; i--) {
            
            console.log(data.stock[i]);
            stock = jQuery.parseJSON(data.stock[i]);
            console.log('symbol:' + stock.symbol);
            
            percent_change = stock.percent_change.toString();
            percent_change = percent_change.replace("%","");
            percent_change = percent_change.replace(".",",");
            
            change_direction = 'neutral';
            if(percent_change.indexOf("-")){ change_direction = 'negative'; } 
            if(percent_change.indexOf("+")){ change_direction = 'positive'; }

            template = template + '<a href="/tags/' + stock.symbol + '"><span class="stock_last">' + stock.last_trade_price_only + '</span> <span class="stock_change_percent ' + change_direction + '">' + percent_change + '%</span></a>';

          };

          stock_html = 
          '<div id="stock_data"><div class="container"><div id="stock_data_inner">' + template + '</div></div></div>';

          $('body').append(stock_html);

        });

      }

  }

  function addStockToUsersFavoriteStocks() {
    
        Discourse.ajax("/stock/add_stock_to_users_favorite_stocks?ticker=funcom.ol", {
        type: "GET",
      });
    }
  

})();
