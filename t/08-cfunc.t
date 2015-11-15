#!/usr/bin/env perl6

use v6;

BEGIN say 1..3;

use CTypes;
use TinyCC::CFunc;
use TinyCC { .sysinclude: <stdio.h> }

sub ok($cond, $desc) {
    say "{ $cond ?? '' !! 'not ' }ok { ++$ } - $desc";
}

sub plus(cint \a, cint \b --> cint) is cfunc({ q:to/__END__/ }, tcc) {*}
    return a + b;
    __END__

sub minus(cint \a, cint \b --> cint) is cfunc({ q:to/__END__/ }, tcc) {*}
    return a - b;
    __END__

sub ok3 is cfunc({ q:to/__END__/ }, tcc) {*}
    puts("ok 3 - can print from C function");
    fflush(stdout);
    __END__

ok plus(3, 4) == 7 , 'can add numbers in C';
ok minus(3, 4) == -1,  'can substract numbers in C';
ok3;
