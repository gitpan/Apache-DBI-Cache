use strict;
use Test::More tests => 8;
use Test::Deep;

use Apache::DBI::Cache use_bdb=>0, delimiter=>'^';

Apache::DBI::Cache::connect_on_init('dbi:DBM:f_dir=tmp1');
Apache::DBI::Cache->connect_on_init('dbi:DBM:f_dir=tmp2');

Apache::DBI::Cache::init;

my $stat=Apache::DBI::Cache::statistics;

ok(!tied %{$stat}, '!tied %STAT');

cmp_deeply( $stat->{'DBM^f_dir=tmp1^'}, [1,1,1,0,0],
	    'connect_on_init1' );

cmp_deeply( $stat->{'DBM^f_dir=tmp2^'}, [1,1,1,0,0],
	    'connect_on_init2' );

my $html=join '', @{Apache::DBI::Cache::statistics_as_html()};
cmp_deeply( $html, re('<h1>DBI Handle Statistics for process \d+</h1>'),
	    'html statistics' );

my ($dbh1, $dbh2);
$dbh1=DBI->connect('dbi:DBM:f_dir=tmp1');
$dbh1="$dbh1";
$dbh2=DBI->connect('dbi:DBM:f_dir=tmp1');
$dbh2="$dbh2";
ok $dbh1 eq $dbh2, "got identical handles";

$dbh1=DBI->connect('dbi:DBM:f_dir=tmp1');
$dbh2=DBI->connect('dbi:DBM:f_dir=tmp1');

cmp_deeply( $stat->{'DBM^f_dir=tmp1^'}, [2,0,5,0,0],
	    'statistics after usage1' );

$dbh1="$dbh1";
$dbh2="$dbh2";
ok $dbh1 ne $dbh2, "got different handles";

cmp_deeply( $stat->{'DBM^f_dir=tmp1^'}, [2,2,5,0,0],
	    'statistics after usage2' );

Apache::DBI::Cache::finish;

# Local Variables:
# mode: perl
# End:
