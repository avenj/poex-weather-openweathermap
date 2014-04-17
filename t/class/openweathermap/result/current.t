use Test::More;
use strict; use warnings FATAL => 'all';

use lib 't/inc';
use OWMTestUtil;

use POEx::Weather::OpenWeatherMap::Request;
use POEx::Weather::OpenWeatherMap::Result;


my $req = POEx::Weather::OpenWeatherMap::Request->new_for(
  Current =>
    api_key  => 'abcd',
    tag      => 'foo',
    location => 'Manchester, NH',
);

my $mockjson = get_test_data('current');

my $res = POEx::Weather::OpenWeatherMap::Result->new_for(
  Current =>
    request => $req,
    json    => $mockjson,
);

# parent class:
ok !$res->data->is_empty,         'data hash has keys';
ok !$res->error,                  'error ok';
ok $res->is_success,              'is_success ok';
ok $res->json eq $mockjson,       'json ok';

ok $res->response_code eq '200',  'response_code ok';
ok $res->request == $req,         'request ok';

# us:
isa_ok $res->dt, 'DateTime';
ok $res->dt->epoch == 1397768668, 'dt ok';

ok $res->id eq '5089178', 'id ok';
ok $res->name eq 'Manchester', 'name ok';
ok $res->country eq 'United States of America', 'country ok';
ok $res->station eq 'cmc stations', 'station ok';

ok $res->latitude eq '42.99', 'latitude ok';
ok $res->longitude eq '-71.46', 'longitude ok';

ok $res->temp_f == 41, 'temp_f ok';
ok $res->temp_c == 5,  'temp_c ok';

ok $res->humidity == 49, 'humidity ok';
ok $res->pressure eq 1040, 'pressure ok';

ok $res->cloud_coverage == 8, 'cloud_coverage ok';

isa_ok $res->sunrise, 'DateTime';
ok $res->sunrise->epoch == 1397728770, 'sunrise ok';
isa_ok $res->sunset, 'DateTime';
ok $res->sunset->epoch == 1397777462, 'sunset ok';

ok $res->conditions_terse eq 'Rain', 'conditions_terse ok';
ok $res->conditions_verbose eq 'light rain', 'conditions_verbose ok';
ok $res->conditions_code == 500, 'conditions_code ok';
ok $res->conditions_icon eq '10d', 'conditions_icon ok';

ok $res->wind_speed_mph == 2, 'wind_speed_mph ok';
ok $res->wind_speed_kph == 3, 'wind_speed_kph ok';
ok $res->wind_gust_mph == 6, 'wind_gust_mph ok';
ok $res->wind_gust_kph == 9, 'wind_gust_kph ok';

ok $res->wind_direction_degrees == 59, 'wind_direction_degrees ok';
ok $res->wind_direction eq 'ENE', 'wind_direction ok';


## FIXME need some failure data to test


done_testing
