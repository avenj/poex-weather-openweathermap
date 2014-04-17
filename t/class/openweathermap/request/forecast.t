use Test::More;
use strict; use warnings FATAL => 'all';

use POEx::Weather::OpenWeatherMap::Request;

use Types::Standard -all;

# byname
my $request = POEx::Weather::OpenWeatherMap::Request->new_for(
  Forecast =>
    api_key  => 'abcde',
    tag      => 'foo',
    location => 'Manchester, NH',
);

ok $request->days == 7, 'default days ok';

cmp_ok $request->url, 
  'eq',
  'http://api.openweathermap.org/data/2.5/forecast/'
    .'daily?q=Manchester,NH&units=imperial&cnt=7',
  'url ok';

# bycoord
$request = POEx::Weather::OpenWeatherMap::Request->new_for(
  Forecast =>
    tag       => 'foo',
    location  => 'lat 42, long 24',
);
cmp_ok $request->url,
  'eq',
  'http://api.openweathermap.org/data/2.5/forecast/'
    .'daily?lat=42&lon=24&units=imperial&cnt=7',
  'url ok (lat/long)';

# bycode
$request = POEx::Weather::OpenWeatherMap::Request->new_for(
  Forecast =>
    tag       => 'foo',
    location  => 5089178,
);
cmp_ok $request->url,
  'eq',
  'http://api.openweathermap.org/data/2.5/forecast/'
    .'daily?id=5089178&units=imperial&cnt=7',
  'url ok (city code)';

done_testing
