#!/usr/bin/env perl6

use v6;

use Test;
use TinyCC::CCall;

plan 1;

{
    sub mycos(num --> num) is ccall<cos> {*}
    ok mycos(pi) == -1, 'can call cos()';
}

done-testing;
