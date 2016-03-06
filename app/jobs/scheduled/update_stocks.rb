module Jobs
  class UpdateStocks < Jobs::Scheduled

  	include Sidekiq::Worker

    every 5.minutes

    def execute(args)
      
    	  # find all stocks in tekindex
          
        @tickers = ["FUNCOM.OL", "STAR-A.ST", "STAR-B.ST", "GIG.OL", "BTCUSD=X", "NEL.OL", "THIN.OL", "OPERA.OL", "AGA.OL", "KIT.OL", "BIOTEC.OL", "NAS.OL", "NOM.OL", "BIRD.OL", "NEXT.OL"]

        # find all favorited stocks
     	  puts "Finding all favorite stocks"

        User.find_each do |user|
	  	
  		  	puts "finding favorites for user id: #{user.id}"
  		  	
  		  	unless user.custom_fields["favorite_stocks"].nil? || user.custom_fields["favorite_stocks"].empty?
  		  		
    		  	users_favorite_stocks = user.custom_fields["favorite_stocks"].split(',')
    				puts users_favorite_stocks

    				# add to array
    				@tickers.concat users_favorite_stocks

    			end
  		  	
  		  end

        # remove duplicates
        @tickers = @tickers.uniq

        # sort alphabetically

        @tickers = @tickers.sort_by { |ticker| ticker.downcase }
        @tickers.map!(&:downcase)

        set_stock_data(@tickers)  

    end

  	def set_stock_data (tickers)

  		# handles multiple stocks in one request
        if !tickers.nil? 

          tickers = tickers.uniq
		      puts "Fetching stock data for #{tickers.size} stocks: #{tickers}"
        
          #tickers = ["FUNCOM.OL", "STAR-A.ST"]
          #stocks = StockQuote::Stock.quote(tickers) #old unreliable method, but ok for historical data

          tickers = tickers.join(",")
          source = 'http://finance.yahoo.com/webservice/v1/symbols/' + tickers + '/quote?format=json&view=detail'
          resp = Net::HTTP.get_response(URI.parse(source))
          data = resp.body
          result = JSON.parse(data)

          stocks = result["list"]["resources"]

          puts "processing.."
          puts stocks.size
          puts "stocks"

  	      for index in 0 ... stocks.size

      		  puts "-- Processing: #{index}"

            symbol = result["list"]["resources"][index]["resource"]["fields"]["symbol"].downcase

            unless symbol.nil? || symbol == ""

              symbol = symbol.downcase
              
              price = result["list"]["resources"][index]["resource"]["fields"]["price"]
              last_updated = result["list"]["resources"][index]["resource"]["fields"]["utctime"]
              change_percent = result["list"]["resources"][index]["resource"]["fields"]["chg_percent"]

              puts "#{symbol} / #{price} / #{change_percent} / #{last_updated}"

      		  	::PluginStore.set("stock_price", symbol, price)
              ::PluginStore.set("stock_change_percent", symbol, change_percent)
           		::PluginStore.set("stock_last_updated", symbol, last_updated)
              
            end 

            #puts "#{stocks[index].to_json}"

  		    end

  		    puts "Done!"

        end

  	end

  end
end
