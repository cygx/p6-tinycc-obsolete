# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use CTypes;
use TinyCC;

multi cbind(CPointer $fp, Signature $sig, Bool :$tcc!) is export {
    my $address := +$fp;
    my $csig := csignature($sig);
    if $csig.isvoid {
        my \CODE = qq:to/__END__/;
            int main(void) \{
                ({ $csig.ptrcast }$address)(ARGS);
                return 0;
            }
            __END__

        sub (*@args, TinyCC :$tcc) {
            # BUG why does this check makes thins go book?
            # fail "Arguments { @args.gist } do not match signature { $sig.gist }"
            #     unless \(@args) ~~ $sig;

            my \CLEANUP = not $tcc // $*TINYCC;
            my \tcc = $tcc // $*TINYCC // TinyCC.new;
            LEAVE { tcc.discard if CLEANUP }

            tcc.define(ARGS => @args.map(&ceval).join(', '));
            tcc.compile(CODE).run;
            Nil;
        }
    }
    else {
        my \CODE = qq:to/__END__/;
            extern { $csig.returns } rv;
            int main(void) \{
                rv = ({ $csig.ptrcast }$address)(ARGS);
                return 0;
            }
            __END__

        sub (*@args, TinyCC :$tcc) {
            # BUG why does this check makes thins go book?
            # fail "Arguments { @args.gist } do not match signature { $sig.gist }"
            #     unless \(|@args) ~~ $sig;

            my \CLEANUP = not $tcc // $*TINYCC;
            my \tcc = $tcc // $*TINYCC // TinyCC.new;
            LEAVE { tcc.discard if CLEANUP }

            my $rv := cvalue($sig.returns);
            tcc.define(ARGS => @args.map(&ceval).join(', '));
            tcc.declare(:$rv);
            tcc.compile(CODE).run;
            $rv.rv;
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
