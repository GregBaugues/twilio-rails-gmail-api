Send SMS email alerts with the Gmail API and Ruby on Rails
================================
I turned off GMail alerts on my phone a while ago. It just doesn't make sense for my phone to beep every time one of my mom's Facebook friends "also commented on her status." 

But not all emails are created equal. There are some messages for which I would like to know *right now* when they show up in my inbox. SMS alerts are great for customized urgent notifications like this. 

This tutorial will teach you how to build a Ruby on Rails app that retrieves emails from the GMail API and uses Twilio to send SMS email alerts. Here's the process you'll go through: 

1. Prepare your Ruby on Rails to connect to the Google API
2. Authorize your app wit the Google API using OAuth 2.0
3. Get emails from the GMail API
4. Send SMS alerts using Twilio

Let's get started...

## Setup your Ruby on Rails and GMail API project

Before you pull data from the GMail API, you need to convince Google that your app has access your account data. This is accomplished via a OAuth. The GMail API is a subsidiary of the Google API, so while this tutorial is focused on retrieving emails, the authorization process can also be used to connect to other Google APIs such as Google Calendar, Google Docs, etc. 

### 1. Open a tunnel to your development machine using ngrok

In order to authenticate with the Google API, you need to provide Google with a publicly accessible URL to reach your app. Since your development machine is hiding behind a router, you need to create a tunnel to make your local app available to the Internet at large. Though there are many tunneling apps on the market, at Twilio we're big fans of of [ngrok](http://ngrok.com). 

