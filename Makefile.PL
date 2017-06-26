use strict;
use warnings;

use inc::Module::Install;

name    ('Email-Corpus');
author  ('Ricardo SIGNES <rjbs@cpan.org>');
license ('perl');
all_from('lib/Email/Corpus.pm');

install_share;

WriteAll();
