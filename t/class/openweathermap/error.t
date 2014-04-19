use Test::More;
use strict; use warnings FATAL => 'all';

use POEx::Weather::OpenWeatherMap::Request;
use POEx::Weather::OpenWeatherMap::Error;

my $req = POEx::Weather::OpenWeatherMap::Request->new_for(
  Current =>
    location => 'foo',
    tag      => 'bar',
);

my $err = POEx::Weather::OpenWeatherMap::Error->new(
  request => $req,
  source  => 'http',
  status  => 'died, zomg!',
);

ok $err->status eq 'died, zomg!', 'status ok';
ok $err->source eq 'http', 'source ok';
ok $err->request == $req, 'request ok';

cmp_ok $err, 'eq', '(HTTP) died, zomg!', 'stringify ok';

done_testing
