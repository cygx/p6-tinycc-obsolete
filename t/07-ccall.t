#!/usr/bin/env perl6

use v6;
use Test;

use TinyCC::CCall;
use CTypes;

plan 1;

{
    sub mycos(cdouble --> cdouble) is ccall<cos> {*}
    ok mycos(pi) == cos(pi), 'can call cos from libc';
}

done-testing;
