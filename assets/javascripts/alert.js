(function() {
  
  setTimeout(function(){

      if($('li.current-user').length > 0 && $('li.current-user').html().indexOf('pdx') != -1) { loggedIn = true; } else { loggedIn = false;  }
      
      if(loggedIn){
        addStockToUsersFavoriteStocks();
        displayUsersFavoriteStocks();
      }

  }, 500);

    setInterval(function(){
      
      if(loggedIn){
        displayUsersFavoriteStocks();
      }

  }, 5000);


  function displayUsersFavoriteStocks() {

        Discourse.ajax("/stock/get_users_favorite_stocks", {
          type: "GET",
        }).then(function(data) {
          
          //data = JSON.parse(data);
          //console.log('users fav stocks: ');
          //console.log(data.stock);

          //console.log(data[0].length);

          template = '';

          for (var i = data.stock.length - 1; i >= 0; i--) {
            
            console.log(data.stock[i]);
            stock = jQuery.parseJSON(data.stock[i]);
            console.log('stock:' + stock);
            console.log('symbol:' + stock.symbol);
            nameForUrl = stock.symbol.substring(0, stock.symbol.indexOf('.'));
            console.log(stock.last_trade_price_only);  


            last_trade_price_only = stock.last_trade_price_only.toString().replace(".",",");

            percent_change = stock.percent_change.toString();
            percent_change = percent_change.replace("%","");
            percent_change = percent_change.replace(".",",");
            
            change_direction = 'neutral';
            console.log(percent_change);
            if(percent_change.indexOf("-") != -1){ change_direction = 'negative'; }
            if(percent_change.indexOf("+") != -1){ change_direction = 'positive'; }

            if($('#stock_data').length > 0) { // stock data has been loaded, update existing stock numbers
              console.log('updating data to: ' + last_trade_price_only + ', ' + percent_change);
              //$('#stock_data a[data-symbol="' + nameForUrl + '"] .stock_last').numberAnimate('set', last_trade_price_only);
              //$('#stock_data a[data-symbol="' + nameForUrl + '"] .stock_change_percent').numberAnimate('set', percent_change);

            }

            if($('#stock_data').length == 0) { // stock data has not already been loaded
              template = template + '<a data-symbol="' + nameForUrl + '" href="/tags/' + nameForUrl.toLowerCase() + '"><div class="change_icon  ' + change_direction + '"><div></div></div><span class="stock_symbol">' + nameForUrl + '</span><div class="stock_extra"><span class="stock_last number-animate">' + last_trade_price_only + '</span><span class="stock_change_percent number-animate' + change_direction + '">' + percent_change + '%</span></div></a>';
            }

          };

          if($('#stock_data').length == 0) { // stock data has not already been loaded

            stock_html = '<div id="stock_data"><div class="container"><div id="stock_data_inner">' + template + '</div></div></div>';

            $('body').append(stock_html);
            $('.number-animate').numberAnimate('init');
          }

        });

  }

  function addStockToUsersFavoriteStocks() {
    
        Discourse.ajax("/stock/add_stock_to_users_favorite_stocks?ticker=funcom.ol", {
        type: "GET",
      });
    }
  

})();
