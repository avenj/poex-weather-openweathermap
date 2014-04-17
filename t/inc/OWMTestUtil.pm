package
  OWMTestUtil;
use strictures 1;
use Carp;


use constant {
  JSON_CURRENT  => 't/inc/current.json',
  JSON_THREEDAY => 't/inc/3day.json',
};


use parent 'Exporter::Tiny';

use Path::Tiny;
use JSON::Tiny;



sub _get_test_data_current { path(JSON_CURRENT)->slurp  }
sub _get_test_data_3day    { path(JSON_THREEDAY)->slurp }



our @EXPORT = our @EXPORT_OK = qw/
  get_test_data
/;

sub get_test_data {
  my $type = lc (shift || return);
  for ($type) {
    return _get_test_data_current 
      if $type eq 'current';

    return _get_test_data_3day    
      if $type eq '3day'
      or $type eq 'forecast';
  }
  confess "Fell through in get_test_data: unknown type '$type'"
}



1;
