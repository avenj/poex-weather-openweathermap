package POEx::Weather::OpenWeatherMap::Request;

use strictures 1;
use v5.10;

use Types::Standard -all;

use URI::Escape 'uri_escape_utf8';

use Moo; use MooX::late;


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

has units => (
  required => 1,
  is       => 'ro',
  isa      => Str,
  builder  => sub { 'imperial' },
);

has ts => (
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { time },
);

has url => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->_parse_location_str },
);


sub _url_bycode {
  my ($self, $code) = @_;
  'http://api.openweathermap.org/data/2.5/weather?id='
    . uri_escape_utf8($code)
    . '&units=' . $self->units
}

sub _url_bycoord {
  my $self = shift;
  my ($lat, $long) = map {; uri_escape_utf8($_) } @_;
  "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$long"
    . '&units=' . $self->units
}

sub _url_byname {
  my ($self, @parts) = @_;
  'http://api.openweathermap.org/data/2.5/weather?q='
    . join(',', map {; uri_escape_utf8($_) } @parts)
    . '&units=' . $self->units
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
