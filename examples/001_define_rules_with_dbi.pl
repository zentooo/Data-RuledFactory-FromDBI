use strict;
use warnings;

use Data::RuledFactory::FromDBI;
use Data::Dump qw/dump/;

my $rfd = Data::RuledFactory::FromDBI->new(dbh => $dbh);

$rfd->from_table("article", +{
    published_on => [
        RangeRandom =>+{
            min => DateTime->new( year => 2011, month => 12, day => 1 )->epoch,
            max => DateTime->new( year => 2011, month => 12, day => 24 )->epoch,
            incremental => 1,
            integer => 1,
        }
    ]
});

while ( $rfd->has_next ) {
    my $d = $rf->next;
    printf(
        "id: %d, name: %s, published_on: %s\n",
        $d->{id},
        $d->{name},
        $d->{published_on},
    );
}
