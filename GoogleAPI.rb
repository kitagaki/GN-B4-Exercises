# -*- coding: utf-8 -*-

require 'rubygems'
require 'google/api_client'
require 'yaml'
require 'date'

class GoogleAPI

  def initialize( filename )

    oauth_yaml = YAML.load_file(filename)
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

  #-----------  一番最近行われるイベントを取得する -----------
  # return : most_close_events 予定名，予定までの日数，予定の始まる日，予定の終わる日を含む配列を返す
  def get_events
    
    i = 0
    most_close_events = []
    most_close_events[i] = {"summary"=>nil, "diff_day"=>99999, "start"=>nil, "end"=>nil}
    
    today = Date.today
    page_token = nil
    result = result = @client.execute(:api_method => @service.events.list,
                                      :parameters => {'calendarId' => @CALENDAR_ID})

    while true
      events = result.data.items
      events.each do |e|
        
        # 予定名が存在する
        if e.summary != nil 
          
          # 終日でない,開始終了時刻のある予定
          if  e.start.date_time != nil 
            start_date = Date.new(e.start.date_time.year, e.start.date_time.month, e.start.date_time.day)
            end_date = Date.new(e.end.date_time.year, e.end.date_time.month, e.end.date_time.day)
            
          # 終日の予定
          elsif  e.start.date != nil
            date = e.start.date.split('-')
            start_date = Date.new( date[0].to_i, date[1].to_i, date[2].to_i )
            date = e.end.date.split('-')
            end_date = Date.new( date[0].to_i, date[1].to_i, date[2].to_i ) - 1 # 終日の時は終了日が+1されているので戻す
          end
          
          if start_date <= today && today <= end_date
            diff = 0
          else
            diff = (start_date - today).to_i
          end
 
          if most_close_events[0]["diff_day"] == diff && diff >= 0
            most_close_events[i] = {"summary"=>nil, "diff_day"=>99999, "start"=>nil, "end"=>nil}
            
            most_close_events[i]["diff_day"] = diff
            most_close_events[i]["summary"] = e.summary
            most_close_events[i]["start"] = start_date
            most_close_events[i]["end"] = end_date
            
            i += 1
          elsif most_close_events[0]["diff_day"] > diff && diff >= 0
            most_close_events.clear
            most_close_events[0] = {"summary"=>nil, "diff_day"=>99999, "start"=>nil, "end"=>nil}
            i = 0
            most_close_events[i]["diff_day"] = diff
            most_close_events[i]["summary"] = e.summary
            most_close_events[i]["start"] = start_date
            most_close_events[i]["end"] = end_date

            i += 1
          end
        end

      end

      if !(page_token = result.data.next_page_token)
        break
      end
      result = result = @client.execute(:api_method => service.events.list,
                                        :parameters => {'calendarId' => @CALENDAR_ID, 'pageToken' => page_token})
    end

    return most_close_events

  end

end

