task :list_labels  => :environment  do
  require 'pp'

  client = Google::APIClient.new
  client.authorization.access_token = Token.access_token
  service = client.discovered_api('gmail')
  result = client.execute(
      :api_method => service.users.labels.list,
      :parameters => {'userId' => 'me'},
      :headers => {'Content-Type' => 'application/json'})
  pp JSON.parse(result.body)
end
