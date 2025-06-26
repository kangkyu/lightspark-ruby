require 'lightspark/config'

Lightspark.configure do |config|
  config.client_id = ENV["LIGHTSPARK_TEST_API_TOKEN_CLIENT_ID"]
  config.client_secret = ENV["LIGHTSPARK_TEST_API_TOKEN_CLIENT_SECRET"]
end
