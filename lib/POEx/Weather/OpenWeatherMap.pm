package POEx::Weather::OpenWeatherMap;

use v5.10;
use strictures 1;
use Carp;

use List::Objects::Types -all;
use Types::Standard      -all;

use POE 'Component::Client::HTTP';

use POEx::Weather::OpenWeatherMap::Error;
use POEx::Weather::OpenWeatherMap::Request;
use POEx::Weather::OpenWeatherMap::Result;


use Moo; use MooX::late;
with 'MooX::Role::POE::Emitter';


has api_key => (
  lazy        => 1,
  is          => 'ro',
  isa         => Str,
  predicate   => 1,
  builder     => sub { '' },
);

has _in_shutdown => (
  is          => 'rw',
  isa         => Bool,
  default     => sub { 0 },
);

sub _ua_alias {
  my ($self) = @_;
  $self->alias ? $self->alias . 'UA' : ()
}


sub start {
  my ($self) = @_;
  $self->_in_shutdown(0) if $self->_in_shutdown;
  $self->set_object_states(
    [
      $self => +{
        emitter_started  => 'mxrp_emitter_started',
        emitter_stopped  => 'mxrp_emitter_stopped',

        get_weather        => 'mxrp_get_weather',
        mxrp_http_response => 'mxrp_http_response',
      },

      ( $self->has_object_states ? $self->object_states->all : () ),
    ]
  );
  $self->_start_emitter
}

sub stop {
  my ($self) = @_;
  $self->_in_shutdown(1);
  $self->_shutdown_emitter
}

sub _emit_error {
  my $self = shift;
  my $err = POEx::Weather::OpenWeatherMap::Error->new(@_);
  $self->emit( error => $err );
  $err
}


sub mxrp_emitter_started {
#  my ($kernel, $self) = @_[KERNEL, OBJECT];
}

sub mxrp_emitter_stopped {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->post( $self->_ua_alias => 'shutdown' )
    if $kernel->alias_resolve( $self->_ua_alias );
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

  my $type = $args{forecast} ? 'Forecast' : 'Current';

  my $my_request = POEx::Weather::OpenWeatherMap::Request->new_for(
    $type =>
      ( 
        $self->has_api_key && length $self->api_key ?
          (api_key => $self->api_key) : () 
      ),
      %args
  );

  unless ( $kernel->alias_resolve($self->_ua_alias) ) {
    POE::Component::Client::HTTP->spawn(
      Alias           => $self->_ua_alias,
      FollowRedirects => 2,
    )
  }

  $kernel->post( $self->_ua_alias => request => mxrp_http_response =>
    $my_request->http_request,
    $my_request
  );
}


sub mxrp_http_response {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  return if $self->_in_shutdown;

  my ($http_request, $my_request) = @{ $_[ARG0] };
  my ($http_response)             = @{ $_[ARG1] };

  unless ($http_response->is_success) {
    $self->_emit_error(
      request => $my_request,
      status  => 'HTTP: '.$http_response->status_line,
    );
    return
  }

  state $base = 'POEx::Weather::OpenWeatherMap::Request::';
  my ($type, $event);
  CLASS: {
    if ($my_request->isa($base.'Current')) {
      $type  = 'Current';
      $event = 'weather';
      last CLASS
    }
    
    if ($my_request->isa($base.'Forecast')) {
      $type  = 'Forecast';
      $event = 'forecast';
      last CLASS
    }

    confess "Unknown request type: $my_request"
  } # CLASS

  my $content = $http_response->content;
  my $my_response = POEx::Weather::OpenWeatherMap::Result->new_for(
    $type =>
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

  $self->emit( 
    $event => $my_response 
  );
}

1;


=pod

=head1 NAME

POEx::Weather::OpenWeatherMap - POE-enabled OpenWeatherMap client

=head1 SYNOPSIS

  
  use POE;
  use POEx::Weather::OpenWeatherMap;

  my $api_key = 'foo';

  POE::Session->create(
    package_states => [
      main => [qw/
        _start
        
        pwx_error
        pwx_weather
        pwx_forecast
      /],
    ],
  );

  sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    
    # Create and start emitter:
    my $wx = POEx::Weather::OpenWeatherMap->new(
      api_key      => $api_key,
      event_prefix => 'pwx_',
    );

    $heap->{wx} = $wx;
    $wx->start;
  }

  sub pwx_error {
    my $err = $_[ARG0];
    my $status  = $err->status;
    my $request = $err->request;
    # ... do something with error ...
    warn "Error! ($status)";
  }

  sub pwx_weather {
    my $result = $_[ARG0];

    my $tag = $result->request->tag;

    my $place = $result->name;

    my $tempf = $result->temp_f;
    my $conditions = $result->conditions_verbose;
    # (see POEx::Weather::OpenWeatherMap::Result::Current for a method list)
    # ...
  }

  sub pwx_forecast {
    my $result = $_[ARG0];

    my $place = $result->name;

    my $itr = $result->iter;
    while (my $day = $itr->()) {
      my $date = $day->dt->mdy;
      my $temp_hi = $day->temp_max_f;
      my $temp_lo = $day->temp_min_f;
      # (see POEx::Weather::OpenWeatherMap::Result::Forecast)
      # ...
    }
  }

  POE::Kernel->run;

