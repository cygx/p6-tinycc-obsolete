# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use CTypes;
use TinyCC;

multi cbind(CPointer $fp, Signature $sig, Bool :$tcc!) is export {
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

        sub (|args, TinyCC :$tcc) {
            fail "Arguments { args.gist } do not match signature { $sig.gist }"
                unless args ~~ $sig;

            my \CLEANUP = not $tcc // $*TINYCC;
            my \tcc = $tcc // $*TINYCC // TinyCC.new;
            LEAVE { tcc.discard if CLEANUP }

            tcc.define(ARGS => cargs(args.list).join(', '));
            tcc.compile(CODE).run;
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

        sub (|args, TinyCC :$tcc) {
            fail "Arguments { args.gist } do not match signature { $sig.gist }"
                unless args ~~ $sig;

            my \CLEANUP = not $tcc // $*TINYCC;
            my \tcc = $tcc // $*TINYCC // TinyCC.new;
            LEAVE { tcc.discard if CLEANUP }

            my $rv := cval($rtype);
            tcc.define(ARGS => cargs(args.list).join(', '));
            tcc.declare(:$rv);
            tcc.compile(CODE).run;
            rv($rv);
        }
    }
}

multi cinvoke(CPointer $fp, Signature $sig, Capture $args, Bool :$tcc!)
    is export {
    cbind($fp, $sig, :tcc).(|$args);
}

multi cinvoke(CPointer $fp, Signature $sig, *@args, Bool :$tcc!) is export {
    cbind($fp, $sig, :tcc).(|@args);
}
