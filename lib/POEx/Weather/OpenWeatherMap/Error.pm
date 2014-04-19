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

=pod

=head1 NAME

POEx::Weather::OpenWeatherMap::Error

=head1 SYNOPSIS

  # Usually received from POEx::Weather::OpenWeatherMap

=head1 DESCRIPTION

These objects contain information on internal or backend (API) errors; they
are generally emitted to subscribed sessions by
L<POEx::Weather::OpenWeatherMap> in response to a failed request.

These objects stringify to the contents of the L</status> attribute.

=head2 ATTRIBUTES

=head3 request

The original L<POEx::Weather::OpenWeatherMap::Request> object that caused the
error to occur.

=head3 status

The error/status message string.

=head1 SEE ALSO

L<POEx::Weather::OpenWeatherMap>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
