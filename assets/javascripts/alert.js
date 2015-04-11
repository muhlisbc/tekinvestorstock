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
          
          data = JSON.parse(data);
          console.log('users fav stocks: ');
          console.log(data.stock);

          //console.log(data[0].length);

          for (var i = data.stock.length - 1; i >= 0; i--) {
            
            console.log(data.stock[i].symbol);
          };

          form_html = "<a href=''>Rediger din portefølje</a><div id='my_stock'><span class='label'>Antall aksjer:</span> <input id='num_stocks' type='text' placeholder='1000' /><span class='label'>Snittpris:</span> <input id='average_price' type='text' placeholder='5,3' /> </div> ";

          stock_html = 
          '<div id="stock_data"><div class="container"><span id="stock_data_inner"><span class="stock_last"><span class="label">Kurs:</span> <strong>' + 0 + '</strong></span> <span class="stock_change_percent">(<strong>' + 0 + '</strong>%)</span> <span class="stock_my_total_value"><span class="label">Min aksjeverdi:</span> <strong>' + 0 + '</strong></span> <span class="value_change_today"><span class="label">I dag:</span> <span class="sign">+</span><strong>' + 0 + '</strong></span></span> <span class="value_change"><span><span class="label">Gevinst/tap:</span></span> <span class="sign">+</span><strong>' + 0 + '</strong></span> <span class="value_change_percent">(<span class="sign">+</span><strong>' + 0 + '</strong>%)</span>' + form_html + '</div></div>' ;

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
