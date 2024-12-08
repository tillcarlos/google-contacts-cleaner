## What is this

A tool to clean up my contacts

## Prepare

get the credentials.json from a google API user, with contacts API enabled.

`bundle install`

## Run it like this:

`ruby authorize.rb` - make sure you get the credentials

...
Total so far: 722 contacts with birthdays.
Found 11 contacts with birthdays on this page.
Total so far: 733 contacts with birthdays.
Processing complete. Total contacts with birthdays: 733
...

`ruby prepare.rb` - see if data/... holds a list. 
`ruby execute.rb` - removes the birthdays form that csv in data.

## Resources

https://console.cloud.google.com/apis/dashboard?pli=1&project=lighthouse-crawler-347004



