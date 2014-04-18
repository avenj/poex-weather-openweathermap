package POEx::Weather::OpenWeatherMap::Result::Forecast;

use v5.10;
use strictures 1;
use Carp;

use Types::Standard      -all;
use List::Objects::Types -all;

use POEx::Weather::OpenWeatherMap::Result::Forecast::Day;


sub lazy_for {
  my $type = shift;
  (
    lazy => 1, is => 'ro', isa => $type,
    ( $type->has_coercion ? (coerce => 1) : () ),
    @_
  )
}

use Moo; use MooX::late;
extends 'POEx::Weather::OpenWeatherMap::Result';

has id => ( lazy_for Int,
  builder => sub { shift->data->{city}->{id} },
);

has name => ( lazy_for Str,
  builder => sub { shift->data->{city}->{name} },
);

has country => ( lazy_for Str,
  builder => sub { shift->data->{city}->{country} },
);

has latitude => ( lazy_for StrictNum,
  builder => sub { shift->data->{city}->{coord}->{lat} },
);

has longitude => ( lazy_for StrictNum,
  builder => sub { shift->data->{city}->{coord}->{lon} },
);

has count => ( lazy_for Int,
  builder => sub { shift->data->{cnt} // 0 },
);

has _forecast_list => ( lazy_for ArrayObj,
  builder => sub { 
    my @list = @{ shift->data->{list} || [] };
    [ map {;
      ref %$_ eq 'HASH' ?
        POEx::Weather::OpenWeatherMap::Result::Forecast::Day->new(%$_)
        : carp "expected a HASH but got $_"
    } @list ]
  },
);

sub list {
  my ($self) = @_;
  $self->_forecast_list->all
}

sub iter {
  my ($self) = @_;
  $self->_forecast_list->natatime(1)
}

## FIXME interface to _forecast_list


1;
