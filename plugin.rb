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

      def get_stocks_favorite_count
        if !params[:ticker].nil?
          
          stock_favorite_count = ::PluginStore.get("stock_favorite_count", params[:ticker])

          if stock_favorite_count.nil?
            ::PluginStore.set("stock_favorite_count", params[:ticker], 0)
          end

          render json: ::PluginStore.get("stock_favorite_count", params[:ticker]).to_i

        end
      end

      def increment_stocks_favorite_count(ticker)
        if !params[:ticker].nil?
          
          stock_favorite_count = ::PluginStore.get("stock_favorite_count", params[:ticker])

          if stock_favorite_count.nil?
            ::PluginStore.set("stock_favorite_count", params[:ticker], 0)
          else 
            ::PluginStore.set("stock_favorite_count", params[:ticker], stock_favorite_count.to_i + 1)
          end

        end
      end

      def decrement_stocks_favorite_count(ticker)
        if !params[:ticker].nil?
          
          stock_favorite_count = ::PluginStore.get("stock_favorite_count", params[:ticker])

          if stock_favorite_count.nil?
            ::PluginStore.set("stock_favorite_count", params[:ticker], 0)
          else 
            ::PluginStore.set("stock_favorite_count", params[:ticker], stock_favorite_count.to_i - 1)
          end
          
        end
      end

      def add_stock_to_users_favorite_stocks
        increment_stocks_favorite_count(params[:ticker])
        stocks_array = current_user.custom_fields["favorite_stocks"]

        if !stocks_array.nil?
          stocks_array.push(params[:ticker]) unless stocks_array.include?(params[:ticker])
        else  
          stocks_array = [params[:ticker]]
        end

        current_user.custom_fields["favorite_stocks"] = stocks_array
        current_user.save

        render json: { message: "OK" }

      end

      def get_users_favorite_stocks
        render json: current_user.custom_fields["favorite_stocks"]
      end

      # update stock price
      def stock_data
        
        if !params[:ticker].nil?

          stock_last_updated = ::PluginStore.get("stock_data_last_values_last_updated", params[:ticker])
          
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
          @stock_data = @stock_data << get_stock_data(params[:ticker])

          render json: @stock_data
          
        end

        return

      end

      def set_stock_data()

        if !params[:ticker].nil? 

          stock = StockQuote::Stock.quote(params[:ticker]).to_json
        
          ::PluginStore.set("stock_data_last_values", params[:ticker], stock)
          ::PluginStore.set("stock_data_last_values_last_updated", params[:ticker], Time.now.to_i)

        end

      end

      def get_stock_data(ticker)
        if !params[:ticker].nil? 
          ::PluginStore.get('stock_data_last_values', params[:ticker])
        end
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

    get '/get_users_favorite_stocks' => 'stock#get_users_favorite_stocks'
    get '/add_stock_to_users_favorite_stocks' => 'stock#add_stock_to_users_favorite_stocks'

    get '/user_average_price' => 'stock#get_user_average_price'
    get '/set_user_average_price' => 'stock#set_user_average_price'
  end

  Discourse::Application.routes.append do
    mount ::StockPlugin::Engine, at: '/stock'
  end


end
