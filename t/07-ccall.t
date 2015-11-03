#!/usr/bin/env perl6

use v6;
use Test;

use TinyCC *;
use TinyCC::CCall;

plan 1;

{
    sub libc-cos(num --> num) is ccall(tcc, :name<cos>) {*}
    ok libc-cos(pi) == cos(pi), 'can call cos from libc';
}

done-testing;
