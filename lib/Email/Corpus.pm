
use strict;
use warnings;
package Email::Corpus;

use Carp ();

use DBI;
use File::Temp;

=head1 NAME

Email::Corpus - a collection of email messages for testing

=head1 SYNOPSIS

  use Email::Corpus;
  use Test::More;
  use Hypthetical::DKIM::Tester qw(check_dkim);

  my $collection = Email::Corpus->search({
    package => [ -Core, -DKIM ],
    name    => $name,
    tags    => [ qw(mime tnef) ],
    filter  => sub { exists $_->meta->{dkim} },
  });

  plan tests => $collection->count;

  while (my $email = $collection->next) {
    my ($pkg, $guid) = map { $email->$_ } qw(package guid);

    is(
      check_dkim($email->abstract),
      $email->meta->{dkim},
      "expected dkim result on $guid in $pkg",
    );
  }

=head1 METHODS

=head2 search

  my $collection = Email::Corpus->search(\%arg);

Valid arguments are:

  package - a package or list of corpus packages to search
            strings beginning with - will have the dash replaced with
            Email::Corpus::Corpus::

  name    - only get messages with the given name
  tags    - only get messages with all the given tags
  guid    - only get messages with the given GUID
  filter  - a coderef to filter out results; $_ is set to each email

=cut

my $TEMPDIR;
sub _tempdir {
  $TEMPDIR ||= File::Temp::tempdir(CLEANUP => 1);
}

sub search {
  my ($self, $arg) = @_;
  $arg ||= {};

  my %corpus = map { $_ => { name => $_->db_name, file => $_->db_file } }
               $self->_prepare_packages($arg->{packages});

  my $tempdir = $self->_tempdir;
  my $dbh = DBI->connect("dbi:SQLite:$tempdir/email-corpus.db", undef, undef);

  for (keys %corpus) {
    my $file = $dbh->quote($corpus{$_}{file});
    $dbh->do("ATTACH DATABASE $file AS $corpus{$_}{name}") or die $dbh->errstr;
  }

  my $qname = $dbh->quote($arg->{name});
  my $qguid = $dbh->quote($arg->{guid});

  my @queries;
  my $query = 'SELECT %s AS package, guid FROM %s.emails WHERE 1=1';
     $query .= " AND name = $qname" if $arg->{name};
     $query .= " AND guid = $qguid" if $arg->{guid};

  for (keys %corpus) {
    my $pkg = $dbh->quote($_);
    push @queries, sprintf $query, $pkg, $corpus{$_}{name};
    warn "@queries";
  }

  my $results = $dbh->selectall_arrayref(join(' UNION ', @queries));

  return $results;
}

sub _prepare_packages {
  my ($self, $packages) = @_;

  my @packages = @$packages if $packages;
  @packages = '-Core' unless @packages;

  for (@packages) {
    s/^-/$self->default_corpus_namespace/e;
    eval "require $_; 1" or die $@;
  }

  return @packages;
}

sub default_corpus_namespace { 'Email::Corpus::Corpus::' }

1;
