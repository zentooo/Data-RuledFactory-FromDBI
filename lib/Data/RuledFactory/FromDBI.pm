package Data::RuledFactory::FromDBI;
use 5.008_001;
use strict;
use warnings;

use Carp qw/croak/;

use DBIx::Inspector;
use Time::Piece::MySQL;

use parent qw/Data::RuledFactory/;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $opts = ref $_[0] ? $_[0] : +{@_};

    my $dbh;

    if ( ! ($dbh = delete $opts->{dbh}) ) {
        croak "mandatory parameter dbh missing.";
    }

    $opts->{inspector} = DBIx::Inspector->new(dbh => $dbh);

    my $self = $class->SUPER::new($opts);

    return $self;
}

sub from_table {
    my ($self, $table, $params) = @_;

    my @columns = $self->{inspector}->columns($table);

    for my $column (@columns) {
        if ( $params->{$column->name} ) {
            $self->add_rule($params->{$column->name});
        }
        else {
            $self->add_rule($column->name, $self->_rule_from_column($column));
        }
    }
}

sub _rule_from_column {
    my ($self, $column) = @_;

    # looks like integer
    if ( $column->data_type == 4 ) {
        return [ Sequence => { min => 1, step => 1 } ];
    }
    # looks like float
    elsif ( 6 <= $column->data_type && $column->data_type <= 8 ) {
        return [ RangeRandom => { min => 1.0, max => 9999.9 } ];
    }
    # looks like string
    elsif ( $column->data_type == 1 || $column->data_type == 12 ) {
        return [ StringRandom => { data => q{\w\w\w\w} } ];
    }
    # looks like date
    elsif ( $column->data_type == 9 || $column->data_type == 91 ) {
        return sub { localtime()->mysql_date; };
    }
    # looks like time
    elsif ( $column->data_type == 10 || $column->data_type == 92 ) {
        return sub { localtime()->mysql_time; };
    }
    # looks like datetime or timestamp
    elsif ( $column->data_type == 11 || $column->data_type == 93 ) {
        return sub { localtime()->mysql_datetime; };
    }
    else {
        return [ Sequence => { min => 1, step => 1 } ];
    }
}


1;
__END__

=head1 NAME

Data::RuledFactory::FromDBI - subclass of Data::RuledFactory for creating rule from DBI fuzzily.

=head1 VERSION

This document describes Data::RuledFactory::FromDBI version 0.01.

=head1 SYNOPSIS

    # assume that you have a table `article` on your DB such like this:
    +--------------------------+---------------------+------+-----+---------+-------+
    | Field                    | Type                | Null | Key | Default | Extra |
    +--------------------------+---------------------+------+-----+---------+-------+
    | id                       | int(10) unsigned    | NO   | PRI | NULL    |       |
    | status                   | tinyint(1) unsigned | NO   |     | NULL    |       |
    | content                  | text                | NO   |     | NULL    |       |
    | published_on             | int(10) unsigned    | NO   |     | NULL    |       |
    | created_on               | int(10) unsigned    | NO   |     | NULL    |       |
    | updated_on               | int(10) unsigned    | NO   |     | NULL    |       |
    | ...                      | ...                 | NO   |     | NULL    |       |
    | ...                      | ...                 | NO   |     | NULL    |       |
    | ...                      | ...                 | NO   |     | NULL    |       |
    +--------------------------+---------------------+------+-----+---------+-------+


    # ... and have the dbh for that DB.

    use Data::RuledFactory::FromDBI;

    my $rf = Data::RuledFactory::FromDBI->new(dbh => $dbh);

    # You need not to define all rules for each column.
    # Define the rules only you need. Rules for omitted columns will be auto-generated fuzzily.

    $rf->from_table("article", +{
        published_on => [
            RangeRandom =>+{
                min => DateTime->new( year => 2011, month => 12, day => 1 )->epoch,
                max => DateTime->new( year => 2011, month => 12, day => 24 )->epoch,
                incremental => 1,
                integer => 1,
            }
        ]
    });
    $rf->rows(100);

    while ( $rf->has_next ) {
        my $d = $rf->next;
        # insert auto-generated data to DB with DBI or whatelse.
    }


    ### If insertion failed somehow ( because of DB's constraint ? )
    ### then you define a rule manually :)

    $rf->from_table("article", +{
        published_on => [
            RangeRandom =>+{
                min => DateTime->new( year => 2011, month => 12, day => 1 )->epoch,
                max => DateTime->new( year => 2011, month => 12, day => 24 )->epoch,
                incremental => 1,
                integer => 1,
            }
        ],
        status => [
            ListRandom => { data => [0, 1, 2] } ];
        ]
    });

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

zentooo E<lt>ankerasoy@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, zentooo. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
