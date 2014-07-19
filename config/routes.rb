Gmail::Application.routes.draw do
  root 'google#connect'
  get "/auth/:provider/callback" => "sessions#create"
end
