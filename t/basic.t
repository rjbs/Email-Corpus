use strict;
use warnings;

use Test::More 'no_plan';

use Email::Corpus;

my @results = Email::Corpus->search({
  package => [ -Core ],
  name    => 'bar',
});

use Data::Dumper;
diag Dumper(@results);
