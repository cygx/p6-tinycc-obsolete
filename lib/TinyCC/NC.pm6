# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use nqp;
use TinyCC::CTypes;

my class Callsite is repr<NativeCall> {}

my class nc is export {
    method bind(Str $name, Signature $sig, Str :$lib) {
        my $argtypes := nqp::list();
        nqp::push($argtypes, nqp::hash('type', cnativetype($_)))
            for $sig.params.grep(*.positional)>>.type;

        my $rtype := $_ ~~ Int ?? Int !! $_
            given $sig.returns;

        my $cs := nqp::create(Callsite);
        nqp::buildnativecall(
            $cs,
            $lib // '',
            $name,
            '', # calling convention
            $argtypes,
            nqp::hash('type', cnativetype($sig.returns)),
        );

        sub (|args) {
            fail "Arguments { args.gist } do not match signature { $sig.gist }"
                unless args ~~ $sig;

            my $args := nqp::list();
            nqp::push($args, $_) for args.list;
            nqp::nativecall($rtype, $cs, $args);
        }
    }

    multi method invoke(Str $name, Signature $sig, Capture $args, Str :$lib) {
        self.bind($name, $sig, :$lib).(|$args);
    }

    multi method invoke(Str $name, Signature $sig, *@args, Str :$lib) {
        self.bind($name, $sig, :$lib).(|@args);
    }

}
