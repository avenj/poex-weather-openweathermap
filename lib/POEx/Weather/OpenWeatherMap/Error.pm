package POEx::Weather::OpenWeatherMap::Error;

use strictures 1;

use Types::Standard -all;

use Moo; use MooX::late;
use overload
  bool => sub { 1 },
  '""' => sub { shift->status },
  fallback => 1;

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
