# -*- coding: utf-8 -*-
require './TwitterBot.rb' # TwitterBot.rbの読み込み

#---------- MyTwitterBot ----------                                                                         
class MyTwitterBot < TwitterBot
  
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
        a = tweet( Time.now.to_s + msg )
        #puts msg
      end

    end

  end 
  

end

tw = MyTwitterBot.new
tw.tweet_requested_msg
