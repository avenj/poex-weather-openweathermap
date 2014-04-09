package POEx::Weather::OpenWeatherMap::Result;

use strictures 1;

use List::Objects::Types -all;
use Types::Standard      -all;


use Moo; use MooX::late;

has request => (
  required  => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::Weather::OpenWeatherMap::Request'],
);

has json => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

has data => (
  lazy      => 1,
  isa       => HashObj
  builder   => sub {
    # FIXME build from ->json
  },
  #  then provide more useful accessors to munge $self->data
);

1;
