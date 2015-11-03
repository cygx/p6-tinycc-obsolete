# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use TinyCC::NC;

sub zero(Mu:U $type) {
    given ~$type.REPR {
        when 'P6int' { 0 }
        when 'P6num' { 0e0 }
        when 'CPointer' { $type }
        default { die }
    }
}

sub c-to-nctype(Mu:U $type) is export {
    given $type {
        when int { int32 }
        default { $type }
    }
}

proto rv($) is export {*}

multi rv($ptr where $ptr.?of.REPR ne 'CPointer') {
    nc.cast($ptr.of, $ptr);
}

multi rv($ptr where $ptr.?of.REPR eq 'CPointer') {
    nc.deref-ptr-of-ptr($ptr);
}

sub lv($ptr) is rw is export {
    nc.cast-ptr-to-array($ptr).AT-POS(0);
}

proto cvar(|) is rw is export {*}

multi cvar(Mu:U $type, :$value) is rw {
    $type := c-to-nctype($type);
    nc.array($type, $value // zero($type)).AT-POS(0);
}

multi cvar(Mu:U $type, $ptr is rw, :$value) is rw {
    $type := c-to-nctype($type);
    my $carray := nc.array($type, $value // zero($type));
    $ptr = nc.cast-to-ptr-of($type, $carray);
    $carray.AT-POS(0);
}

multi cval(Mu:U $type, $value?) is export {
    $type := c-to-nctype($type);
    nc.cast-to-ptr-of($type, nc.array($type, $value // zero($type)));
}

sub ctype(Mu:U $type) is export {
    given $type.^name {
        when 'Mu' { 'void' }
        when any <int int32> { 'int' }
        when any <uint uint32> { 'unsigned int' }
        when any <longlong int64> { 'long long' }
        when any <ulonglong uint64> { 'unsigned long long' }
        when any <num num64> { 'double'}
        when 'num32' { 'float' }
        when 'Pointer' { 'void*' }
        default { die }
    }
}

sub cparams(@params) is export {
    return 'void' unless @params;
    @params.map: {
        when .positional {
            my $ctype := ctype(.type);
            my $name := .name;
            defined($name) ?? "$ctype $name" !! $ctype;
        }
        default { die }
    }
}

sub cargs(@args) is export {
    use nqp;
    @args.map: {
        when Numeric { ~.Numeric }
        when .REPR eq 'CPointer' { "(void*){ nqp::unbox_i($_) }" }
        default { die }
    }
}
