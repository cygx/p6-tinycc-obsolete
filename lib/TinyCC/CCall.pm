# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use TinyCC;
use CTypes;

sub ccall(Str $name, Signature $sig) {
    my $csig := csignature($sig);
    if $csig.isvoid {
        my \CODE = qq:to/__END__/;
            { $csig.prototype($name) };
            int main(void) \{
                ($name)(ARGS);
                return 0;
            }
            __END__

        sub (*@args) {
            my \tcc = $*TINYCC // TinyCC.new;
            tcc.define(ARGS => @args.map(&ceval).join(', '));
            tcc.compile(CODE);
            tcc.run;
            Nil;
        }
    }
    else {
        my \CODE = qq:to/__END__/;
            { $csig.prototype($name) };
            extern { $csig.returns } rv;
            int main(void) \{
                rv = ($name)(ARGS);
                return 0;
            }
            __END__

        sub (*@args) {
            my \tcc = $*TINYCC // TinyCC.new;
            my $rv := cvalue($sig.returns);
            tcc.define(ARGS => @args.map(&ceval).join(', '));
            tcc.declare(:$rv);
            tcc.compile(CODE);
            tcc.run;
            $rv.rv;
        }
    }
}

multi trait_mod:<is>(Routine $r, :ccall($name)!) is export {
    $r.wrap: ccall($name ~~ Bool ?? $r.name !! ~$name, $r.signature);
}
