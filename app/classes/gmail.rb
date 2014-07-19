class GMail

  def self.setup
    @@client = Google::APIClient.new(
      :application_name => 'SMS Gmail Alerts',
      :application_version => '1.0.0')
    @@client.authorization.access_token = Token.access_token
    @@service = @@client.discovered_api('gmail')
  end

  def self.request(method, params={})
    setup if @@client.nil?
    result = @@client.execute(
      :api_method => method,
      :parameters => {'userId' => 'me'}.merge(params),
      :headers => {'Content-Type' => 'application/json'})
    JSON.parse(result.body)
  end

  def self.messages(params = {})
    method = @@service.users.messages.list
    request(method)['messages']
  end

  def self.labels(params = {})
    method = @@service.users.labels.list
    request(method)['labels']
  end

end