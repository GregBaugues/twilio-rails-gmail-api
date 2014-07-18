Send SMS email alerts with the Gmail API and Ruby on Rails
================================

First thing we need to do is to head over to the Google Developer's Console and create a new project and turn on the GMail API. 

Turn on the [GMail API in the Google Developers Console](https://console.developers.google.com/project/951811866064/apiui/api/gmail?authuser=0). 

![](/public/images/gmail-console.png)

You've probably authorized a webapp to login with your Google account dozens of times. We want to do something similar -- give our application permission to pull our data from our Gmail account -- but since this program is running automatically on a server, we don't want to have to give it explicit permission each time it runs. So instead of creating a web application token, we're going to create a Service Account. 

After you've created your new app, click ```Credentials```, then click ```Create Client ID``` and select ```Service account.``` A service account will allow our server to access the GMail API without user consent via the browser each time we run it. 

![](/public/images/google-service-account-key.png)

Create a new Rails app. 

```term
rails new gmail-twilio
cd gmail-twilio
```

I use [rvm](https://rvm.io/) to keep my gemsets separate from one another. 

```term
echo "2.1.2" > .ruby-version
echo "gmail-twilio" > .ruby-gemset
cd ..
cd gmail-twilio
```

Since we're not using any views in this app, we can strip out a lot of the cruft in the default gems. Replace your ```Gemfile``` with this: 

```ruby
source 'https://rubygems.org'

gem 'rails', '4.0.2'
gem 'sqlite3'
gem 'google-api-client', :require => 'google/api_client'
gem 'omniauth', '~> 1.2.2'
gem 'omniauth-google-oauth2'
```

Then run: 

```term 
gem install bundler
bundle install
```

# google-api-client

One of the first steps in the Google Calendar API v3 Documentation, is to set up the Ruby client library. Unfortunately, the examples given are for Sinatra or plain ol’ Ruby. The docs don’t mention that if you simply add this line to your Gemfile:

```ruby
gem 'google-api-client'
```

You will get an error that looks like this: 

```term
NameError (uninitialized constant SessionsController::Google)
```

So make sure you use the ```:require syntax``` from above (props to [Roo on StackOverflow](http://stackoverflow.com/questions/9308704/rails-3-routing-error-uninitialized-constant-mycontrollergoogle)).


# Omniauth 1.2.2

OmniAuth uses swappable “strategies” to connect to services such as Facebook, Twitter, FourSquare, etc. We are replacing the Twitter strategy from the RailsCast with the Google OAuth2.0 strategy. To make this work right, replace the existing app/initializers/omniauth.rb with:





