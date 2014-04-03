#!/usr/bin/env perl

use Carp;
use strictures 1;
use 5.10.0;

use List::Objects::WithUtils;
use List::Objects::Types -all;

use IRC::Toolkit;

use POE;
use POEx::Weather::OpenWeatherMap;
use POEx::IRC::Client::Lite;


use Getopt::Long;
my $Opts = +{
  nickname => 'Aurae',
  username => 'aurae',
  server   => undef,
  api_key  => undef,
  channels => '',
  cmd      => '.wx',
};
GetOptions( $Opts,
  'nickname=s',
  'username=s',
  'server=s',
  'api_key=s',
  'channels=s',
  'cmd=s',
);

sub getopts { 
  unless (is_ArrayObj $Opts->{channels}) {
    $Opts->{channels} = array(split /,/, $Opts->{channels})
  }
  state $argv = hash(%$Opts)->inflate 
}


POE::Session->create(
  package_states => [
    main => [qw/
      _start

      pxi_irc_001
      pxi_irc_public_msg
      
      pwx_error
      pwx_weather
    /],
  ],
);

sub _start {
  $_[HEAP]->{irc} = POEx::IRC::Client::Lite->new(
    event_prefix => 'pxi_',
    server   => getopts->server,
    nick     => getopts->nickname,
    username => getopts->username,
  );
  $_[HEAP]->{irc}->connect;

  $_[HEAP]->{wx} = POEx::Weather::OpenWeatherMap->new(
    event_prefix => 'pwx_',
    api_key => getopts->api_key,
  );
  $_[HEAP]->{wx}->start;
}



sub pxi_irc_001 {
  $_[HEAP]->{irc}->join( getopts->channels->all )
}

sub pxi_irc_public_msg {
  my $event = $_[ARG0];
  my ($target, $string) = @{ $event->params };
  
  my $cmd = getopts->cmd;
  if ( index($string, "$cmd ") == 0 ) {
    my $location = substr $string, length("$cmd ");

    $_[HEAP]->{wx}->get_weather(
      location => $location,
      tag      => $target,
    );
  }
}


sub pwx_error {
  my $res = $_[ARG0];

  my $status = $res->status;
  my $req    = $res->request;

  if ($req->{tag}) {
    my $chan = $req->{tag};
    $_[HEAP]->{irc}->privmsg($chan => "Err: $status");
  }
  carp $status;
}

sub pwx_weather {
  my $res = $_[ARG0];

  my $data = $res->weather;
  my $req  = $res->request;

  my $place = $data->{name};
  
  my $main = $data->{main};
  my $temp = int $main->{temp};
  my $temp_lo = int $main->{temp_min};
  my $temp_hi = int $main->{temp_max};
  my $humid   = $main->{humidity};

  my $wind_now  = $data->{wind}->{speed};
  my $wind_gust = $data->{wind}->{gust};

  my $weather = shift @{ $data->{weather} };
  my $desc = $weather->{description};

  my $str = 
    "($place) ${temp}F (${temp_lo}F/${temp_hi}F lo/hi)"
    . " ${humid}% humid; wind ${wind_now}mph gusting to ${wind_gust}mph"
    . " ($desc)"
  ;

  my $chan = $req->tag;
  $_[HEAP]->{irc}->privmsg($chan => $str);
}

POE::Kernel->run

