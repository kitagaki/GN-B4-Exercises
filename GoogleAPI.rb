# -*- coding: utf-8 -*-

require 'rubygems'
require 'google/api_client'
require 'yaml'
require 'date'

class GoogleAPI

  def initialize

    oauth_yaml = YAML.load_file('google-api.yml')
    @client = Google::APIClient.new("application_name"=>"twitterbot")
    @client.authorization.client_id = oauth_yaml["client_id"]
    @client.authorization.client_secret = oauth_yaml["client_secret"]
    @client.authorization.scope = oauth_yaml["scope"]
    @client.authorization.refresh_token = oauth_yaml["refresh_token"]
    @client.authorization.access_token = oauth_yaml["access_token"]
    
    @CALENDAR_ID = oauth_yaml["calendar_id"]
    
    if @client.authorization.refresh_token && @client.authorization.expired?
      @client.authorization.fetch_access_token!
    end
  
    @service = @client.discovered_api('calendar', 'v3')
  
  end

  #----------- 一番最近行われるイベントを取得する -----------
  # return : most_close_event
  def get_event

    most_close_event = {"summary"=>nil, "diff_day"=>99999}

    today = Date.today
    page_token = nil
    result = result = @client.execute(:api_method => @service.events.list,
                                      :parameters => {'calendarId' => @CALENDAR_ID})

    while true
      events = result.data.items     
      events.each do |e|

        # 終日でない,開始終了のある予定        
        if e.start.date_time != nil          
          diff = (Date.new(e.start.date_time.year, e.start.date_time.month, e.start.date_time.day) - today).to_i
          if most_close_event["diff_day"] > diff && diff >= 0
            most_close_event["diff_day"] = diff
            most_close_event["summary"] = e.summary
          end          
        end

        # 終日の予定
        if e.start.date != nil
          date = e.start.date.split('-')
          diff = (Date.new( date[0].to_i, date[1].to_i, date[2].to_i ) - today).to_i
          if most_close_event["diff_day"] > diff && diff >= 0
            most_close_event["diff_day"] = diff
            most_close_event["summary"] = e.summary
          end
        end 
        
        #print e.summary
        #print diff
        #print "\n"

      end
      
      if !(page_token = result.data.next_page_token)
        break
      end      
      result = result = @client.execute(:api_method => service.events.list,
                                        :parameters => {'calendarId' => @CALENDAR_ID, 'pageToken' => page_token})
    end
    
    return most_close_event

  end

end