=head1 DESCRIPTION

A POE-enabled interface to OpenWeatherMap (L<http://www.openweathermap.org>),
providing an object-oriented asynchronous interface to current & forecast
weather conditions for a given city, latitude/longitude, or OpenWeatherMap
city code.

This an event emitter that consumes L<MooX::Role::POE::Emitter>; look there
for documentation on composed methods. See L<http://www.openweathermap.org>
for more on OpenWeatherMap itself.

=head2 ATTRIBUTES

=head3 api_key

Your L<OpenWeatherMap|http://www.openweathermap.org> API key.

(See L<http://www.openweathermap.org/api> to register for free.)

=head2 METHODS

=head3 start

Start our session.

Must be called before events will be received or emitted.

=head3 stop

Stop our session, shutting down the emitter and user agent (which will cancel
pending requests).

=head3 get_weather

  $wx->get_weather(
    # 'location =>' is mandatory.
    #  These are all valid location strings:
    #  By name:
    #   'Manchester, NH'
    #   'London, UK'
    #  By OpenWeatherMap city code:
    #   5089178
    #  By latitude/longitude:
    #   'lat 42, long -71'
    location => 'Manchester, NH',

    # Set 'forecast => 1' to get the forecast,
    # omit or set to false for current weather:
    forecast => 1,

    # If 'forecast' is true, you can specify the number of days to fetch
    # (up to 14):
    days => 3,

    # Optional tag for identifying the response to this request:
    tag  => 'foo',
  );

Request a weather report for the given C<< location => >>.

The location can be a 'City, State' or 'City, Country' string, an
L<OpenWeatherMap|http://www.openweathermap.org/> city code, or a 'lat X, long
Y' string.

Requests the current weather by default (see
L<POEx::Weather::OpenWeatherMap::Request::Current>).

If passed C<< forecast => 1 >>, requests a weather forecast (see
L<POEx::Weather::OpenWeatherMap::Request::Forecast>), in which case C<< days
=> $count >> can be specified (up to 14).

An optional C<< tag => >> can be specified to identify the response when it
comes in.

The request is made asynchronously and a response (or error) emitted when it
is available; see L</EMITTED EVENTS>. There is no useful return value.

=head2 RECEIVED EVENTS

=head3 get_weather

  $poe_kernel->post( $wx->session_id =>
    get_weather =>
      location => 'Manchester, NH',
      tag      => 'foo',
  );

POE interface to the L</get_weather> method (above); see L</METHODS> for usage
details.

=head2 EMITTED EVENTS

=head3 error

Emitted when an error occurs; this may be an internal error, an HTTP error,
or an error reported by the OpenWeatherMap API.

C<$_[ARG0]> is a L<POEx::Weather::OpenWeatherMap::Error> object.

=head3 weather

Emitted when a request for the current weather has been successfully processed.

C<$_[ARG0]> is a L<POEx::Weather::OpenWeatherMap::Result::Current> object; see
that module's documentation for details on retrieving weather information.

=head3 forecast

Emitted when a request for a weather forecast has been successfully processed.

C<$_[ARG0]> is a L<POEx::Weather::OpenWeatherMap::Result::Forecast> object;
see that module's documentation for details on retrieving per-day forecasts
(L<POEx::Weather::OpenWeatherMap::Result::Forecast::Day> objects).

=head2 WITHOUT POE

It's possible to use the Request & Result classes to construct appropriate
HTTP requests & parse JSON responses without POE; this event emitter merely
glues together a L<POE::Component::Client::HTTP> session &
L<POEx::Weather::OpenWeatherMap::Request> /
L<POEx::Weather::OpenWeatherMap::Result> objects.

Any user agent that accepts a L<HTTP::Request> will do; see
C<examples/using_lwp.pl> in this distribution for a simple example.

=head1 SEE ALSO

L<POEx::Weather::OpenWeatherMap::Error>

L<POEx::Weather::OpenWeatherMap::Result>

L<POEx::Weather::OpenWeatherMap::Result::Current>

L<POEx::Weather::OpenWeatherMap::Result::Forecast>

L<POEx::Weather::OpenWeatherMap::Request>

L<POEx::Weather::OpenWeatherMap::Request::Current>

L<POEx::Weather::OpenWeatherMap::Request::Forecast>

L<POEx::Weather::OpenWeatherMap::Request::Forecast::Day>

The C<examples/> directory of this distribution.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
