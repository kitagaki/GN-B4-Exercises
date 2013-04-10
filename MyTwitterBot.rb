# -*- coding: utf-8 -*-
require './TwitterBot.rb' # TwitterBot.rbの読み込み
require './GoogleAPI.rb' 
require 'open-uri'
require 'csv'

#---------- MyTwitterBot ----------                                                                         
class MyTwitterBot < TwitterBot

  #----------- プロフィールの情報を取得する ----------
  def get_credentials
    response = @access_token.get('/account/verify_credentials.json')
    
    profile = JSON.parse(response.body)

    return profile
  end 

  #----------- 本日の天気を取得する ----------
  # return : 文字列型で今日の天気
  def get_weather    
    url = "http://weather.livedoor.com/forecast/webservice/json/v1"
    
    result = open(url + '?' + "city=330010").read
    
    weather = JSON.parse(result)

    # 配列の[0]は今日,[1]は明日を意味している
    return weather["forecasts"][0]["telop"]
  end

  #----------- xxx_msg を取得する-----------
  # " 「xxx」と言って" という文字列があれば xxx を返す
  # なければ nil を返す
  def get_xxx_msg( msg )
    /「(.+)」と言って/ =~ msg
    return $1
  end

  #----------- CSVファイルからプロフィールを取得する-----------
  # return : 名前(String)と誕生日(Date)を含むプロフィール
  def get_profile( filename )
    profile = []
    i = 0
    CSV.foreach(filename) do |row|
      profile[i] = {}
      profile[i]["name"] = row[0]
      profile[i]["birthday"] = Date.parse(row[1])
      i += 1
    end
    
    return profile
  end

  #------------ 指定した日付が今日と一致しているか判定 -----------
  # return : 一致していたらtrue，そうでなければfalse
  def is_birthday_today( date )
    today = Date.today   
    return ( date.month == today.month && date.day == today.day )
  end

  #------------ 今日誕生日の人がいたらつぶやく -----------
  def tweet_birthday
    profile = get_profile('birthday.csv')
    profile.each do |prof|
      if is_birthday_today(prof["birthday"])
        tweet( "本日は" + prof["name"] + "さんの誕生日です．おめでとうございます！ by bot")
      end
    end
  end

  #---------- ツイートの要求があればつぶやく----------
  def tweet_requested_msg    
    tweets = get_tweet
 
    tweets.each do |post|
      msg = get_xxx_msg( post["message"] )
 
      if msg != nil
        tweet( msg + "by bot")
       end

    end

  end 

  #---------- 本日の天気をツイートする -----------
  def tweet_weather 
    
    tweet( "今日は" + get_weather + "ですねえ． by bot" )
   
  end

  #---------- 一番近い予定が何日前か知らせる -----------
  def tweet_close_event

    cal = GoogleAPI.new
    event = cal.get_event

    if event["summary"] != nil      
      tweet( event["summary"] + "が" + event["diff_day"].to_s + "日前です. by bot" )
    else
      tweet( "最近は何も予定ないわ～． by bot" )
    end

  end

 
end

tw = MyTwitterBot.new
#tw.tweet_requested_msg
#tw.tweet_weather
#tw.tweet_close_event
tw.tweet_birthday
