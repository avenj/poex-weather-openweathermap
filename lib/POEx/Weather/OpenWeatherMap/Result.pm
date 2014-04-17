package POEx::Weather::OpenWeatherMap::Result;

use Carp;
use strictures 1;

use JSON::Tiny;

use Module::Runtime 'use_module';
use List::Objects::Types -all;
use Types::Standard      -all;


use Moo; use MooX::late;

sub new_for {
  my ($class, $type) = splice @_, 0, 2;
  confess "Expected a subclass type" unless $type;
  my $subclass = $class .'::'. ucfirst($type);
  use_module($subclass)->new(@_)
}


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
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  builder   => sub {
    my ($self) = @_;
    JSON::Tiny->new->decode( $self->json )
  },
);

has response_code => (
  lazy      => 1,
  is        => 'ro',
  isa       => Maybe[Int],
  builder   => sub {
    my ($self) = @_;
    $self->data->{cod}
  },
);


has is_success => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  builder   => sub {
    my ($self) = @_;
    ($self->response_code // '') eq '200'
  },
);

has error => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub {
    my ($self) = @_;
    return '' if $self->is_success;
    my $data = $self->data;
    my $msg = $data->{message} || 'Unknown error from backend';
    # there's only so much I can take ->
    $msg = 'Not found' if $msg eq 'Not found city';
    $msg
  },
);

1;

=pod

=head1 NAME

POEx::Weather::OpenWeatherMap::Result - Weather lookup result superclass

=head1 SYNOPSIS

  # Normally retrieved via POEx::Weather::OpenWeatherMap;
  # subscribed sessions receive a subclass of this class:
  sub my_weather_event {
    my $result = $_[ARG0];
    # ...
  }

=head1 DESCRIPTION

This is the base class for L<POEx::Weather::OpenWeatherMap> weather results.

Also see L<POEx::Weather::OpenWeatherMap::Result::Current> and
L<POEx::Weather::OpenWeatherMap::Result::Forecast>.

=head2 data

This is the decoded hash from the attached L</json>. 

Subclasses provide more convenient accessors for retrieving desired
information.

=head2 error

The error message received from the OpenWeatherMap backend (or the empty
string if there was no error).

Also see L</is_success>, L</response_code>

=head2 is_success

Returns boolean true if the OpenWeatherMap backend returned a successful
response.

Also see L</error>, L</response_code>

=head2 json

The raw JSON this Result was created with.

=head2 response_code

The response code from OpenWeatherMap.

Also see L</is_success>, L</error>

=head2 request

The original request that was attached to this result.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as perl.

=cut
