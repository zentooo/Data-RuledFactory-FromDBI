#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Data::RuledFactory::FromDBI';
}

diag "Testing Data::RuledFactory::FromDBI/$Data::RuledFactory::FromDBI::VERSION";
