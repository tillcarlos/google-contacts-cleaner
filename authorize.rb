require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/people_v1'
require 'date'
require 'fileutils'
require 'sinatra'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Google People API - Tills Cleanup Tool'
CLIENT_SECRETS_PATH = 'credentials/credentials.json'
CREDENTIALS_PATH = 'credentials/token.yaml'
SCOPE = Google::Apis::PeopleV1::AUTH_CONTACTS

def authorize
  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)

  # Launch a Sinatra server to handle the OAuth redirect
  credentials = nil
  Thread.new do
    Sinatra::Base.set :port, 4567
    Sinatra::Base.get '/oauth2callback' do
      code = params['code']
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: 'default', code: code, base_url: 'http://localhost:4567'
      )
      "Authorization successful! You can close this window."
    end
    Sinatra::Base.run!
  end

  # Generate the authorization URL
  url = authorizer.get_authorization_url(base_url: 'http://localhost:4567')
  puts "Open the following URL in your browser and authorize the application:"
  puts "-----------"
  puts url

  # Wait until credentials are set by the Sinatra thread
  until credentials
    sleep 1
  end

  credentials
end

# Initialize the API
service = Google::Apis::PeopleV1::PeopleServiceService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

