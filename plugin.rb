# name: stock
# about: 
# version: 0.1
# authors: JT

register_asset "javascripts/alert.js"
register_asset "javascripts/numberanimate.js"

load File.expand_path("../stock.rb", __FILE__)

StockPlugin = StockPlugin
    
gem 'stock_quote', '1.1.2' ## comment this out on local, but should be there for prod

after_initialize do

  module StockPlugin

    class Engine < ::Rails::Engine
      engine_name "stock_plugin"
      isolate_namespace StockPlugin
    end

    class StockController < ActionController::Base
      include CurrentUser

      # update stock price
      def stock_data

        stock_last_updated = ::PluginStore.get("stock_funcom", 'stock_last_updated')
        
        # if no data, update now
        if stock_last_updated.nil? || stock_last_updated == ''
          set_stock_data()  
          stock_last_updated = Time.now.to_i
        end


        # if data has not been updated in 1 minute, update
        if Time.now.to_i - stock_last_updated > 60

          set_stock_data()  

        end

        # return stock object
    	  @stock_data = []
        @stock_data = @stock_data << get_stock_data('stock_funcom', 'stock_data')

        render json: @stock_data
        return

      end

      def set_stock_data()
        stock = StockQuote::Stock.quote("funcom.ol").to_json
        
        ::PluginStore.set("stock_funcom", 'stock_data', stock)
        ::PluginStore.set("stock_funcom", 'stock_last_updated', Time.now.to_i)

      end

      def get_stock_data(stock, type)
        ::PluginStore.get(stock, type)
      end


      # user stock price

      def set_user_stock
        
        ::PluginStore.set("user_stock", current_user.id.to_s, params[:value])
        render json: nil
        return
      end  

      def get_user_stock
        
        render json: ::PluginStore.get("user_stock", current_user.id.to_s)
        return

      end  

      # user avg stock price

      def set_user_average_price
        
        ::PluginStore.set("user_average_price", current_user.id.to_s, params[:value])
        render json: nil
        return
      end  

      def get_user_average_price
        
        render json: ::PluginStore.get("user_average_price", current_user.id.to_s)
        return

      end  

    end

  end

  StockPlugin::Engine.routes.draw do
    get '/stock_data' => 'stock#stock_data'
    get '/user_stock' => 'stock#get_user_stock'
    get '/set_user_stock' => 'stock#set_user_stock'

    get '/user_average_price' => 'stock#get_user_average_price'
    get '/set_user_average_price' => 'stock#set_user_average_price'
  end

  Discourse::Application.routes.append do
    mount ::StockPlugin::Engine, at: '/stock'
  end


end