[Register for a free ngrok account](https://ngrok.com/user/signup), then [download it](https://ngrok.com/), unzip it and move the executable to your home directory. Then run ngrok, specifying a custom subdomain and passing the port number of your (not yet created) Rails app: 3000 by default: 

On OSX this looks like: 

```shell
unzip ~/Downloads/ngrok.zip
mv ~/Downloads/ngrok ~
~/ngrok -subdoman=example 3000
```

Once it ngrok starts, you'll see something like the picture below. So long as this terminal window stays open and ngrok stays running, anyone can access the your equivalent ```localhost:3000``` via a publicly accessible ngrok url. 

![](public/images/ngrok.png)

I'll use ```example.ngrok.com``` for the rest of the tutorial -- make sure you replace that with your custom ngrok url. 

### 2. Create a new app in your Google API console 

Head over to the [Google Developer's Console](https://console.developers.google.com/project) and click *Create Project*. Name your app ```Gmail Alerts```, and wait a few minutes for Google to to create your project. Then click into your project, click *Enable an API* and flip the toggles next to *Gmail API*, *Google Contacts CardDAV API*, and *Google+ API* (if youre the tidy type, you can turn the rest of the APIs). 

![](/public/images/google-apis-on.png)

Now create your OAuth 2.0 credentials which your Rails app will use to gain permission to interact with your GMail account. Click *Credentials* on the left side of the screen, then click *Create new Client ID*.

![](/public/images/client-id.png)

You will see a few new values will pop up on your dashboard. Open a new terminal window (don't touch the one running ngrok!) and set the *client id* and *client secret* as sessions variables.

```shell
export CLIENT_ID=123456789.apps.googleusercontent.com
export CLIENT_SECRET=abcdefg
```

Session variables (otherwise known as "environment variables") disappear with each new terminal *session*, so make sure that when you launch your Rails app in the next step, you do it from this same window. Alternatively, you can use the [dotenv](https://github.com/bkeepers/dotenv) gem to store environment variables so that you don't have to reset them from each new terminal session. 

### 3. Setup a Ruby on Rails project to access the Google API

Create a new Rails app from your preferred code directory:

```shell
cd ~/code
rails new gmail-alerts
cd gmail-alerts
```

If you use [rvm](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv), set your ruby version and gemset: 

```shell
echo "2.1.2" > .ruby-version
echo "gmail-twilio" > .ruby-gemset
```

Then set up your ```Gemfile``` to work with the Google API and Twilio. Since this will be a simple app that you run mostly from the command line, you can strip out most of the default Rails gems. 

Replace your entire ```Gemfile```with: 

```ruby
#Gemfile
source 'https://rubygems.org'

gem 'rails', '4.0.2'
gem 'sqlite3'
gem 'google-api-client', require: 'google/api_client'
gem 'json'
gem 'omniauth', '~> 1.2.2'
gem 'omniauth-google-oauth2'
gem 'twilio-ruby' 
```

Let's talk about a few of those gems: 

##### 'rails', '4.0.2'

At the time of writing this is the most recent version of Rails, but there's nothing in this tutorial that should keep your Rails 3 app from working with the Google API. 

##### sqlite3

SQLite is a great datastore for getting up and running quickly, though if you deploy this app to a production you'll probably want to upgrade to MySQL or PostgreSQL. 

##### google-api-client

The official [ruby gem of the Google API](https://github.com/google/google-api-ruby-client). Unfortunately, Google didn't quite conform to standard gem naming conventions, so if you simply use ```gem 'google-api-client'```, you'll get an ```uninitialized constant``` error when you later call ```Google::APIClient.new```. Appending ```require: 'google/api_client'``` to the gem declaration prevents this. 

##### json

The Google API gem returns data in easily digestible JSON. The JSON gem eats up that data and spits it back as a hash.

##### omniauth and omniauth-google-oauth2

OmniAuth uses swappable “strategies” to perform OAuth authentication with services such as Twitter, Facebook and GMail. Fortunately, there's a Omniauth strategy for the Google API which simplifies connecting your Rails app to the GMail API. 

##### twilio-ruby

This is the Twilio helper library that will help you send SMS messages using Ruby. 

Once your Gemfile is saved, install your gems from the terminal: 

```shell 
gem install bundler
bundle install
```

Onto the coding... 

## Authorize your Rails app with the Google API

### 1. Retrieve the Google API OAuth token using Omniauth

Even if you've never written an OAuth authorization before, you've undoubtedly used it. OAuth is the results in a screen that looks like this: 

![](public/images/choose-an-email.png)

Once the verified, Google "calls back" your app and sends a temporary access token that can be used to access your account data. Omniauth is the defacto standard way to use OAuth in Ruby apps. 

To set up Omniauth, create a new file in ```config/initializers``` called ```omniauth.rb```:

```ruby
#config/initalizers/omniauth.rb

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], {
    scope: ['email',
            'https://www.googleapis.com/auth/gmail.readonly'],
    access_type: 'offline'
  }
end
```

(PSA: any time you modify a file in the ```config/initializers``` directory, you must restart your Rails server for the changes to take effect.)

The ```provider``` line tells Omniauth setup the ```google_oauth2``` strategy with the ```CLIENT_ID``` and ```CLIENT_SECRET``` environment variables you defined earlier. 

*scope* tells the Google API which resources you want to access. If you omit the ```email``` scope you will receive an ```insufficientPermissions``` error when you try to authenticate.

Because you want to access GMail via an automated script, and because the access token Google sends you expires after 60 minutes, you must provide the ```access_type: 'offline'``` flag. This causes Google to send a refresh token that can be exchanged for new access tokens as they expire. 

Google sends these tokens via HTTP request parameters to the ```callback``` url you defined in your Google API console earlier. Let's create that. 

Delete the default code in your your ```config/routes.rb``` (yes, all of it) and replace it with: 

```ruby
# config/routes.rb

GmailAlerts::Application.routes.draw do
  get "/auth/:provider/callback" => "sessions#create"
end
```

This tells Rails, "when a request is made to ```http://example.ngrok.com/auth/google/callback``` run the ```create``` method in the ```Sessions``` controller. To define the ```SessionsController```, create a new file at ```app/controllers/sessions_controller.rb```: 

```ruby
# app/controllers/sessions_controller.rb

class SessionsController < ApplicationController
  def create
    @auth = request.env["omniauth.auth"]
  end
end
```

This is just a temporary ```SessionsController``` to make sure that the authentication flow is working correctly so far. For the sake of instant gratification, create a simple view at ```app/views/sessions/create.erb```: 

```
# app/views/sessions/create.erb

<%= @auth %>
```

Now to try it out... From the terminal window where you set your environment variables, start your Rails server: 

```shell
rails s
```

Visit ```http://example.ngrok.com/auth/google_oauth2``` in a broswer. You will be redirected to Google to authorize your GMail account, then Google will redirect to your callback URL, passing along authentication data in the request parameters. You should see something like this: 

![](/images/token.png)
(need a better picture here)

### 2. Save the OAuth token using ActiveRecord

The two most important bits of information here are in: 

```
request.env['credentials']['access_token']
```

This lets you pull data from the GMail API, but expires in 60 minutes. 

```
request.env['credentials']['refresh_token']
```

This lets you request fresh access tokens as they expire. 

Now a bit of inconvenience.... Google only sends the refresh token the first time you authorize your account, so *you have to save it*... and we just blew that opportunity. So, go to your [Gmail Account Permissions](https://security.google.com/settings/security/permissions?pli=1) and revoke permissions to the app you just authorized so that Google will send another refresh token. This time we'll be ready for it. 

Initialize your database and create an ActiveRecord model to store your tokens: 

```shell
rake db:create
rails g model token \access_token:string refresh_token:string expires_at:datetime
rake db:migrate
```

Update ```SessionsController``` to save the Google API tokens: 

```ruby
# app/controllers/sessions_controller.rb

class SessionsController < ApplicationController
  def create
    @auth = request.env["omniauth.auth"]["credentials"]
    Token.create(@auth)
      access_token:   @auth['token'],
      refresh_token:  @auth['refresh_token'],
      expires_at:     @auth['expires_at'])
      #include email?
  end
end
```

Visit ```http://example.ngrok.com/auth/google_oauth2``` again and reauthorize your GMail account. Check your database and ensure that a new record was created in your ```tokens``` table with the ```access_token``` and ```refresh_token``` populated.  

### 3. Refresh the Google API access token when necessary 

Unfortunately, the google-api-gem doesn't have a built-in method to refresh a token, so you have to write that logic yourself using the ```net/http``` and ```json``` gems. Copy this code into the Token model at ```app/models/token.rb```, then we'll talk about what it all does: 

```ruby
# app/models/token.rb

require 'net/http'
require 'json'

class Token < ActiveRecord::Base

  def to_params
    { 'refresh_token' => refresh_token,
      'client_id'     => ENV['CLIENT_ID'],
      'client_secret' => ENV['CLIENT_SECRET'],
      'grant_type'    => 'refresh_token' }
  end

  def request_token_from_google
    url = URI("https://accounts.google.com/o/oauth2/token")
    Net::HTTP.post_form(url, self.to_params)
  end

  def refresh!
    response = request_token_from_google
    data = JSON.parse(response.body)
    update_attributes(
      token: data['access_token'],
      expires_at: Time.now + (data['expires_in'].to_i).seconds
    )
  end

  def self.access_token
    t = Token.last
    t.refresh! if t.expires_at < Time.now
    t.access_token
  end

end
```

#### to_params

Converts the token's attributes into a hash that has the key names that the Google API expects. 

#### request_token_from_google

Makes a http POST request to the Google API OAuth 2.0 authorization endpoint using the token parameters from above. For more info on this process, check out the docs for [how to refresh a Google API token](https://developers.google.com/accounts/docs/OAuth2WebServer#refresh)).  

#### refresh!

Passes the token's parameters via HTTP request to to Google, then parses the JSON response and updates the token database row with the new access token and expiration date. Once you have an access token, you will not need to authenticate via the browser again. 

#### access_token

A convenience class method to return the latest access token, refreshing if necessary. 

One last note on the Token model: The tokens table is be a bit atypical in that it will only contain a single row that updates with your fresh access_token. For simplicity's sake I wrote this tutorial to only work with a single email address, but it won't be difficult to add support for multiple accounts.

## Get Emails from the GMail API

### 1. Create an SMS label and use the GMail API to find its ID

Alright! You have authorized your Rails app with the GMail API. Now it's time to pull some data. But first... let's think about how you're going to identify which emails deserve SMS alerts. You could do this in your Ruby code but that would mean modifying and redeploying your app every time you want to add a new alert. Instead, let's use GMail's robust filtering functionality to add a label called "SMS" to emails that fit specific criteria.

Now you can have your app look for emails in your inbox that have the SMS label. But first, we need to find the id of your newly created label, and we can only discover that from the GMail API. 

Create a new rake task at ```lib/tasks/list_labels.rake```: 

```ruby
#lib/tasks/list_labels.rake

require 'pp'

task :list_labels  => :environment do
  client = Google::APIClient.new  # "Create a new Google API client"
  client.authorization.access_token = Token.access_token  # "Here's my access token"
  service = client.discovered_api('gmail') # "Pull data from GMail"
  
  result = client.execute(
    :api_method => service.users.labels.list, # "Give me a list of all the labels..."
    :parameters => {'userId' => 'me'}, # "... from my GMail account... "
    :headers => {'Content-Type' => 'application/json'}) # "... in JSON."
  
  pp JSON.parse(result.body) # "Pretty Print the returned data"
end  
```

Run your rake task from the terminal: 

```shell
rake list_labels
```

![](public/images/labels.png)

My SMS label id is 'Label_29.' What's yours? 

### 2. Get a list of inbox emails marked with the SMS label

Armed with your label id, let's go get some emails. Create a new task file, ```lib/tasks/check_messages.rb``` and copy: 

```ruby
# lib/tasks/check_messages.rb
require 'pp'

task :check_messages  => :environment  do
  client = Google::APIClient.new
  client.authorization.access_token = Token.access_token
  service = client.discovered_api('gmail')
  
  result = client.execute(
    :api_method => service.users.messages.list,
    :parameters => {'userId' => 'me', 'labelIds' => ['INBOX', 'Label_29']},
    :headers => {'Content-Type' => 'application/json'})
  
    data = JSON.parse(result.body)
    pp data
  
end
```

Astute readers will notice that this is the same as your ```list_lables``` task but for four small changes: 

1. Change the task name from ```list_labels``` to ```check_messages```
2. Change the ```:api_method``` to ```service.users.messages.list```
3. Add ```'labelIds' => ['INBOX', 'Label_29']```  to the ```:parameters``` hash. 
4. Store result data a variable 

### 3. Retrieve email details from the GMail API

```ruby

  email_ids = data['emails'].collect { |e| e['id'] }
  
  result = client.execute(
    :api_method => service.users.message.detail,
    :parameters => {'userId' => 'me', 'emailIds' => email_ids},
    :headers => {'Content-Type' => 'application/json'})
    
  emails = JSON.parse(result.body)['emails']
```

NEED CODE FOR EXTRACTING DETAILS


## Send SMS alerts using Twilio

#### 1. Setup your Twilio account credentials

Sign into your Twilio account or [register a free trial account](https://www.twilio.com/try-twilio) if you don't have one already. From your [account dashboard](https://www.twilio.com/user/account), click ```Numbers``` and search for one that that suits your fancy, and buy it for $1. 

![](public/images/buy-a-phone-number.png)

Now go back to your dashboard and find your ```account_sid``` and ```auth_token```. 

![Twilio credentials](public/images/twilio-credentials.png)

Save these values as session variables in the same way that you did for the Google OAuth credentials.

```shell
export TWILIO_ACCOUNT_SID=ABCDEFGHI
export TWILIO_AUTH_TOKEN=12345679
export MY_CELLPHONE=+13126207892
export TWILIO_PHONE_NUMBER=+13128675309
```

### 2. Create an ActiveRecord model to track and send SMS alerts

We're going to keep this simple and create a model that answers the question "Have I already attempted to send an SMS alert for this email?" If you want to get fancy, you could use [delivery receipts]() to ensure that your phone received the SMS, or setup a callback for Twilio to send your app a success/error messages, but that's another blog post. 

From the terminal:

```term
rails g model alerts \email_id:string body:string
rake db:migrate
```

Then populate ```app/models/alert.rb``` with:

```ruby
class Alert < ActiveRecord::Base
  
  def self.send_sms(body)
    client = Twilio::REST::Client.new(
      ENV['TWILIO_ACCOUNT_SID'], 
      ENV['TWILIO_AUTH_TOKEN'])

    client.account.messages.create(
      to: ENV['CELLPHONE_NUMBER'],
      from: ENV['TWILIO_NUMBER'],
      body: body)
  end

end

```

The ```send_sms``` method instantiates a new Twilio REST client using your account credentials, then sends an sms using three parameters you would expect: 'to' phone number, 'from' phone number, and the message body. 

Append your ```check_emails``` task to send a text message when it discovers new emails if an alert for that message does not already exist: 

```ruby
  emails.each do |email|
    unless Alert.exists?(email_id: email.id)
      body = "#{email.from} -- #{email.subject}"
      Alert.send_sms(body)
      Alert.create(email_id: email.id) 
    end
  end
```

Try it out:

```term
rake check_emails
```

BOOM!

### 3. Create cronjob to monitor GMail


```term
1 * * * rake check_messages
```

Next steps: 

Obviously in its current form, this script is only going to work if your development machine is open. 

https://productforums.google.com/forum/#!topic/gmail/12c_hR0_F2I

