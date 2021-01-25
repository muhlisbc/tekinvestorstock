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
        
	group = Group.find_by("lower(name) = ?", "insider")

        puts "Finding all users"

        users_all = User.order(id: :desc).find_in_batches(batch_size: 1000) do |users| # Drip has 1000 element limit in batches

		subscribersListStart = '{"batches": [{"subscribers": ['
		subscribersListEnd = '}]}]}'

		users.each do |user|

	        user_email = UserEmail.where(user_id: user.id)

		if user_email == nil
			user_email = ""
			puts user.id
			puts "user_email nil"
		end

		puts "processing: ID: " + user.id + " " + user_email
			
		  isInsider = false

		  if group && GroupUser.where(user_id: user.id, group_id: group.id).exists? 
		    isInsider = true
		  else
		    isInsider = false
		  end

		   # find stats for this user
		   results = nil
		   sql = "SELECT SUM(reads) as sum_reads, count(id) as post_count, avg(like_count) AS like_avg, sum(like_count) as total_likes_received, user_id from posts Where user_id = " + user.id.to_s + " group by user_id"
		   results = ActiveRecord::Base.connection.execute(sql)

			sum_reads = 0
			post_count = 0
			like_avg = 0
			total_likes_received = 0

			if !results.to_a.empty?
				sum_reads = results[0]["sum_reads"]
				post_count = results[0]["post_count"]
				like_avg = results[0]["like_avg"]
				total_likes_received = results[0]["total_likes_received"]

				puts sum_reads.to_s + " / " + post_count.to_s + " / " + like_avg.to_s + " / " + total_likes_received.to_s

			end
			
		  subscriberInfo = '{
			"email": "' + user_email + '",
			"time_zone": "Europe/Copenhagen",
			"custom_fields": {
			  "insider": "' + isInsider.to_s + '",
			  "username": "' + user.username + '",
			  "users_posts_read_x_times": "' + sum_reads.to_s + '",
			  "post_count": "' + post_count.to_s + '",
			  "likes_received_per_post": "' + like_avg.to_s + '",
			  "total_likes_received": "' + total_likes_received.to_s + '",
			  "created_at": "' + user.created_at.to_s + '",
			  "last_seen_at": "' + user.last_seen_at.to_s + '"
			}
		  },'

		  puts subscriberInfo

		  subscribersListStart = subscribersListStart + subscriberInfo

			  end

		subscribers = subscribersListStart.slice!(subscribersListStart.length-1,subscribersListStart.length) + subscribersListEnd #remove trailing ,
		puts subscribers

		resp = client.create_or_update_subscribers(subscribers)
		puts resp
	end
	    
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
