#!/usr/bin/env perl6

use v6;

use Test;
use TinyCC;

plan 1;

tcc.catch(-> | { pass 'Compilation error succesfully caught' });
try tcc.compile('42');

done-testing;
