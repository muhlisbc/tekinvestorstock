(function() {

  setInterval(function(){
    
    $('.user-title:contains("Mesteren")').addClass('mesteren');

  }, 3000);
  
  // start
  setTimeout(function(){

    stockTimer();

    num_stocks_now = $('#num_stocks').val();
    average_price_now = $('#average_price').val();

  }, 2000);
  

// check if num_stocks/avg price has changed every 5 secs, if so, update
  setInterval(function(){
      
    if(num_stocks_now != $('#num_stocks').val() || average_price_now != $('#average_price').val()) {

      stockTimer();
      //$('#stock_data_inner').animate({opacity: 1}, 400);
      //console.log('updating');

      num_stocks_now = $('#num_stocks').val();
      average_price_now = $('#average_price').val();
  
    }

  }, 2005);

  // rerun every minute
  setInterval(function(){
    stockTimer();
  }, 60000);




  function stockTimer(){

    //alert($('.ember-view.title').text());
    //$('.ember-view.title').text(@last_price);

//alert();  
  //var flickerAPI = "/stock/stock_data";
  /*$.getJSON( flickerAPI, {
  //  tags: "mount rainier",
    //tagmode: "any",
    format: "json"
  })
    .done(function( data ) {
      //$.each( data.items, function( i, item ) {
        
        alert(data);
        
      })
    .fail(function( jqxhr, textStatus, error ) {
      var err = textStatus + ", " + error;
      console.log( "Request Failed: " + err );
    });
    */
    

/*    Discourse.ajax("/stock/set_user_stock", {
      type: "GET",
      data: {value: 1236}
    }).then(function(user_data) {
      
      //alert(user_data);

    }.bind(this));
  */  

//  if(!$('div.not-logged-in-avatar').length) {    // if not logged in

if(!$('div.not-logged-in-avatar').length > 0) { loggedIn = true; } else { loggedIn = false;  }

    Discourse.ajax("/stock/stock_data", {
      type: "GET",
      //data: {post_id: this.get('post.id'), option: option}
    }).then(function(stock_data) {
      
      stock = jQuery.parseJSON(stock_data.stock[0]);
      
      //value_change_today = value_change_today * stock_my_total_value

      //console.log(value_change);
      //console.log(stock);
      

      if($('#stock_data').length == 0) { // stock data has not already been loaded

        form_html = "<a href=''>Rediger din portefølje</a><div id='my_stock'><span class='label'>Antall aksjer:</span> <input id='num_stocks' type='text' placeholder='1000' /><span class='label'>Snittpris:</span> <input id='average_price' type='text' placeholder='5,3' /> </div> ";

        stock_html = 
        '<div id="stock_data"><div class="container"><span id="stock_data_inner"><span class="stock_last"><span class="label">Kurs:</span> <strong>' + 0 + '</strong></span> <span class="stock_change_percent">(<strong>' + 0 + '</strong>%)</span> <span class="stock_my_total_value"><span class="label">Min aksjeverdi:</span> <strong>' + 0 + '</strong></span> <span class="value_change_today"><span class="label">I dag:</span> <span class="sign">+</span><strong>' + 0 + '</strong></span></span> <span class="value_change"><span><span class="label">Gevinst/tap:</span></span> <span class="sign">+</span><strong>' + 0 + '</strong></span> <span class="value_change_percent">(<span class="sign">+</span><strong>' + 0 + '</strong>%)</span>' + form_html + '</div></div>' ;

        $('body').append(stock_html);
        getUserStock(); // put # of stocks in input field
        getUserAveragePrice(); // put avg price in input field

        setTimeout(function(){
          getValues();

          $('.stock_last strong').numberAnimate('init');
          $('.stock_change_percent strong').numberAnimate('init');
          $('.stock_my_total_value strong').numberAnimate('init');
          $('.value_change strong').numberAnimate('init');
          $('.value_change_percent strong').numberAnimate('init');
          $('.value_change_today strong').numberAnimate('init');


          $('#num_stocks').on('input', function() {

              new_val = parseInt($(this).val());
              if (new_val == "" || new_val == null) { new_val = 0; $(this).val(0); }
              
              //$('#stock_data_inner').animate({opacity: 0.3}, 400);

              Discourse.ajax("/stock/set_user_stock", {
                type: "GET",
                data: {value: new_val}
              }).then(function(user_data) {
              
              });
              //stockTimer(); // refresh calcs
          });


          $('#average_price').on('input', function() {

              new_val = $(this).val();
              if (new_val == "" || new_val == null) { new_val = 0; $(this).val(0); }
              
              new_val = new_val.replace(",",'.');
              
              //$('#stock_data_inner').animate({opacity: 0.3}, 400);

              Discourse.ajax("/stock/set_user_average_price", {
                type: "GET",
                data: {value: new_val}
              }).then(function(user_data) {

              });
              //stockTimer(); // refresh calcs
          });

          $('#stock_data a').on('click', function() {
          
            if(loggedIn){
            
              if( $('#stock_data a').text() != 'Lagre') {
  
                $('#stock_data a').text('Lagre');            
                $('#my_stock').animate({opacity: 1}, 200);
                //$('#my_stock input:first-child').focus();
                  
              } else { 
  
                $('#stock_data a').text('Rediger din portefølje');
                $('#my_stock').animate({opacity: 0}, 0);
  
              }
            
            } else { $('.btn-primary').trigger('click'); }

            return false;
            
            
          });



        },500);
      }


      setTimeout(function(){
        getUserStock(); // put # of stocks in input field
        getUserAveragePrice(); // put avg price in input field
        getValues();
        last_trade_price_only = stock.last_trade_price_only.toString().replace(".",",");
        //last_trade_price_only = stock.ask.toString().replace(".",",");
        //console.log(stock);
        $('.stock_last strong').numberAnimate('set', last_trade_price_only);
        
        percent_change = stock.percent_change.toString();
        percent_change = percent_change.replace("%","");
        percent_change = percent_change.replace(".",",");

//        console.log('animating');
        $('.stock_change_percent strong').numberAnimate('set', percent_change);
        
        if(loggedIn){
          
        if(stock_my_total_value != undefined) { $('.stock_my_total_value strong').numberAnimate('set', stock_my_total_value); }
        if(value_change != undefined) { $('.value_change strong').numberAnimate('set', value_change.toFixed(0)); }
        if(!isNaN(value_change_percent)) { $('.value_change_percent strong').numberAnimate('set', value_change_percent.toFixed(1)); }

        
        //stock.percent_change = '-90%';
        
        // if negative:

        //percent_change = '-19.5%';
        if(percent_change.indexOf("-")){
          
          value_yesterday = stock_my_total_value * 100;
          value_yesterday = value_yesterday / (100 - (stock.percent_change.replace("%","").replace("+","")) * -1);
          console.log(value_yesterday);
          console.log('diff:' + (stock_my_total_value - value_yesterday));

          var value_change_today = stock_my_total_value - value_yesterday;
          console.log(value_change_today);

        } else {
          
          value_yesterday = stock_my_total_value * 100;
          value_yesterday = value_yesterday / (100 - (stock.percent_change.replace("%","").replace("+","")) * -1);
          console.log(value_yesterday);
          console.log('diff:' + (stock_my_total_value - value_yesterday));

          var value_change_today = stock_my_total_value - value_yesterday;
          console.log(value_change_today);
      }
        

        $('.value_change_today strong').numberAnimate('set', value_change_today.toFixed(0));

}
        if(percent_change.indexOf("+") >= 0) {
            $('.stock_change_percent').removeClass('red').addClass('green');
        } else {
            $('.stock_change_percent').removeClass('green').addClass('red');
        }

if(loggedIn){
  
        if(value_change > 0) {
            $('.value_change .sign').html('+').addClass('green');
            $('.value_change strong').removeClass('red').addClass('green');
            $('.value_change_percent .sign').html('+').addClass('green');
            $('.value_change_percent').removeClass('red').addClass('green');
        }
        if(value_change < 0) {
            $('.value_change .sign').html('');
            $('.value_change strong').removeClass('green').addClass('red');
            $('.value_change_percent .sign').html('');
            $('.value_change_percent').removeClass('green').addClass('red');
        }


        if(value_change_today > 0) {
            $('.value_change_today .sign').html('+').removeClass('red').addClass('green');
            $('.value_change_today strong').removeClass('red').addClass('green');
            
        }
        if(value_change_today < 0) {
            $('.value_change_today .sign').html('');
            $('.value_change_today strong').removeClass('green').addClass('red');
            
        }
        
      }
      },600);

    }.bind(this));
  
    

  }

//}

function getValues(){
  if(loggedIn){
    numberShares = parseInt($('#num_stocks').val());
    averagePrice = $('#average_price').val();

    //console.log(numberShares);

    //averagePrice = 5.76;
    //stock.last_trade_price_only = Math.random() * 10;
    //console.log(stock.last_trade_price_only);

    stock_my_total_value = parseInt(numberShares * stock.last_trade_price_only);
    //console.log(stock_my_total_value);
    purchase_value = numberShares * averagePrice;
    value_change = parseInt(stock_my_total_value - purchase_value);

    value_change_percent = ((stock_my_total_value/purchase_value) * 100) - 100;


}

}
function getUserStock() { 
    if(loggedIn){
    // update user stock count on load
    Discourse.ajax("/stock/user_stock", {
      type: "GET",
      data: {}
    }).then(function(user_data) {
      
      num_stocks = 0;
      if (parseInt(user_data) > 0) { num_stocks = user_data; }
      $('#num_stocks').val(num_stocks);

      console.log(num_stocks);
      
    }.bind(this));
}
 }

 function getUserAveragePrice() { 
  
  if(loggedIn){
  
    var average_price = 0;
    
    // update user stock count on load
    Discourse.ajax("/stock/user_average_price", {
      type: "GET",
      data: {}
    }).then(function(user_data) {
      
      average_price = 0;
      if (parseInt(user_data) > 0) { average_price = user_data; }
      $('#average_price').val(average_price); 
      console.log(average_price);

    }.bind(this));
  }
 }

function addThousandsSeparator(input) {
    var output = input
    if (parseFloat(input)) {
      if (input > 999) {
        input = new String(input); // so you can perform string operations
        var parts = input.split("."); // remove the decimal part
        parts[0] = parts[0].split("").reverse().join("").replace(/(\d{3})(?!$)/g, "$1,").split("").reverse().join("");
        output = parts.join(".");
      } else { output = input; }
    }

    return output;
}


  /*Discourse.AlertButton = Discourse.ButtonView.extend({
    text: 'alert',
    title: 'display the topic title in an alert',

    click: function() {
      alert(this.get("controller.content.title"));
    },

    renderIcon: function(buffer) {
      buffer.push("<i class='icon icon-warning-sign'></i>");
    }
  });

  Discourse.TopicFooterButtonsView.reopen({
    addAlertButton: function() {
      this.attachViewClass(Discourse.AlertButton);
    }.on("additionalButtons")
  });
*/
})();
