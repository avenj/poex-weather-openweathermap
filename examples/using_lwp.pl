#!/usr/bin/env perl
use strictures 1;

# Look Ma, no POE:

my $location = shift(@ARGV);
unless (defined $location && length $location) {
  die "Usage: $0 <LOCATION> [API_KEY]\n"
}
my $api_key = shift(@ARGV);
unless (defined $api_key && length $api_key) {
  warn "Warning; no API key specified, trying without . . .\n"
}

use LWP::UserAgent;

use POEx::Weather::OpenWeatherMap::Request;
use POEx::Weather::OpenWeatherMap::Result;

my $request = POEx::Weather::OpenWeatherMap::Request->new_for(
  Current => 
    location => $location,
    ( 
      $api_key ? (api_key => $api_key) : () 
    ),
);

my $response = LWP::UserAgent->new->request( $request->http_request );
die $response->status_line unless $response->is_success;

my $result = POEx::Weather::OpenWeatherMap::Result->new_for(
  Current =>
    request => $request,
    json    => $response->content,
);

die $result->error unless $result->is_success;

my $place = $result->name;
my $temp  = $result->temp_f;
my $wind  = $result->wind_speed_mph;
my $dir   = $result->wind_direction;

print "$place -> ${temp}F, wind ${wind}mph ($dir)\n";



