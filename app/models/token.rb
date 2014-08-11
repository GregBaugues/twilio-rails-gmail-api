require 'open-uri'
require 'net/http'
require 'json'

class Token < ActiveRecord::Base

  def self.access_token
    #convenience method to retrieve the latest token and refresh if necessary
    t = Token.last
    t.refresh! if t.expires_at < Time.now
    t.token
  end

  def refresh!
    data = JSON.parse(request_token_from_google.body)
    update_attributes(
      token: data['access_token'],
      expires_at: Time.now + data['expires_in'].to_i.seconds
    )
  end

  def request_token_from_google
    url = URI("https://accounts.google.com/o/oauth2/token")
    Net::HTTP.post_form(url, self.to_params)
  end

  def to_params
    { 'refresh_token' => refresh_token,
      'client_id'     => ENV['CLIENT_ID'],
      'client_secret' => ENV['CLIENT_SECRET'],
      'grant_type'    => 'refresh_token'}
  end

end
