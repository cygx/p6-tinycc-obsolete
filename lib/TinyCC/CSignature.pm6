# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use nqp;
use TinyCC::CTypes;

class CParameter {
    has $.name;
    has $.type;

    method Str {
        defined($!name) ?? "$!type $!name" !! $!type;
    }
}

class CSignature is export {
    has $.returns;
    has @.params;

    method arity { +@!params }

    method from(Signature $sig) {
        self.bless(
            returns => ctype($sig.returns),
            params => $sig.params.grep(*.positional).map({
                CParameter.new(name => .name, type => ctype(.type));
            }),
        );
    }

    method prototype($name) {
        "{ $!returns } { $name }({ @!params ?? @!params.join(', ') !! 'void' })"
    }
}

sub cargs(@args) is export {
    @args.map: {
        when Numeric { ~.Numeric }
        when .REPR eq 'CPointer' { "(void*){ nqp::unbox_i($_ // 0) }" }
        default { die "Mapping of argument { .gist } not known" }
    }
}
