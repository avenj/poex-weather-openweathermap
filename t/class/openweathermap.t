use Test::More;
use strict; use warnings FATAL => 'all';

use lib 't/inc';
use OWMTestUtil;

use POE;
use POEx::Weather::OpenWeatherMap;

{ no strict 'refs';
  *{ 'POEx::Weather::OpenWeatherMap::_issue_http_request' } = sub {
    my ($self, $request) = @_;
    # FIXME 
    #  post request to mock http client session
    #  post back appropriate mock data for $request type
    #  shove mock client in t/inc ?
  };
}

# FIXME POE session tests

done_testing
