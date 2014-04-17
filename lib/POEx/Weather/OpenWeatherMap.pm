package POEx::Weather::OpenWeatherMap;

use Carp;
use strictures 1;
use feature 'state';

use Try::Tiny;

use Lowu;   # autoboxed lists
use List::Objects::Types -all;
use Types::Standard      -all;

use HTTP::Request;

use POE;
use POE::Component::Client::HTTP;


use POEx::Weather::OpenWeatherMap::Error;
use POEx::Weather::OpenWeatherMap::Request;
use POEx::Weather::OpenWeatherMap::Result;


use Moo; use MooX::late;
with 'MooX::Role::POE::Emitter';


has api_key => (
  required    => 1,
  is          => 'ro',
  isa         => Str,
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

        get_weather      => 'mxrp_get_weather',
        http_response    => 'mxrp_response',

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
  my ($self, %args) = @_;
  $args{request} = $args{request}->inflate if is_HashRef($args{request});
  $self->emit( error => 
    POEx::Weather::OpenWeatherMap::Error->new(%args)
  )
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
    my $fake_req = POEx::Weather::OpenWeatherMap::Request->new(
      tag      => $args{tag},
      location => '',
    );
    $self->_emit_error(
      request => $fake_req,
      status  => "Missing 'location =>' in query",
    );
    return
  }

  # FIXME request objs should be for current or forecast (subclasses?)

  my $my_request = POEx::Weather::OpenWeatherMap::Request->new(%args);

  # FIXME caching

  $kernel->post( $self->ua_alias => request => http_response =>
    $self->_prepare_http_request($my_request),
    $my_request
  );
}


sub _prepare_http_request {
  my ($self, $my_request) = @_;

  my $req = HTTP::Request->new( GET => $my_request->url );
  $req->header( 'x-api-key' => $self->api_key );

  $req
}

sub mxrp_response {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  ## FIXME OO API

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
  my $my_response = POEx::Weather::OpenWeatherMap::Result->new(
    request => $my_request,
    json    => $content,
  );
  
  unless ($my_response->is_success) {
    $self->_emit_error(
      request => $my_request,
      status  => "OpenWeatherMap: $code: ".$my_response->error,
    );
    return
  }

  ## FIXME
  ## http://bugs.openweathermap.org/projects/api/wiki/Weather_Data
  ##   try to add some sanity wrt optional values
  ##   maybe an actual class for these:

  $self->emit( weather => $my_response );
  # FIXME cache response
}

sub _decode_response {
  my ($self, $raw, $my_request) = @_;

  my $data = try { JSON::Tiny->new->decode($raw) } catch {
    my $err = +{
      request => $my_request,
      status  => 'JSON: '.$_,
    }->inflate;
    $self->emit( error => $err );
    undef
  } or return;

  $data
}

1;

# vim: ts=2 sw=2 et sts=2 ft=perl
