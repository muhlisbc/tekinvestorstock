
  setTimeout(function(){

      if($('li.current-user').length > 0 && $('li.current-user').html().indexOf('pdx') != -1) { loggedIn = true; } else { loggedIn = false;  }
      if($('#home-page').length > 0) { homePage = true; } else { homePage = false; }
      
      if(loggedIn && homePage){
        displayUsersFavoriteStocks(false);
        console.log('refreshing stocks');
      }
      
      // run check every X ms to see if page has changed, if page has changed and new page is home page, refresh stock list
      oldTopicsCount=$('.topic-list tr').length;
      $(function() {
          setInterval(function() {
              if($('.topic-list tr').length!=oldTopicsCount) {
                   displayUsersFavoriteStocks(true);
                   console.log('page changed, updating stocks');
                  
                  // add notice in fav stocks box if not signed in       
                  if(!loggedIn && homePage) {
                    $('#user-favorite-stocks .spinner').hide();
                   // $('#user-favorite-stocks').append('<p class="user-favorite-stocks__not_logged_in"><a href="#" onClick="openSignupModal()" class="link_open_signup">Registrer deg</a> eller <a href="#" onClick="openLoginModal()" class="link_open_login">logg inn</a> for å følge aksjekursene på dine favorittaksjer.</p>');      
                  }
                   
                   oldTopicsCount=$('.topic-list tr').length;
              } 
          },500);
      });

  }, 500);

    setInterval(function(){
      
      if(loggedIn && homePage){
        displayUsersFavoriteStocks(false);
        console.log('refreshing stocks, interval');
      }

  }, 60000);


  function displayUsersFavoriteStocks(forceRefresh) {
        console.log('displayUsersFavoriteStocks');
        console.log('forceRefresh:' + forceRefresh);
        Discourse.ajax("/stock/get_users_favorite_stocks", {
          type: "GET",
        }).then(function(data) {
          
          //data = JSON.parse(data);
          //console.log('users fav stocks: ');
          //console.log(data.stock);

          //console.log(data[0].length);

          template = '';
          console.log(data.stock);
          for (var i = data.stock.length - 1; i >= 0; i--) {
            
            //console.log('stock #' + i);
            
            //console.log(data.stock[i]);
            stock = jQuery.parseJSON(data.stock[i]);
            //console.log('stock:' + stock);
            console.log('symbol:' + stock.symbol);
            nameForUrl = stock.symbol;//.substring(0, stock.symbol.indexOf('.'));
            //console.log(stock.last_trade_price_only);  

            if(stock.last_trade_price_only != null) {

              last_trade_price_only = stock.last_trade_price_only.toString().replace(".",",");

              percent_change = stock.percent_change.toString();
              percent_change = percent_change.replace("%","");
              percent_change = percent_change.replace(".",",");
              
              change_direction = 'neutral';
              //console.log(percent_change);
              if(percent_change.indexOf("-") != -1){ change_direction = 'negative'; }
              if(percent_change.indexOf("+") != -1){ change_direction = 'positive'; }

              if($('#stock_data').length > 0 && forceRefresh == false) { // stock data has been loaded, update existing stock numbers
                // update data
                console.log('updating ' + nameForUrl + ' data to: ' + last_trade_price_only + ', ' + percent_change + ' ' + nameForUrl + ', ' + last_trade_price_only);
                //console.log($('#stock_data a[data-symbol="' + nameForUrl + '"] .stock_last'));
                $('#stock_data tr[data-symbol="' + nameForUrl + '"] .stock_last').numberAnimate('set', last_trade_price_only);
                $('#stock_data tr[data-symbol="' + nameForUrl + '"] .stock_change_percent .number-animate').numberAnimate('set', percent_change);
                // set up or down
                $('#stock_data tr[data-symbol="' + nameForUrl + '"] .change_icon, #stock_data tr[data-symbol="' + nameForUrl + '"] .stock_change_percent').removeClass('positive').removeClass('negative').addClass(change_direction);

              }

              if($('#stock_data').length == 0 || forceRefresh) { // stock data has not already been loaded
                template = template + '<tr data-symbol="' + nameForUrl + '"><td class="td-ticker"><a href="/tags/' + nameForUrl.toLowerCase() + '"><span class="stock_symbol">' + nameForUrl + '</span></a></td><td class="td-last"><span class="stock_last number-animate">' + last_trade_price_only + '</span></td><td class="td-change"><span class="stock_change_percent ' + change_direction + '"><span class="number-animate">' + percent_change + '</span>%</span></td></tr>';
              }
            }

          };

          if($('#stock_data').length == 0 || forceRefresh) { // stock data has not already been loaded
            
            if(forceRefresh) {
              $('#stock_data').remove();
              //console.log('removing stock data');
            }

            stock_html = '<div id="stock_data"><div class="container"><table id="stock_data_inner"><thead><th class="th-symbol">Ticker</th><th class="th-last">Siste</th><th class="th-change">I dag</th></thead><tbody>' + template + '</tbody></table></div></div>';
            //console.log(stock_html);
            $('#user-favorite-stocks .spinner').hide();
            $('#user-favorite-stocks').append(stock_html);              
            $('.number-animate').numberAnimate('init');
          }

        });

  }

  function addStockToUsersFavoriteStocks(ticker) {
    
        Discourse.ajax("/stock/add_stock_to_users_favorite_stocks?ticker=" + ticker, {
        type: "GET"
        }).then(function(data) {
          displayUsersFavoriteStocks(true); // force refresh
      });
    }

  function removeStockFromUsersFavoriteStocks(ticker) {
    
        Discourse.ajax("/stock/remove_stock_from_users_favorite_stocks?ticker=" + ticker, {
        type: "GET"
        }).then(function(data) {
          displayUsersFavoriteStocks(true); // force refresh
      });
    }

    function isStockUsersFavorite(ticker) {
        Discourse.ajax("/stock/get_users_favorite_stocks", {
          type: "GET",
        }).then(function(data) {
            //console.log(data.stock);
          //data = data.toString;

          for (var i = data.stock.length - 1; i >= 0; i--) {
            stock = jQuery.parseJSON(data.stock[i]);

            if(ticker.toLowerCase() == stock.symbol.toLowerCase()) { console.log(ticker + ' is a favorite stock: ' + stock.symbol.toLowerCase()); return true; }
          }
          console.log(ticker + ' is not a favorite stock');
          return false;

      });
    }
    
    function openSignupModal() {
      $('.btn.sign-up-btn').trigger("click");
    }
  
    function openLoginModal() {
      $('.btn.login-btn').trigger("click");
    }
