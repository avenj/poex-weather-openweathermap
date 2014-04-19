package POEx::Weather::OpenWeatherMap::Error;

use strictures 1;
use Carp;

use Types::Standard -all;

use Moo; use MooX::late;
use overload
  bool => sub { 1 },
  '""' => sub { shift->as_string },
  fallback => 1;

has request => (
  required  => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::Weather::OpenWeatherMap::Request'],
);

has source => (
  required  => 1,
  is        => 'ro',
  isa       => sub {
    $_[0] eq 'api' || $_[0] eq 'internal' || $_[0] eq 'http'
  },
);

has status => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

sub as_string {
  my ($self) = @_;
  my $src = uc $self->source;
  my $msg = $self->status;
  "($src) $msg"
}

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

These objects stringify (via L</as_string>).

=head2 ATTRIBUTES

=head3 request

The original L<POEx::Weather::OpenWeatherMap::Request> object that caused the
error to occur.

=head3 source

The source of the error, one of: C<api>, C<internal>, C<http>

=head3 status

The error/status message string.

=head2 METHODS

=head3 as_string

Returns a stringified representation of the error in the form:
C<< (uc $err->source) $err->status >>

=head1 SEE ALSO

L<POEx::Weather::OpenWeatherMap>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
