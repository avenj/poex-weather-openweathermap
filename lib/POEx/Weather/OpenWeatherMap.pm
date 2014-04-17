package POEx::Weather::OpenWeatherMap;

use Carp;
use strictures 1;
use feature 'state';

use Try::Tiny;

use List::Objects::Types -all;
use Types::Standard      -all;

use POE;
use POE::Component::Client::HTTP;


use POEx::Weather::OpenWeatherMap::Error;
use POEx::Weather::OpenWeatherMap::Request;
use POEx::Weather::OpenWeatherMap::Result;


use Moo; use MooX::late;
with 'MooX::Role::POE::Emitter';


has api_key => (
  lazy        => 1,
  is          => 'ro',
  isa         => Str,
  writer      => 'set_api_key',
  predicate   => 1,
  builder     => sub { '' },
);

sub ua_alias {
  my ($self) = @_;
  $self->alias ? $self->alias . 'UA' : ()
}


sub start {
  my ($self) = @_;
  $self->set_object_states(
    [
      $self => +{
        emitter_started  => 'mxrp_emitter_started',
        emitter_stopped  => 'mxrp_emitter_stopped',

        get_weather        => 'mxrp_get_weather',
        mxrp_http_response => 'mxrp_http_response',

        # FIXME cache check/expiry timer
      },

      ( $self->has_object_states ? $self->object_states->all : () ),
    ]
  );
  $self->_start_emitter
}

sub stop {
  my ($self) = @_;
  $self->_shutdown_emitter
}

sub _emit_error {
  my $self = shift;
  my $err = POEx::Weather::OpenWeatherMap::Error->new(@_);
  $self->emit( error => $err );
  $err
}


sub mxrp_emitter_started {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  POE::Component::Client::HTTP->spawn(
    Alias           => $self->ua_alias,
    FollowRedirects => 2,
  )
}

sub mxrp_emitter_stopped {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->post( $self->ua_alias => 'shutdown' );
}

sub get_weather {
  my $self = shift;
  $self->yield(get_weather => @_)
}

sub mxrp_get_weather {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my %args = @_[ARG0 .. $#_];

  unless ($args{location}) {
    warn "Missing 'location =>' in query\n";
    my $fake_req = POEx::Weather::OpenWeatherMap::Request->new_for(
      Current =>
        tag      => $args{tag},
        location => '',
    );
    $self->_emit_error(
      request => $fake_req,
      status  => "Missing 'location =>' in query",
    );
    return
  }

  my $my_request = POEx::Weather::OpenWeatherMap::Request->new_for(
    Current =>
      ( length $self->api_key ? (api_key => $self->api_key) : () ),
      %args
  );

  # FIXME cache retrieval

  $kernel->post( $self->ua_alias => request => mxrp_http_response =>
    $my_request->http_request,
    $my_request
  );
}


sub mxrp_http_response {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  ## FIXME handle forecast or regular resp
  ##  dispatch to appropriate response handler

  my ($http_request, $my_request) = @{ $_[ARG0] };
  my ($http_response)             = @{ $_[ARG1] };

  unless ($http_response->is_success) {
    $self->_emit_error(
      request => $my_request,
      status  => 'HTTP: '.$http_response->status_line,
    );
    return
  }

  my $content = $http_response->content;
  my $my_response = POEx::Weather::OpenWeatherMap::Result->new_for(
    Current =>
      request => $my_request,
      json    => $content,
  );
  
  unless ($my_response->is_success) {
    my $code = $my_response->response_code;
    $self->_emit_error(
      request => $my_request,
      status  => "OpenWeatherMap: $code: ".$my_response->error,
    );
    return
  }

  $self->emit( weather => $my_response );
  # FIXME cache response
}

1;

# vim: ts=2 sw=2 et sts=2 ft=perl
