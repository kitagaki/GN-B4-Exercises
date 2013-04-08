# -*- coding: utf-8 -*-
require './TwitterBot.rb' # TwitterBot.rbの読み込み
require 'open-uri'

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

 
end

tw = MyTwitterBot.new
#tw.tweet_requested_msg
#tw.tweet_weather

