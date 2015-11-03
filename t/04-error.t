#!/usr/bin/env perl6

use v6;
use Test;

plan 3;

{
    use TinyCC *;
    tcc.catch(-> | { pass 'compilation error succesfully caught' });
    try tcc.compile('42').run;
}

{
    use TinyCC *;
    tcc.catch(-> | { die 'unexpected compilation error' });
    ok tcc.compile(q:to/__END__/).run == 2, 'can use math function';
        double log10(double);
        int main(void) { return log10(100); }
        __END__
}

{
    use TinyCC { .set: |:nostdlib };
    tcc.catch(-> | { pass 'cannot use math function with -nostdlib' });
    try tcc.compile(q:to/__END__/).run;
        double log10(double);
        int main(void) { return log10(100); }
        __END__
}

done-testing;
