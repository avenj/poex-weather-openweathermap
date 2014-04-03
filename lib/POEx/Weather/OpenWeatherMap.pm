package POEx::Weather::OpenWeatherMap;

use strictures 1;

use JSON::Tiny;
use Try::Tiny;

use Lowu;   # autoboxed lists
use List::Objects::Types -all;
use Types::Standard      -all;

use HTTP::Request;
use URI::Escape 'uri_escape_utf8';

use POE;
use POE::Component::Client::HTTP;


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


sub query_url_byname {
  my ($self, @parts) = @_;
  uri_escape_utf8 join ',', 
    'http://api.openweathermap.org/data/2.5/weather?q=',
    @parts
}

sub query_url_bycode {
  my ($self, $code) = @_;
  uri_escape_utf8 join '', 
    'api.openweathermap.org/data/2.5/weather?id=',
    $code
}

sub query_url_bycoord {
  my ($self, $lat, $long) = @_;
  uri_escape_utf8
    "api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$long"
}


sub start {
  my ($self) = @_;
  $self->set_object_states(
    [
      $self => +{
        'emitter_started'  => 'mxrp_emitter_started',
        'emitter_stopped'  => 'mxrp_emitter_stopped',

        'get_weather'      => 'mxrp_get_weather',
        'http_response'    => 'mxrp_response',

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

  my $my_request = +{
    tag       => $args{tag},
    location  => $args{location},
    ts        => time,
  }->inflate;

  # FIXME caching

  $kernel->post( $self->ua_alias => request => http_response =>
    $self->_prepare_request($my_request),
    $my_request
  );
}

sub _prepare_request {
  my ($self, $my_request) = @_;

  my $str = $my_request->location;

  my $url;
  URL: {
    if (is_Int $str) {
      # Try for city ID
      last URL
    }

    # FIXME  lat/long syntax?
    # FIXME else assume city name search
  }
  # FIXME parse $str, prepare appropriate HTTP::Request
  # FIXME add x-api-key header
  # FIXME return request obj for UA

  my $req = HTTP::Request->new(GET => $url);
  $req->header( 'x-api-key' => $self->api_key );

  $req
}

sub mxrp_response {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  my ($http_request, $my_request) = @{ $_[ARG0] };
  my ($http_response)             = @{ $_[ARG1] };

  unless ($http_response->is_success) {
    # FIXME ->emit an error
    return
  }
  my $content = $http_response->content;
  my $data = $self->_decode_response($content, $my_request);
  return unless $data;

  # FIXME _decode_response & emit weather_response
  # FIXME caching
}

sub _decode_response {
  my ($self, $raw, $my_request) = @_;
  # FIXME try{} to decode JSON
  # else ->emit an error 
}

1;

# vim: ts=2 sw=2 et sts=2 ft=perl
