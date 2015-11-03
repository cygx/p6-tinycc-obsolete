# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use TinyCC;
use TinyCC::Types;

sub invokee(Ptr $fp, Signature $sig) {
    my $address := +$fp;
    my $rtype := $sig.returns;
    if $rtype =:= Mu {
        my $csig = cparams($sig.params).join(', ');
        my \CODE = qq:to/__END__/;
            int main(void) \{
                ((void (*)($csig))$address)(ARGS);
                return 0;
            }
            __END__

        sub (*@args) {
            my \tcc = TinyCC.new;
            tcc.define(ARGS => cargs(@args).join(', '));
            tcc.compile(CODE);
            tcc.run;
            Nil;
        }
    }
    else {
        my $ctype := ctype($rtype);
        my $csig = cparams($sig.params).join(', ');
        my \CODE = qq:to/__END__/;
            extern $ctype rv;
            int main(void) \{
                rv = (($ctype (*)($csig))$address)(ARGS);
                return 0;
            }
            __END__

        sub (*@args) {
            my \tcc = TinyCC.new;
            my $rv;
            cvar(c-to-nctype($rtype), $rv);
            tcc.define(ARGS => cargs(@args).join(', '));
            tcc.declare(:$rv);
            tcc.compile(CODE);
            tcc.run;
            rv($rv);
        }
    }
}

multi trait_mod:<is>(Routine $r, :cfunc([ TinyCC \tcc, $arg ])!) is export {
    tcc.compile($r, $_) given do given $arg {
        when Stringy { .Str }
        when Callable { .() }
        default { die }
    }

    my $handler := $r.wrap: sub (*@args) {
        $r.unwrap($handler);
        $handler := Nil;
        $r.wrap: invokee(tcc.lookup($r.name), $r.signature);
        $r.(@args);
    }
}
