package POEx::Weather::OpenWeatherMap::Error;

use strictures 1;

use Types::Standard -all;

use Moo; use MooX::late;

## FIXME stringy overload?
## FIXME separate 'phase' or whatever

has request => (
  required  => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::Weather::OpenWeatherMap::Request'],
);

has status => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

1;
