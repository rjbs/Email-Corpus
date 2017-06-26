
use strict;
use warnings;
package Email::Corpus::Corpus;

use File::ShareDir ();

sub db_file {
  my ($class) = @_;
  return File::ShareDir::dist_file(
    'Email-Corpus',
    $class->db_name . '.sqlite'
  );
}

sub db_name {
  my ($class) = @_;
  $class =~ s/(?:::|')/_/g;
  $class= lc $class;
  return $class;
}

1;
