USERNAME = ''
PASSWORD = ''
begin
    load 'config.rb'
rescue Exception
end

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  http_basic_authenticate_with name: USERNAME, password: PASSWORD, except: :index
end
