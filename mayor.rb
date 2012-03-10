require 'rubygems'
require 'foursquare2'
require 'geokit'
require 'oauth2'
require 'cronedit'

require 'config'

# Search for a venue using a location and a name
def venue_search(client)
	print "Enter the venue's approximate address: "
	venue_location = gets

	print "Enter a query for the venue search: "
	venue_query = gets

	geo = Geokit::Geocoders::YahooGeocoder.geocode venue_location
	venues = client.search_venues(:ll => geo.ll, :query => venue_query, :limit => 10)
	venues.groups[0].items.each_with_index do |venue, index|
		puts "(#{index + 1}) #{venue.name} [:#{venue.id} @ #{venue.location.address}, #{venue.location.city}, #{venue.location.state}]."
	end
	puts "(0) My venue isn't here! Try again..."

	chosen_venue = gets
	case chosen_venue.strip.to_i
		when 1..10
			venue_id = venues.groups[0].items[chosen_venue.strip.to_i - 1].id
		when 0
			venue_id = venue_search client
		else
			puts "Invalid choice.: '#{chosen_venue.strip}'"
			venue_id = venue_search client
	end

	return venue_id
end

# Generate OAuth link
def oauth_token
	oauth_client = OAuth2::Client.new($client_id, $client_secret, :site => 'https://foursquare.com/', :authorize_url => '/oauth2/authenticate')
	url = oauth_client.auth_code.authorize_url(:redirect_uri => 'http://svveetdesign.com/4sq/index.php')

	puts "Copy this in your browser and hit accept: "
	puts url
	print "Now paste your OAuth Access Token here: "
	token = gets

	if token.strip.empty?
		token = oauth_token
	end

	return token
end

# Create a CRON task
def cronme_betch(venue_id, token)
	cmd = "curl -X POST -d 'venueId=#{venue_id}&broadcast=private' https://api.foursquare.com/v2/checkins/add?oauth_token=#{token}"

	CronEdit::Crontab.Add '4sq-mayor', {:hour => 16, :command => cmd}
end

# Fire up the selection menu
def start(client)
	print "Enter your venue ID (leave empty if you don't know it): "
	venue_id = gets

	if venue_id.strip.empty?
		venue_id = venue_search client
	end
	
	print "Enter your OAuth access token (leave empty if you don't have one): "
	token = gets

	if token.strip.empty?
		token = oauth_token
	end
	
	cronme_betch venue_id, token

	puts "***********************************************************"
	puts "All done! Soon you will become the mayor of venue ##{venue_id}"
	puts "***********************************************************"
end

# Begin Main Routine
client = Foursquare2::Client.new(:client_id => $client_id, :client_secret => $client_secret)

# Legggggo....
start client
