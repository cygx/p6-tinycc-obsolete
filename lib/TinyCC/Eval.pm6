# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

need TinyCC;
use NativeCall;

my class X::Eval::Comp is X::AdHoc {}

multi EVAL(Cool $code, Str() :$lang! where 'C',
            :%symbols, :%defines,
            :$tcc, :@libtcc, :$root) is export {

    my \tcc = $tcc // TinyCC::load(|@libtcc, :$root);
    LEAVE tcc.delete;

    my $error;
    tcc.catch(-> $, Str $payload { $error = X::Eval::Comp.new(:$payload) });
    tcc.declare(|%(%symbols.pairs.map({ .key => nativecast(Pointer, .value) })));
    tcc.define(|%(%defines.pairs.map({ .key => ~.value })));

    try tcc.compile(~$code);
    $error.?fail;

    tcc.run;
}
