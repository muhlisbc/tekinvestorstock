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
        
          #tickers = ["aapl", "aga.ol", "akso.ol", "amd", "apcl.ol", "asetek.ol", "avm.ol", "axa.ol", "bionor.ol", "biotec.ol", "bird.ol", "bitcoin-xbt.st", "btcusd=x", "dno.ol", "fro.ol", "funcom.ol", "gig.ol", "hugo.ol", "idex.ol", "iox.ol", "kit.ol", "nano.ol", "nas.ol", "natto.ol", "natto.st", "nel.ol", "next.ol", "nod.ol", "nom.ol", "nor.ol", "ocy.ol", "opera.ol", "ork.ol", "pho.ol", "seam.st", "sf.st", "star-a.st", "star-b.st", "tel.ol", "thin.ol", "til.ol"]

          #stocks = StockQuote::Stock.quote(tickers) #old unreliable method, but ok for historical data

          tickers = tickers.join(",")
          #source = 'http://finance.yahoo.com/webservice/v1/symbols/' + tickers + '/quote?format=json&view=detail' #old way
          
          source = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20csv%20where%20url%3D'http%3A%2F%2Fdownload.finance.yahoo.com%2Fd%2Fquotes.csv%3Fs%3D" + tickers + "%26f%3Dsl1d1t1c1p2ohgvt1d1%26e%3D.csv'%20and%20columns%3D'symbol%2Cprice%2Cdate%2Ctime%2Cchange%2Cchg_percent%2Ccol1%2Chigh%2Clow%2Ccol2%2Clast_trade_time%2Clast_trade_date'&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
          
          puts source
          
          resp = Net::HTTP.get_response(URI.parse(source))
          data = resp.body
          result = JSON.parse(data)

          puts result

          #stocks = result["list"]["resources"] #old way
          stocks = result["query"]["results"]["row"]

          puts "processing.."
          puts stocks.size
          puts "stocks"

  	      for index in 0 ... stocks.size

      		  puts "-- Processing: #{index}"

            symbol = result["query"]["results"]["row"][index]["symbol"].downcase

            #symbol = result["list"]["resources"][index]["resource"]["fields"]["symbol"].downcase # old way

            unless symbol.nil? || symbol == ""

              symbol = symbol.downcase
              
              price = result["query"]["results"]["row"][index]["price"]
              #last_updated = result["query"]["results"]["row"][index]["utctime"]
              change_percent = result["query"]["results"]["row"][index]["chg_percent"]

              puts "#{symbol} / #{price} / #{change_percent}"

      		  	::PluginStore.set("stock_price", symbol, price)
              ::PluginStore.set("stock_change_percent", symbol, change_percent)
           		#::PluginStore.set("stock_last_updated", symbol, last_updated)
              
            end 

            #puts "#{stocks[index].to_json}"

  		    end

  		    puts "Done!"

        end

  	end

  end
end
