#!/usr/bin/env perl6

use v6;

use Test;
use TinyCC::Eval;

plan 2;

my $rv = EVAL 'int main() { return 42; }', :lang<C>;
ok $rv == 42, 'EVAL yields correct return value';

my class Point is repr<CStruct> {
    has num64 $.x;
    has num64 $.y;
}

my $point = Point.new(x => 0e0, y => 0e0);

EVAL q:to/OMEGA/, :lang<C>, :symbols(:$point);
    extern struct { double x, y; } point;
    int main() {
        point.x = 0.5;
        point.y = 1.5;
    }
    OMEGA

ok $point.x == 0.5 && $point.y == 1.5, 'can access CStruct from EVAL';

done-testing;
