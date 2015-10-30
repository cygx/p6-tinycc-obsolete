# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use NativeCall;

my class X::Eval::Comp is X::AdHoc {}

multi EVAL(Cool $code, Str() :$lang! where 'C', :%symbols, :@lib) is export {
    require TinyCC;

    my \tcc = TinyCC::load(@lib);
    LEAVE tcc.delete;

    my $error;
    tcc.catch(-> $, Str $payload { $error = X::Eval::Comp.new(:$payload) });
    tcc.declare(|%(%symbols.pairs.map({ .key => nativecast(Pointer, .value) })));

    try tcc.compile(~$code);
    $error.?fail;

    tcc.run;
}
