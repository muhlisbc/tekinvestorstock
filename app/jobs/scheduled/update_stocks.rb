module Jobs
  class UpdateStocks < Jobs::Scheduled

  	include Sidekiq::Worker

    every 5.minutes

    def execute(args)
      
    	  # find all stocks in tekindex
          
        @tickers = ["FUNCOM.OL", "STAR-A.ST", "STAR-B.ST", "GIG.OL", "BTCUSD=X", "NEL.OL", "THIN.OL", "OPERA.OL", "AGA.OL", "KIT.OL", "BIOTEC.OL", "NAS.OL", "NOM.OL", "BIRD.OL", "NEXT.OL"]
        #todo remove above, not used anymore since .ol stocks are filtered out

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

        import_ose_stocks()
        set_stock_data(@tickers)  

    end

    def import_ose_stocks ()

      # this is the way we get all Oslo stocks, direct from netfonds 15 min delayed
      # get stocks from all on one page at http://www.netfonds.no/quotes/kurs.php?exchange=OSE&sec_types=&ticks=&table=tab&sort=alphabetic

      def read(url)
       CSV.new(open(url), :headers => :first_row, col_sep: "\t").each do |line|

         symbol = line[1].downcase + ".ol"
         last = line[2].to_f
         change = line[5].to_f
         last_close = line[9].to_f
         
         percent_change = (((last - last_close)/last_close)*100).round(2).to_s + "%"
         
         if last == 0 # if no trades in stock today, last will be 0 and therefore change should be 0 also
          percent_change = 0
          last = last_close # also do this so we have a price to show
        end

         puts symbol + " last: " + last.to_s + " change: " + change.to_s + " yesterday: " + last_close.to_s + " change %: "  + percent_change.to_s
         ::PluginStore.set("stock_price", symbol, last.to_s)
         ::PluginStore.set("stock_change_percent", symbol, percent_change.to_s)
         #::PluginStore.set("stock_last_updated", symbol, last_updated) #todo: add
        
       end
      end

      read("http://www.netfonds.no/quotes/kurs.php?exchange=OSE&sec_types=&ticks=&table=tab&sort=alphabetic")

      #puts "#{symbol} / #{price} / #{change_percent}"

      puts "Done!"

    end

  	def set_stock_data (tickers)

  		# handles multiple stocks in one request
        if !tickers.nil? 

          tickers = tickers.uniq
          to_be_processed = []

          # don't processs OL stocks here anymore, that has a separate Job
          tickers.each do |stock|

            if !stock.include? ".ol"
                if !stock.include? ".OL"
                  to_be_processed.push(stock)
                end
            end
            
          end

          tickers = to_be_processed

		      puts "Fetching stock data for #{tickers.size} stocks: #{tickers}"
        
          #tickers = ["aapl", "aga.ol", "akso.ol", "amd", "apcl.ol", "asetek.ol", "avm.ol", "axa.ol", "bionor.ol", "biotec.ol", "bird.ol", "bitcoin-xbt.st", "btcusd=x", "dno.ol", "fro.ol", "funcom.ol", "gig.ol", "hugo.ol", "idex.ol", "iox.ol", "kit.ol", "nano.ol", "nas.ol", "natto.ol", "natto.st", "nel.ol", "next.ol", "nod.ol", "nom.ol", "nor.ol", "ocy.ol", "opera.ol", "ork.ol", "pho.ol", "seam.st", "sf.st", "star-a.st", "star-b.st", "tel.ol", "thin.ol", "til.ol"]

          #stocks = StockQuote::Stock.quote(tickers) #old unreliable method, but ok for historical data

          # since we only get accurate data from Yahoo when we ask for a few stocks at a time, process everything in batches

          ticker_batches = tickers.each_slice(1).to_a

          ticker_batches.each_with_index do | ticker_batch, batch_index |
              
              #sleep(1 * (1 + batch_index)) # add a 5 second delay between fetching stock data to not get blocked by yahoo


              tickers = ticker_batch.compact.join(",") #compact removes nil values

              #source = 'http://finance.yahoo.com/webservice/v1/symbols/' + tickers + '/quote?format=json&view=detail' #old way
              
              source = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20csv%20where%20url%3D'http%3A%2F%2Fdownload.finance.yahoo.com%2Fd%2Fquotes.csv%3Fs%3D" + tickers + "%26f%3Dsl1d1t1c1p2ohgvt1d1%26e%3D.csv'%20and%20columns%3D'symbol%2Cprice%2Cdate%2Ctime%2Cchange%2Cchg_percent%2Ccol1%2Chigh%2Clow%2Ccol2%2Clast_trade_time%2Clast_trade_date'&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
              #source = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20csv%20where%20url%3D%27http%3A%2F%2Fdownload.finance.yahoo.com%2Fd%2Fquotes.csv%3Fs%3D" + tickers + "%26f%3Dsl1d1t1c1p2ohgv%26e%3D.csv%27%20and%20columns%3D%27symbol%2Cprice%2Cdate%2Ctime%2Cchange%2Cchg_percent%2Ccol1%2Chigh%2Clow%2Ccol2%27&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
              puts source
              
             # conn = Faraday.new(:url => 'https://query.yahooapis.com') do |faraday|
              #  faraday.request  :url_encoded             # form-encode POST params
               # faraday.response :logger                  # log requests to STDOUT
                #faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
              #end

              #response = conn.get do |req|
              #  req.url "/v1/public/yql?q=select%20*%20from%20csv%20where%20url%3D%27http%3A%2F%2Fdownload.finance.yahoo.com%2Fd%2Fquotes.csv%3Fs%3D" + tickers + "%26f%3Dsl1d1t1c1p2ohgv%26e%3D.csv%27%20and%20columns%3D%27symbol%2Cprice%2Cdate%2Ctime%2Cchange%2Cchg_percent%2Ccol1%2Chigh%2Clow%2Ccol2%27&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
              ##  req.headers['User-Agent'] = '{
               #   "ua": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36",
                #  "browser": {
              #       "name": "Chrome",
              #       "version": "53.0.2785.116",
              #       "major": "53"
              #     },
              #     "engine": {
              #       "version": "537.36",
              #       "name": "WebKit"
              #     },
              #     "os": {
              #       "name": "Mac OS",
              #       "version": "10.10.5"
              #     },
              #     "device": {},
              #     "cpu": {}
              #   }'
              # end

              resp = Net::HTTP.get_response(URI.parse(source))
              
              puts "code: "
              puts resp.code

              if resp.code == "200" # skip next steps if any error (no stock data etc)


                data = resp.body
                puts data
                #result = JSON.parse(data)
                result = JSON.parse(resp.body)

                puts result

                #stocks = result["list"]["resources"] #old way
                
                if !result["query"].nil? && !result["query"]["results"].nil? && !result["query"]["results"]["row"].nil?
                
                  stocks = result["query"]["results"]["row"]

                  puts "processing.."
                  puts result["query"]["count"]
                  puts "stocks"

                  puts stocks

                  for index in 0 ... result["query"]["count"]

                    puts "-- Processing: #{index} in batch #{batch_index}"

                    if result["query"]["count"] > 1
                      symbol = result["query"]["results"]["row"][index]["symbol"].downcase 
                    else
                      symbol = result["query"]["results"]["row"]["symbol"].downcase 
                    end

                    #symbol = result["list"]["resources"][index]["resource"]["fields"]["symbol"].downcase # old way

                    unless symbol.nil? || symbol == ""

                      symbol = symbol.downcase

                      if result["query"]["count"] > 1
                        price = result["query"]["results"]["row"][index]["price"]
                      else
                        price = result["query"]["results"]["row"]["price"]
                      end

                      if price == "N/A" 
                        price = "0" # something the numberanimator can handle
                      end

                      #last_updated = result["query"]["results"]["row"][index]["utctime"]
                      
                      if result["query"]["count"] > 1
                        change_percent = result["query"]["results"]["row"][index]["chg_percent"]
                      else
                        change_percent = result["query"]["results"]["row"]["chg_percent"]
                      end

                      puts "#{symbol} / #{price} / #{change_percent}"

                      ::PluginStore.set("stock_price", symbol, price)
                      ::PluginStore.set("stock_change_percent", symbol, change_percent)
                      #::PluginStore.set("stock_last_updated", symbol, last_updated)
                      
                    end 

                  #puts "#{stocks[index].to_json}"
                end
              end
            
            end
        

  		    end

  		    puts "Done!"

        end

  	end

  end
end
