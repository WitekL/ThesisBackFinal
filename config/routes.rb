Rails.application.routes.draw do
  post '/upload', to: 'computation#upload_file'
  post '/creator', to: 'computation#creator'
end
