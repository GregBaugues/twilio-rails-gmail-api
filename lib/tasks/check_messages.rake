require 'pp'

task :check_emails  => :environment  do
  client = Google::APIClient.new
  client.authorization.access_token = Token.access_token
  service = client.discovered_api('gmail')

  result = client.execute(
    :api_method => service.users.messages.list,
    :parameters => {'userId' => 'me', 'labelIds' => ['INBOX', 'Label_29']},
    :headers => {'Content-Type' => 'application/json'})

  data = JSON.parse(result.body)

  email_ids = data['messages'].collect { |msg| msg['id'] }

  email_ids.each do |id|
    result = client.execute(
      :api_method => service.users.messages.get,
      :parameters => {'userId' => 'me', 'id' => id},
      :headers => {'Content-Type' => 'application/json'})
    data = JSON.parse(result.body)

    subject = get_gmail_attribute(data, 'Subject')
    from = get_gmail_attribute(data, 'From')

    pp "#{id} - #{from} - #{subject}"
  end

end

def get_gmail_attribute(gmail_data, attribute)
  headers = gmail_data['payload']['headers']
  array = headers.reject { |hash| hash['name'] != attribute }
  array.first['value']
end