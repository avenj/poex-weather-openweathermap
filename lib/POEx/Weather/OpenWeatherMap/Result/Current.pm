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


sub lazy_for {
  my $type = shift;
  ( lazy => 1, is => 'ro', isa => $type, coerce => 1, @_ )
}


use Moo; use MooX::late;
extends 'POEx::Weather::OpenWeatherMap::Result';


has dt => ( lazy_for DateTimeUTC,
  builder   => sub { shift->data->{dt} },
);

has id   => ( lazy_for Int,
  builder   => sub { shift->data->{id} },
);

has name => ( lazy_for Str,
  builder   => sub { shift->data->{name} },
);

has country => ( lazy_for Str,
  builder   => sub { shift->data->{sys}->{country} // '' },
);

has station => ( lazy_for Str,
  builder   => sub { shift->data->{base} // '' },
);


has latitude => ( lazy_for StrictNum,
  builder   => sub { shift->data->{coord}->{lat} },
);

has longitude => ( lazy_for StrictNum,
  builder   => sub { shift->data->{coord}->{lon} },
);


has temp_f => ( lazy_for Int,
  builder   => sub { int( shift->data->{main}->{temp} ) },
);

has temp_c => ( lazy_for Int,
  builder   => sub { int f_to_c( shift->temp_f ) },
);


has humidity => ( lazy_for Int,
  builder   => sub { int( shift->data->{main}->{humidity} // 0 ) },
);

has pressure => ( lazy_for StrictNum,
  builder   => sub { shift->data->{main}->{pressure} },
);

has cloud_coverage => ( lazy_for Int,
  builder   => sub { int( shift->data->{clouds}->{all} // 0 ) },
);


has sunrise => ( lazy_for DateTimeUTC,
  builder   => sub { shift->data->{sys}->{sunrise} // 0 },
);

has sunset => ( lazy_for DateTimeUTC,
  builder   => sub { shift->data->{sys}->{sunset} // 0 },
);


sub _so_weather_maybe {
  my ($self) = @_;
  my $weather = $self->data->{weather};
  return unless ref $weather eq 'ARRAY' and @$weather;
  $weather->[0]
}

has conditions_terse => ( lazy_for Str,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return '';
    $weather->{main} // ''
  },
);

has conditions_description => ( lazy_for Str,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return '';
    $weather->{description} // ''
  },
);

has conditions_code => ( lazy_for Int,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return 0;
    $weather->{id} // 0
  },
);

has conditions_icon => ( lazy_for Maybe[Str],
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return;
    $weather->{icon}
  },
);


has wind_speed => ( lazy_for Int,
  builder   => sub { int( shift->data->{wind}->{speed} // 0 ) },
);

has wind_speed_kph => ( lazy_for Int,
  builder   => sub { int( mph_to_kph shift->wind_speed ) },
);

has wind_direction_degrees => ( lazy_for StrictNum,
  builder   => sub { shift->data->{wind}->{deg} // 0 },
);

has wind_direction => ( lazy_for Str,
  builder   => sub { deg_to_compass( shift->wind_direction_degrees ) },
);

has wind_gust => ( lazy_for Int,
  builder   => sub {
    my ($self) = @_;
    my $gust = int( $self->data->{wind}->{gust} // 0 );
    return 0 unless $gust and $gust ne $self->wind_speed;
    $gust
  },
);

has wind_gust_kph => ( lazy_for Int,
  builder   => sub { int( mph_to_kph shift->wind_gust ) },
);



1;
