package POEx::Weather::OpenWeatherMap::Result::Forecast::Day;

use strictures 1;

use Types::Standard       -all;
use Types::DateTime       -all;
use List::Objects::Types  -all;

use POEx::Weather::OpenWeatherMap::Units -all;

use Moo; use MooX::late;

my $CoercedInt = Int->plus_coercions(StrictNum, sub { int });

has dt => (
  is        => 'ro',
  isa       => DateTimeUTC,
  coerce    => 1,
  builder   => sub { 0 },
);

has pressure => (
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { 0 },
);

has humidity => (
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { 0 },
);

has cloud_coverage => (
  init_arg  => 'clouds',
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { 0 },
);


has wind_speed_mph => (
  init_arg  => 'speed',
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { 0 },
);

has wind_speed_kph => (
  lazy      => 1,
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { f_to_c shift->wind_speed_mph },
);

has wind_direction => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { deg_to_compass shift->wind_direction_degrees },
);

has wind_direction_degrees => (
  init_arg  => 'deg',
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { 0 },
);

{ package
    POEx::Weather::OpenWeatherMap::Result::Forecast::Day::Temps;
  use strict; use warnings FATAL => 'all';
  use Moo;
  has [qw/ morn night eve min max day /], 
    ( is => 'ro', default => sub { 0 } );
}

has temp => (
  is        => 'ro',
  isa       => (InstanceOf[__PACKAGE__.'::Temps'])
    ->plus_coercions( HashRef,
      sub { 
        POEx::Weather::OpenWeatherMap::Result::Forecast::Day::Temps->new(%$_)
      },
  ),
  coerce    => 1,
  builder   => sub {
    POEx::Weather::OpenWeatherMap::Result::Forecast::Day::Temps->new
  },
);

has temp_min_f => (
  lazy      => 1,
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { shift->temp->min },
);

has temp_max_f => (
  lazy      => 1,
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { shift->temp->max },
);

has temp_min_c => (
  lazy      => 1,
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { f_to_c shift->temp_min_f },
);

has temp_max_c => (
  lazy      => 1,
  is        => 'ro',
  isa       => $CoercedInt,
  coerce    => 1,
  builder   => sub { f_to_c shift->temp_max_f },
);



has _weather_list => (
  init_arg  => 'weather',
  is        => 'ro',
  isa       => ArrayObj,
  coerce    => 1,
  builder   => sub { [] },
);

has _first_weather_item => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashRef,
  builder   => sub { shift->_weather_list->[0] || +{} },
);

has conditions_terse => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->_first_weather_item->{main} // '' },
);

has conditions_verbose => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->_first_weather_item->{description} // '' },
);

has conditions_code => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { shift->_first_weather_item->{id} // 0 },
);

has conditions_icon => (
  lazy      => 1,
  is        => 'ro',
  isa       => Maybe[Str],
  builder   => sub { shift->_first_weather_item->{icon} },
);



1;

=pod

=head1 NAME

POEx::Weather::OpenWeatherMap::Result::Forecast::Day

=head1 SYNOPSIS

  # Usually retrived via a POEx::Weather::OpenWeatherMap::Result::Forecast

=head1 DESCRIPTION

A L<POEx::Weather::OpenWeatherMap> weather forecast for a single day.

=head2 ATTRIBUTES

=head3 Conditions

=head4 cloud_coverage

The forecast cloud coverage, as a percentage.

=head4 conditions_terse

The conditions category.

=head4 conditions_verbose

The conditions description string.

=head4 conditions_code

The L<OpenWeatherMap|http://www.openweathermap.org/> conditions code.

=head4 conditions_icon

The L<OpenWeatherMap|http://www.openweathermap.org/> conditions icon.

=head4 dt

  my $date = $result->dt->mdy;

A L<DateTime> object coerced from the timestamp attached to this forecast.

=head4 humidity

The forecast humidity, as a percentage.

=head4 pressure

The forecast atmospheric pressure, in hPa.

=head3 Temperature

=head4 temp

An object containing the returned temperature data; this object provides
B<morn>, B<night>, B<eve>, B<min>, B<max>, B<day> accessors.

See L</temp_min_f>, L</temp_max_f>.

=head4 temp_min_f

The forecast low temperature, in degrees Fahrenheit.

=head4 temp_max_f

The forecast high temperature, in degrees Fahrenheit.

=head4 temp_min_c

The forecast low temperature, in degrees Celsius.

=head4 temp_max_c

The forecast high temperature, in degrees Celsius.

=head3 Wind

=head4 wind_speed_mph

The forecast wind speed, in MPH.

=head4 wind_speed_kph

The forecast wind speed, in KPH.

=head4 wind_direction

The forecast wind direction, as a (inter-)cardinal direction in the set
C<< [ N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW ] >>

=head4 wind_direction_degrees

The forecast wind direction, in degrees azimuth.

=head1 SEE ALSO

L<http://www.openweathermap.org>

L<POEx::Weather::OpenWeatherMap>

L<POEx::Weather::OpenWeatherMap::Result>

L<POEx::Weather::OpenWeatherMap::Result::Forecast>

L<POEx::Weather::OpenWeatherMap::Result::Current>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
