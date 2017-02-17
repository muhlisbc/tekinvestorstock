module Jobs
  class EmailExport < Jobs::Scheduled

  	include Sidekiq::Worker

    # export email addyes to email sender (drip)

    every 1.hour

    def execute(args)
        
        client = Drip::Client.new do |c|
          c.api_key = "eqwaxhhcryfcxxdyqwhu"
          c.account_id = "9675646"
        end

        subscribersListStart = '{"batches": [{"subscribers": ['
        subscribersListEnd = '}]}]}'

        puts "Finding all users"

        users = User.order(created_at: :desc).limit(10) # Drip has 1000 element limit in batches

        users.each do |user|
	  	
  		  	puts "processing:" + user.email
          isInsider = false

          group = Group.find_by("lower(name) = ?", "insider")
          
          if group && GroupUser.where(user_id: user.id, group_id: group.id).exists? 
            isInsider = true
          else
            isInsider = false
          end
  		  	
          subscriberInfo = '{
                "email": "' + user.email + '",
                "time_zone": "Europe/Copenhagen",
                "custom_fields": {
                  "insider": "' + isInsider + '",
                  "username": "' + user.username + '",
                  "created_at": "' + user.created_at.to_s + '",
                  "last_seen_at": "' + user.last_seen_at.to_s + '"
                }
          },'

          subscribersListStart = subscribersListStart + subscriberInfo

  		  end

        subscribers = subscribersListStart.slice!(subscribersListStart.length-1,subscribersListStart.length) + subscribersListEnd #remove trailing ,
        puts subscribers

        resp = client.create_or_update_subscribers(subscribers)
        puts resp

        puts "import complete"

      end

        # {
        #   "batches": [{
        #     "subscribers": [
        #       {
        #         "email": "john@acme.com",
        #         "time_zone": "America/Los_Angeles",
        #         "tags": ["Customer", "SEO"],
        #         "custom_fields": {
        #           "name": "John Doe"
        #         }
        #       },
        #       {
        #         "email": "joe@acme.com",
        #         "time_zone": "America/Los_Angeles",
        #         "tags": ["Prospect"],
        #         "custom_fields": {
        #           "name": "Joe"
        #         }
        #       }
        #     ]
        #   }]
        # }

  end
end
