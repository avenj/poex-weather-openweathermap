package POEx::Weather::OpenWeatherMap::Request::Current;

use Moo;
extends 'POEx::Weather::OpenWeatherMap::Request';

# Empty subclass

1;

=pod

=head1 NAME

POEx::Weather::OpenWeatherMap::Request::Current

=head1 SYNOPSIS

  use POEx::Weather::OpenWeatherMap::Request;
  my $current = POEx::Weather::OpenWeatherMap::Request->new_for(
    Current =>
      tag      => 'foo',
      location =>
  );

=head1 DESCRIPTION

This is an empty subclass of L<POEx::Weather::OpenWeatherMap::Request>.

Look there for related documentation.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl

=cut
