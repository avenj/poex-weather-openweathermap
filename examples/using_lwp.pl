#!/usr/bin/env perl

use strictures 1;

use LWP::UserAgent;

use POEx::Weather::OpenWeatherMap::Request;
use POEx::Weather::OpenWeatherMap::Result;

my $location = shift(@ARGV) || 'Manchester, NH';

my $request = POEx::Weather::OpenWeatherMap::Request->new_for(
  Current => 
    location => $location,
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



