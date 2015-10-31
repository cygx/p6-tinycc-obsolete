#!/usr/bin/env perl6

use v6;

use Test;
use TinyCC::Eval;

plan 3;

{
    my $rv = EVAL 'int main() { return 42; }', :lang<C>;
    ok $rv == 42, 'EVAL yields correct return value';
}

{
    use NativeCall;

    my @out := CArray[uint64].new;
    @out[0] = 0;

    EVAL q:to/EOC/, :lang<C>, :symbols(:@out), :defines(N => 33);
        extern unsigned long long out;

        static unsigned long long fib(unsigned n) {
            return n < 2 ? n : fib(n - 1) + fib(n - 2);
        }

        int main() {
            out = fib(N);
        }
        EOC

    ok @out[0] == (0, 1, *+* ... *)[33], 'EVAL can access symbols and defines';
}

{
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
}

done-testing;
