Rails.application.routes.draw do
  post '/upload', to: 'computation#upload_file'
end
