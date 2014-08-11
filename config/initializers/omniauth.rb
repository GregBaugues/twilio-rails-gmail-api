Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], {
    approval_prompt: 'force',
    access_type: 'offline',
    scope: ['email',
            'https://www.googleapis.com/auth/gmail.readonly']}
end