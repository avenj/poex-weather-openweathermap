package POEx::Weather::OpenWeatherMap;

use Carp;
use strictures 1;
use feature 'state';

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

has units => (
  lazy        => 1,
  is          => 'ro',
  writer      => 'set_units',
  isa         => Str,
  builder     => sub { 'imperial' },
);

sub ua_alias {
  my ($self) = @_;
  $self->alias ? $self->alias . 'UA' : ()
}


sub query_url_byname {
  my ($self, @parts) = @_;
  'http://api.openweathermap.org/data/2.5/weather?q='
    . join(',', map {; uri_escape_utf8($_) } @parts)
    . '&units=' . $self->units
}

sub query_url_bycode {
  my ($self, $code) = @_;
  'http://api.openweathermap.org/data/2.5/weather?id='
    . uri_escape_utf8($code)
    . '&units=' . $self->units
}

sub query_url_bycoord {
  my $self = shift;
  my ($lat, $long) = map {; uri_escape_utf8($_) } @_;
  "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$long"
    . '&units=' . $self->units
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
    warn "Expected 'location =>' parameter in get_weather request\n";
    $self->emit( error => +{
        request => 
          +{ tag => $args{tag}, location => undef, ts => time }->inflate,
        status  => "Missing 'location =>' in query",
      }->inflate
    );
    return
  }

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

  state $latlong = 
    qr{\Alat(?:itude)?\s+?(-?[0-9.]+),?\s+?long?(?:itude)?\s+?(-?[0-9.]+)};

  my $url;
  URL: {
    if (is_StrictNum $str) {
      $url = $self->query_url_bycode($str);
      last URL
    }

    if (my ($lat, $lon) = $str =~ $latlong) {
      $url = $self->query_url_bycoord($lat, $lon);
      last URL
    }

    my @parts = split /,\s+?/, $str;
    $url = $self->query_url_byname(@parts);
  }

  my $req = HTTP::Request->new( GET => $url );
  $req->header( 'x-api-key' => $self->api_key );

  $req
}

sub mxrp_response {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  my ($http_request, $my_request) = @{ $_[ARG0] };
  my ($http_response)             = @{ $_[ARG1] };

  unless ($http_response->is_success) {
    my $err = +{
      request => $my_request,
      status  => 'HTTP: '.$http_response->status_line,
    }->inflate;
    $self->emit( error => $err );
    return
  }
  my $content = $http_response->content;
  my $data = $self->_decode_response($content, $my_request);
  return unless $data;

  unless ( (my $code = $data->{cod} // '') eq '200') {
    my $msg = $data->{message} || 'Unknown error';
    $self->emit( error => +{
        request => $my_request,
        status  => "OpenWeatherMap: $code: $msg",
      }->inflate
    );
    return
  }

  ## FIXME
  ## http://bugs.openweathermap.org/projects/api/wiki/Weather_Data
  ##   try to add some sanity wrt optional values

  my $my_response = +{
    request => $my_request,
    weather => $data,
    json    => $content,
  }->inflate;

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
