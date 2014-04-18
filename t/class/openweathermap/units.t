use Test::More;
use strict; use warnings FATAL => 'all';

use POEx::Weather::OpenWeatherMap::Units -all;

my $cel = int f_to_c 0;
ok $cel == -17, 'f_to_c ok' or diag $cel;

my $kph = int mph_to_kph 10;
ok $kph == 16, 'mph_to_kph ok';

ok deg_to_compass(0) eq 'N', 'deg_to_compass 0 ok';
ok deg_to_compass(135) eq 'SE', 'deg_to_compass 135 ok';
ok deg_to_compass(360) eq 'N', 'deg_to_compass 360 ok';

done_testing
