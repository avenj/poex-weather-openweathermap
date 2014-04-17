package POEx::Weather::OpenWeatherMap::Result::Current;

use strictures 1;
use Carp;

use List::Objects::Types -all;
use Types::Standard      -all;
use Types::DateTime      -all;

use POEx::Weather::OpenWeatherMap::Units qw/
  f_to_c
  mph_to_kph
  deg_to_compass
/;


use Moo; use MooX::late;
extends 'POEx::Weather::OpenWeatherMap::Result';


has dt => (
  lazy      => 1,
  is        => 'ro',
  isa       => DateTimeUTC,
  builder   => sub { shift->data->{dt} },
);

has id   => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { shift->data->{id} },
);

has name => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->data->{name} },
);

has country => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->data->{sys}->{country} // '' },
);

has station => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->data->{base} // '' },
);


has latitude => (
  lazy      => 1,
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { shift->data->{coord}->{lat} },
);

has longitude => (
  lazy      => 1,
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { shift->data->{coord}->{lon} },
);


has temp_f => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { int( shift->data->{main}->{temp} ) },
);

has temp_c => (
  lazy      => 1,
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { f_to_c( shift->temp_f ) },
);


has humidity => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { int( shift->data->{main}->{humidity} // 0 ) },
);

has pressure => (
  lazy      => 1,
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { shift->data->{main}->{pressure} },
);

has cloud_coverage => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { int( shift->data->{clouds}->{all} // 0 ) },
);


has sunrise => (
  lazy      => 1,
  is        => 'ro',
  isa       => DateTimeUTC,
  builder   => sub { shift->data->{sys}->{sunrise} // 0 },
);

has sunset => (
  lazy      => 1,
  is        => 'ro',
  isa       => DateTimeUTC,
  builder   => sub { shift->data->{sys}->{sunset} // 0 },
);


sub _so_weather_maybe {
  my ($self) = @_;
  my $weather = $self->data->{weather};
  return unless ref $weather eq 'ARRAY' and @$weather;
  $weather->[0]
}

has conditions_terse => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return '';
    $weather->{main} // ''
  },
);

has conditions_description => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return '';
    $weather->{description} // ''
  },
);

has conditions_code => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return 0;
    $weather->{id} // 0
  },
);

has conditions_icon => (
  lazy      => 1,
  is        => 'ro',
  isa       => Maybe[Str],
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return;
    $weather->{icon}
  },
);


has wind_speed => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { int( shift->data->{wind}->{speed} // 0 ) },
);

has wind_speed_kph => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { int( mph_to_kph shift->wind_speed ) },
);

has wind_direction_degrees => (
  lazy      => 1,
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { shift->data->{wind}->{deg} // 0 },
);

has wind_direction => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { deg_to_compass( shift->wind_direction_degrees ) },
);

has wind_gust => (
  lazy      => 1,
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub {
    my ($self) = @_;
    my $gust = $self->data->{wind}->{gust};
    return 0 unless $gust and $gust ne $self->wind_speed;
  },
);

has wind_gust_kph => (
  lazy      => 1,
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { int( mph_to_kph shift->wind_gust ) },
);



1;
