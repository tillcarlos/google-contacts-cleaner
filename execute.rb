require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/people_v1'
require 'csv'

APPLICATION_NAME = 'Google People API - Tills Cleanup Tool'
CLIENT_SECRETS_PATH = 'credentials/credentials.json'
CREDENTIALS_PATH = 'credentials/token.yaml'
SCOPE = Google::Apis::PeopleV1::AUTH_CONTACTS

def authorize
  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)

  credentials = authorizer.get_credentials('default')
  raise "No valid token found. Run the authorization script first." if credentials.nil?

  credentials
end

# Initialize the API
service = Google::Apis::PeopleV1::PeopleServiceService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Path to the CSV file
CSV_FILE_PATH = 'data/contacts_with_birthdays.csv'

# Read the CSV and update contacts
updated_count = 0
CSV.foreach(CSV_FILE_PATH, headers: true) do |row|
  name = row['Name']
  resource_name = row['Resource Name']
  birthday = row['Birthday']

  # Update the contact
  begin
    sleep 1
    
    contact = service.get_person(
      resource_name,
      person_fields: 'metadata'
    )
    etag = contact.etag

    puts "Updating contact: #{name} (#{resource_name}), etag = #{etag}"
    service.update_person_contact(
      resource_name,
      Google::Apis::PeopleV1::Person.new(
        etag: etag, # Include the etag
        birthdays: [], # Remove the birthday
        biographies: [
          Google::Apis::PeopleV1::Biography.new(
            value: "Birthday: #{birthday}"
          )
        ]
      ),
      update_person_fields: 'birthdays,biographies'
    )
    updated_count += 1
  rescue Google::Apis::ClientError => e
    puts "API error for resource (#{resource_name}): #{e.message}"
    puts e.inspect
  rescue => e
    puts "Failed to update contact: #{name} (#{resource_name}) - #{e.message}"
  end
end

puts "Processing complete. Total contacts updated: #{updated_count}"
