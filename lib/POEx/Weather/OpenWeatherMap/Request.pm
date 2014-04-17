package POEx::Weather::OpenWeatherMap::Request;

use v5.10;
use strictures 1;
use Carp;

use Types::Standard -all;
use Types::DateTime -all;

use HTTP::Request;
use URI::Escape 'uri_escape_utf8';

use Module::Runtime 'use_module';


use Moo; use MooX::late;


sub new_for {
  my ($class, $type) = splice @_, 0, 2;
  confess "Expected a subclass type" unless $type;
  my $subclass = $class .'::'. ucfirst($type);
  use_module($subclass)->new(@_)
}


has api_key => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 1,
  builder   => sub { '' },
);


has tag => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 1,
  builder   => sub { '' },
);

has location => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);


has ts => (
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { time },
);

has url => (
  init_arg  => undef,
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->_parse_location_str },
);

has http_request => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['HTTP::Request'],
  builder   => sub {
    my ($self) = @_;
    my $req = HTTP::Request->new( GET => $self->url );
    $req->header( 'x-api-key' => $self->api_key )
      if $self->has_api_key and length $self->api_key;
    $req
  },
);


has _units => (
  required => 1,
  is       => 'ro',
  isa      => Str,
  builder  => sub { 'imperial' },
);


sub _url_bycode {
  my ($self, $code) = @_;
  'http://api.openweathermap.org/data/2.5/weather?id='
    . uri_escape_utf8($code)
    . '&units=' . $self->_units
}

sub _url_bycoord {
  my $self = shift;
  my ($lat, $long) = map {; uri_escape_utf8($_) } @_;
  "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$long"
    . '&units=' . $self->_units
}

sub _url_byname {
  my ($self, @parts) = @_;
  'http://api.openweathermap.org/data/2.5/weather?q='
    . join(',', map {; uri_escape_utf8($_) } @parts)
    . '&units=' . $self->_units
}


sub _parse_location_str {
  my ($self) = @_;

  state $latlong =
    qr{\Alat(?:itude)?\s+?(-?[0-9.]+),?\s+?long?(?:itude)?\s+?(-?[0-9.]+)};

  my $str = $self->location;
  my $url;
  URL: {
    if (is_StrictNum $str) {
      $url = $self->_url_bycode($str);
      last URL
    }

    if (my ($lat, $lon) = $str =~ $latlong) {
      $url = $self->_url_bycoord($lat, $lon);
      last URL
    }

    my @parts = split /,\s+?/, $str;
    $url = $self->_url_byname(@parts);
  }

  $url
}

1;
