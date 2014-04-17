use Test::More;
use strict; use warnings FATAL => 'all';

use POEx::Weather::OpenWeatherMap::Request;

use Types::Standard -all;

# basics + byname
my $request = POEx::Weather::OpenWeatherMap::Request->new_for(
  Current =>
    api_key  => 'abcde',
    tag      => 'foo',
    location => 'Manchester, NH',
);

isa_ok $request, 'POEx::Weather::OpenWeatherMap::Request::Current';

ok $request->api_key eq 'abcde', 'api_key ok';
ok $request->tag eq 'foo', 'tag ok';
ok $request->location eq 'Manchester, NH', 'location ok';
ok is_StrictNum $request->ts, 'ts ok';
cmp_ok $request->url, 
  'eq',
  'http://api.openweathermap.org/data/2.5/weather?q=Manchester,NH&units=imperial',
  'url ok';

isa_ok $request->http_request, 'HTTP::Request';
ok $request->http_request->header('x-api-key') eq 'abcde', 
  'request header ok';


# bycoord
$request = POEx::Weather::OpenWeatherMap::Request->new_for(
  Current =>
    tag       => 'foo',
    location  => 'lat 42, long 24',
);
cmp_ok $request->url,
  'eq',
  'http://api.openweathermap.org/data/2.5/weather?lat=42&lon=24&units=imperial',
  'url ok (lat/long)';

# bycode
$request = POEx::Weather::OpenWeatherMap::Request->new_for(
  Current =>
    tag       => 'foo',
    location  => 5089178,
);
cmp_ok $request->url,
  'eq',
  'http://api.openweathermap.org/data/2.5/weather?id=5089178&units=imperial',
  'url ok (city code)';

done_testing
