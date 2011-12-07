#!perl -w
use strict;
use Test::More;

use Test::Mock::Guard;
use Data::Util qw/:check/;

use Data::RuledFactory;
use DBIx::Inspector;


BEGIN {
    use_ok 'Data::RuledFactory::FromDBI';
}

diag "Testing Data::RuledFactory::FromDBI/$Data::RuledFactory::FromDBI::VERSION";

my $rf = Data::RuledFactory->new;
$rf->add_rule("DATA_TYPE" => [
    ListRandom => { data => [(1 .. 15)] }
]);
$rf->add_rule("COLUMN_NAME" => [
    ListRandom => { data => [('a' .. 'z')] }
]);

$rf->rows(100);

sub mock_inspector {
    return mock_guard("DBIx::Inspector", +{
        new => sub {
            return bless +{}, "DBIx::Inspector";
        },
        columns => sub {
            map { DBIx::Inspector::Column->new($_) } $rf->to_array(0, 10);
        }
    });
}

sub next_column {
    my $code = shift;
    if ( $rf->has_next ) {
        my $column = DBIx::Inspector::Column->new($rf->next);
        $code->($column);
    }
}

subtest new => sub {
    my $g = mock_inspector;
    my $rfd = Data::RuledFactory::FromDBI->new(dbh => +{});
    isa_ok($rfd, "Data::RuledFactory");
    isa_ok($rfd, "Data::RuledFactory::FromDBI");
};

subtest _rule_from_column => sub {
    my $g = mock_inspector;
    my $rfd = Data::RuledFactory::FromDBI->new(dbh => +{});

    $rfd->rows(20);

    my $i = 0;
    while ( $rfd->has_next && $i++ <= 20 ) {
        next_column(sub {
            my $column = shift;
            note $column->data_type;
            my $rule = $rfd->_rule_from_column($column);

            if ( 9 <= $column->data_type && $column->data_type <= 11 ) {
                ok(is_code_ref($rule));
            }
            else {
                ok(is_array_ref($rule));
            }
        });
    }
};

subtest from_table => sub {
    my $g = mock_inspector;
    my $rfd = Data::RuledFactory::FromDBI->new(dbh => +{});

    $rfd->from_table("user");
    is(scalar @{$rfd->rules}, 10);
};

done_testing;
