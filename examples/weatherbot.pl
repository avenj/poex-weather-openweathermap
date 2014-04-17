#!/usr/bin/env perl

use strictures 1;
use Carp;
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

  help => sub {
    say $_ for (
      "Usage:",
      "",
      "  --api-key=KEY",
      "",
      "  --nickname=NICKNAME",
      "  --username=USERNAME",
      "  --server=ADDR",
      "  --channels=CHAN[,CHAN ..]",
      "  --cmd=CMD",
    );
    exit 0
  },
};
GetOptions( $Opts,
  'nickname=s',
  'username=s',
  'server=s',
  'api_key=s',
  'channels=s',
  'cmd=s',

  'help',
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

  $_[HEAP] = hash(%{ $_[HEAP] })->inflate;
}



sub pxi_irc_001 {
  $_[HEAP]->irc->join( getopts->channels->all )
}

sub pxi_irc_public_msg {
  my $event = $_[ARG0];
  my ($target, $string) = @{ $event->params };
  
  my $cmd = getopts->cmd;
  if ( index($string, "$cmd ") == 0 ) {
    my $location = substr $string, length("$cmd ");

    $_[HEAP]->wx->get_weather(
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
    $_[HEAP]->irc->privmsg($chan => "Err: $status");
  }
  warn "Err: $status";
}

sub pwx_weather {
  my $res = $_[ARG0];

  my $place = $res->name;

  my $tempf = $res->temp_f;
  my $tempc = $res->temp_c;
  my $humid = $res->humidity;

  my $wind    = $res->wind_speed_mph;
  my $gust    = $res->wind_gust_mph;
  my $winddir = $res->wind_direction;
  
  my $terse   = $res->conditions_terse;
  my $verbose = $res->conditions_verbose;

  my $hms = $res->dt->hms;

  my $str = "$place at ${hms}UTC: ${tempf}F/${tempc}C";
  $str .= " and ${humid}% humidity;";
  $str .= " wind is ${wind}mph $winddir";
  $str .= " gusting to ${gust}mph" if $gust;
  $str .= ". Current conditions: ${terse}: $verbose";

  my $chan = $res->request->tag;
  $_[HEAP]->irc->privmsg($chan => $str);
}

POE::Kernel->run

