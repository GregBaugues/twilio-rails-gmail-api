class SessionsController < ApplicationController
  def create
    @auth = request.env["omniauth.auth"]["credentials"]
    Token.create(@auth)
      token:          @auth['token'],
      refresh_token:  @auth['refresh_token'],
      expires_at:     @auth['expires_at'])
  end
end