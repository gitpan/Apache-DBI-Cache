use strict;
use Test::More tests => 10;
use Test::Deep;

my @called=(0,0);
my ($before_sub, $after_sub);
my $nocache;
BEGIN {
  $before_sub=sub {
    $called[0]++;
    return @_, {incr=>2}, $nocache;
  };
  $after_sub=sub {
    my ($dbh, $dsn, $user, $passwd, $attr,
	$ctx)=@_;
    $called[1]+=$ctx->{incr};
    1;
  };
}

use Apache::DBI::Cache delimiter=>'^', bdb_env=>"t/dbenv",
                       plugin=>['DBM', $before_sub, $after_sub],
                       plugin=>'Apache::DBI::Cache::mysql';

Apache::DBI::Cache::connect_on_init('dbi:DBM:f_dir=tmp1');
Apache::DBI::Cache->connect_on_init('dbi:DBM:f_dir=tmp1');

Apache::DBI::Cache::init;

my $stat=Apache::DBI::Cache::statistics;

cmp_deeply( $stat->{'DBM^f_dir=tmp1^'}, [2,2,2,0,0],
	    'connect_on_init1' );

cmp_deeply \@called, [2, 4], 'plugin called';

my @old_plugin=Apache::DBI::Cache::plugin('DBM');

cmp_deeply \@old_plugin, [isa('CODE'), isa('CODE')], 'fetch plugin';

Apache::DBI::Cache::plugin('DBM', undef, undef);
cmp_deeply [Apache::DBI::Cache::plugin('DBM')], [], 'plugin deleted';

@called=(0,0);
DBI->connect('dbi:DBM:f_dir=tmp1');
cmp_deeply \@called, [0,0], 'plugin not called';

cmp_deeply( $stat->{'DBM^f_dir=tmp1^'}, [2,2,3,0,0],
	    'but handle used' );

Apache::DBI::Cache::plugin('DBM', @old_plugin);
@called=(0,0);
$nocache=1;
DBI->connect('dbi:DBM:f_dir=tmp1');
cmp_deeply \@called, [1,0], 'nocache';

cmp_deeply( $stat->{'DBM^f_dir=tmp1^'}, [2,2,3,0,0],
	    'statistics remain unchanged' );
undef $nocache;

Apache::DBI::Cache::plugin('DBM', sub{$called[0]++; return;}, sub{die});
@called=(0,0);
DBI->connect('dbi:DBM:f_dir=tmp1');
cmp_deeply \@called, [1,0], 'nocache2';

cmp_deeply( $stat->{'DBM^f_dir=tmp1^'}, [2,2,3,0,0],
	    'statistics remain unchanged again' );

Apache::DBI::Cache::finish;

# Local Variables:
# mode: perl
# End:
