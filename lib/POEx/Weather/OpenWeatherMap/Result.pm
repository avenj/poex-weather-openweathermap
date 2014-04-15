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
  isa       => HashObj
  builder   => sub {
    my ($self) = @_;
    JSON::Tiny->new->decode( $self->json )
  },
);


has is_success => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  builder   => sub {
    my ($self) = @_;
    my $data = $self->data;
    my $code = $data->{cod} // '';
    $code eq '200'
  },
);

has error => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub {
    my ($self) = @_;
    return if $self->is_success;
    my $data = $self->data;
    $data->{message} || 'Unknown error from backend'
  },
);

1;
