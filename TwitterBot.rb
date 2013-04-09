# -*- coding: utf-8 -*-
require 'oauth'
require 'json'
require 'yaml'

#--------- TwitterBot ---------
class TwitterBot

  def initialize
    yml_data = YAML.load_file('./setting.yml')
    @consumer = OAuth::Consumer.new(
      @CONSUMER_KEY = yml_data["consumer_key"],
      @CONSUMER_SECRET = yml_data["consumer_secret"],
      :site => 'https://api.twitter.com/1.1'
    )
    @access_token = OAuth::AccessToken.new(
      @consumer,
      @ACCESS_TOKEN = yml_data["access_token"],
      @ACCESS_TOKEN_SECRET = yml_data["access_token_secret"]
    )
  end

  #--------- ツイート---------
  def tweet( message )
    @access_token.post(
      '/statuses/update.json',
      'status' => message
    )
  end

  #--------- ツイート受信 <+0000の時刻,発言内容,発言者> ---------
  def get_tweet
    response = @access_token.get(
      '/statuses/home_timeline.json'
    )

    tweet_resource = JSON.parse(response.body)
   
    tweets = Array.new

    tweet_resource.each do |tr|
      tweets << {
        "user_id" => tr["user"]["screen_name"],
        "user_name" => tr["user"]["name"],
        "message" => tr["text"],
        "time" => tr["created_at"] }
    end

    return tweets
  end

end
