class SessionsController < ApplicationController
  def create
    @auth = request.env["omniauth.auth"]
    @token = @auth["credentials"]["token"]
    Token.create(auth_token: @token)
    # client = Google::APIClient.new
    # client.authorization.access_token = @token
    # service = client.discovered_api('gmail')
    # @result = client.execute(
    #   :api_method => service.users.messages.list,
    #   :parameters => {'userId' => 'me', 'labelIds' => ['INBOX', 'Label_29']
    #   :headers => {'Content-Type' => 'application/json'})
    # err!
  end
end