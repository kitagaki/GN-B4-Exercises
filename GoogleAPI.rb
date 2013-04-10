# -*- coding: utf-8 -*-
##########################################################################
# 【GNグループ新人研修課題】RubyによるTwitterBotプログラムの作成
#
# ファイルの内容: GoogleCalendarAPIを利用してカレンダー情報を取得するクラス
#
# 作成者: 北垣 千拡
# 
##########################################################################

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

  #------------ GoogleCalendarAPIを利用してeventlistを取得する------------
  # return : 今日以降のイベントリスト
  def get_eventlist
    return @client.execute(:api_method => @service.events.list,
                           :parameters => {'calendarId' => @CALENDAR_ID, 'timeMin' => DateTime.now})
  end

  #------------ 最近傍のイベントを取得する-----------
  # return : most_close_events 予定名，予定までの日数，予定の始まる日，予定の終わる日を含む配列
  def get_most_close_events

    eventlist = get_eventlist

    events = eventlist.data.items

    most_close_events = []
    most_close_events[0] = {"summary"=>nil, "diff_day"=>99999, "start"=>nil, "end"=>nil}

    events.each do |e|
      
      if e.summary != nil # 予定名が存在する
        most_close_events = update_most_close_events( most_close_events, e  )        
      end

    end

    return most_close_events

  end

  #----------- 最近傍のイベントを更新する----------
  # cur_events : 現在最近傍のイベント
  # new_event  : 新しいイベント
  def update_most_close_events( cur_events, new_event )
    
    start_date = get_start_date(new_event)
    end_date   = get_end_date(new_event)
    
    new_diff = get_date_diff(Date.today, start_date, end_date)
    cur_diff = cur_events[0]["diff_day"]

    if new_diff == cur_diff && new_diff >= 0

      cur_events << {"summary"=>new_event.summary, "diff_day"=>new_diff, "start"=>start_date, "end"=>end_date}
      
    elsif cur_diff > new_diff && new_diff >= 0
      
      cur_events.clear
      cur_events << {"summary"=>new_event.summary, "diff_day"=>new_diff, "start"=>start_date, "end"=>end_date}
      
    end

    return cur_events

  end

  #------------ イベントからイベント開始時刻を取得する ------------
  # return : イベントの開始時刻(Date型)
  def get_start_date( e )    

    if  e.start.date_time != nil # 終日でない,開始終了時刻のある予定
      start_date = Date.new(e.start.date_time.year, e.start.date_time.month, e.start.date_time.day)
      
    elsif  e.start.date != nil # 終日の予定
      tmp = e.start.date.split('-')
      start_date = Date.new( tmp[0].to_i, tmp[1].to_i, tmp[2].to_i )
    end

    return start_date

  end

  #------------ イベントからイベント終了時刻を取得する ------------
  # return : イベントの終了時刻(Date型)
  def get_end_date( e )

    if  e.start.date_time != nil # 終日でない,開始終了時刻のある予定
      end_date = Date.new(e.end.date_time.year, e.end.date_time.month, e.end.date_time.day)

    elsif  e.start.date != nil # 終日の予定
      tmp = e.end.date.split('-')
      end_date = Date.new( tmp[0].to_i, tmp[1].to_i, tmp[2].to_i ) - 1 # 終日の時は終了日が+1されているので戻す
    end

    return end_date

  end

  #------------ 指定した日付との日数差を取得する -----------
  # return : 日数差(int型)
  def get_date_diff(date, start_date, end_date)

    if start_date <= date && date <= end_date
      diff = 0
    else
      diff = (start_date - date).to_i
    end
    
    return diff

  end



end

