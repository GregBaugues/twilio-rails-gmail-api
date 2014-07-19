require 'pp'
task :check_messages  => :environment  do
  client = Google::APIClient.new
  client.authorization.access_token = Token.access_token
  service = client.discovered_api('gmail')
  result = client.execute(
      :api_method => service.users.messages.list,
      :parameters => {'userId' => 'me', 'labelIds' => ['INBOX', 'Label_29']},
      :headers => {'Content-Type' => 'application/json'})
  messages = JSON.parse(result.body)
  pp messages
end

