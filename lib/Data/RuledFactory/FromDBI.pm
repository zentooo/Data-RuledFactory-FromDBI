package Data::RuledFactory::FromDBI;
use 5.008_001;
use strict;
use warnings;

use Data::RuledFactory;
use DBIx::Inspector;

use parent qw/Class::Delegate/;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $opts = ref $_[0] ? $_[0] : +{@_};

    my $dbh;

    if ( $dbh = delete $opts->{dbh} ) {
        croak "mandatory parameter dbh missing.";
    }

    $opts->{inspector} = DBIx::Inspector->new(dbh => $dbh);
    $opts->{factory} = Data::RuledFactory->new($opts);

    my $self = bless $opts, $class;

    $self->add_delegate($opts->{factory});

    return $self;
}

sub from_table {
    my ($table, $params) = @_;

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
    elsif ( $column->data_type == 6 || $column->data_type == 8 ) {
        return [ RangeRandom => { min => 1.0, max => 99999999.9 } ];
    }
    # looks like string
    elsif ( $column->data_type == 1 || $column->data_type == 12 ) {
        return [ StringRandom => { data => q{\w\w\w\w} } ];
    }
    # looks like date
    elsif ( $column->data_type == 9 ) {
        return sub { localtime()->mysql_date; };
    }
    # looks like time
    elsif ( $column->data_type == 10 ) {
        return sub { localtime()->mysql_time; };
    }
    # looks like datetime or timestamp
    elsif ( $column->data_type == 11 ) {
        return sub { localtime()->mysql_datetime; };
    }
    else {
        return [ Sequence => { min => 1, step => 1 } ];
    }
}


1;
__END__

=head1 NAME

Data::RuledFactory::FromDBI - Perl extention to do something

=head1 VERSION

This document describes Data::RuledFactory::FromDBI version 0.01.

=head1 SYNOPSIS

    use Data::RuledFactory::FromDBI;

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
