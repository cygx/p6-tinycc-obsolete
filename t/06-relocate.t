#!/usr/bin/env perl6

use v6;

use Test;

plan 3;

{
    use TinyCC;
    LEAVE tcc.delete;

    tcc.set(:nostdlib);
    tcc.compile(q:to/__END__/);
        void _start() {};
        int i = 42;
        __END__
    tcc.relocate;

    my $p = tcc.lookup('i', :type(int32));
    ok defined($p), 'can lookup declared symbol';
    ok $p.deref == 42, 'can access value';

    my $q = tcc.lookup('j');
    ok !defined($q), 'cannot lookup undeclared symbol';
}

done-testing;
