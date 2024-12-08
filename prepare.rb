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

# Prepare the CSV file
CSV_FILE_PATH = 'data/contacts_with_birthdays.csv'
Dir.mkdir('data') unless Dir.exist?('data') # Ensure the directory exists
CSV.open(CSV_FILE_PATH, 'w') do |csv|
  csv << ['Name', 'Resource Name', 'Birthday'] # Write the header row

  total_with_birthdays = 0
  page_token = nil

  loop do
    # Fetch a page of contacts
    response = service.list_person_connections(
      'people/me',
      person_fields: 'names,birthdays,metadata',
      page_size: 100,
      page_token: page_token
    )

    # Process the current page
    current_page_with_birthdays = 0
    response.connections&.each do |person|
      next unless person.birthdays # Skip if no birthday

      # Extract data
      name = person.names&.first&.display_name || 'Unknown'
      resource_name = person.resource_name
      birthday_data = person.birthdays[0].date
      birthday = "#{birthday_data.year || 'unknown'}-#{birthday_data.month || 'unknown'}-#{birthday_data.day || 'unknown'}"

      # Write to CSV
      csv << [name, resource_name, birthday]

      current_page_with_birthdays += 1
    end

    # Update totals
    total_with_birthdays += current_page_with_birthdays
    puts "Found #{current_page_with_birthdays} contacts with birthdays on this page."
    puts "Total so far: #{total_with_birthdays} contacts with birthdays."

    # Break the loop if there's no next page
    page_token = response.next_page_token
    break unless page_token
  end

  puts "Processing complete. Total contacts with birthdays: #{total_with_birthdays}"
  puts "Results saved to #{CSV_FILE_PATH}"
end
