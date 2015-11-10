# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use v6;
use nqp;

my class Callsite is repr<NativeCall> {}
my class void is repr<Uninstantiable> {}
my class ScalarRef { ... }
my class VMPtr is repr<CPointer> {
    method new(Mu \address) { nqp::box_i(nqp::unbox_i(address), self) }
    method from(Mu \obj) { nqp::nativecallcast(VMPtr, VMPtr, nqp::decont(obj)) }
    method Int { nqp::unbox_i(self) }
    method gist { "VMPtr|{ nqp::unbox_i(self) }" }
    method perl { "VMPtr.from({ nqp::unbox_i(self) })" }
}

my constant cvoidptr is export = VMPtr;

proto csizeof(Mu \obj) is export { obj.?CT-SIZEOF // nqp::nativecallsizeof(obj) }
proto ctypeid(Mu \obj) is export { obj.?CT-TYPEID // {*} }
proto ctype(Mu \obj, *%) is export { obj.?CT-TYPE // {*} }
proto carraytype(Mu) is export {*}
proto cpointer(Mu:U \T, $value, *%) is export {*}
proto carray(Mu:U \T, *@values, *%) is export {*}
proto cval(Mu:U \T, $value, *%) is export {*}
proto cbind(Str $name, Signature $sig, *%) is export {*}
proto cinvoke(Str $name, Signature $sig, *@, *%) is export {*}

my constant CHAR_BIT = 8;
my constant PTRSIZE = nqp::nativecallsizeof(VMPtr);
my constant PTRBITS = CHAR_BIT * PTRSIZE;

my native cintptr is Int is nativesize(PTRBITS) is repr<P6int> is export {}
my native cuintptr is Int is nativesize(PTRBITS) is unsigned is repr<P6int>
    is export {}
# -- no need to define array types: dispatches to fixed-sized types

my constant INTMAP = Map.new(
    map { CHAR_BIT * nqp::nativecallsizeof($_) => .HOW.name($_) },
        my native longlong is repr<P6int> is ctype<longlong> {},
        my native long is repr<P6int> is ctype<long> {},
        my native int is repr<P6int> is ctype<int> {},
        my native short is repr<P6int> is ctype<short> {},
        my native char is repr<P6int> is ctype<char> {});

my constant NUMMAP = Map.new(
    map { CHAR_BIT * nqp::nativecallsizeof($_) => .HOW.name($_) },
#        my native longdouble is repr<P6num> is ctype<longdouble> {},
        my native double is repr<P6num> is ctype<double> {},
        my native float is repr<P6num> is ctype<float> {});

sub ni($_, $size) {
    .HOW.WHAT =:= int.HOW.WHAT && .HOW.nativesize($_) == $size
        && !.HOW.unsigned($_);
}

sub nu($_, $size) {
    .HOW.WHAT =:= int.HOW.WHAT && .HOW.nativesize($_) == $size
        && ?.HOW.unsigned($_);
}

sub nn($_, $size) {
    .HOW.WHAT =:= int.HOW.WHAT && .HOW.nativesize($_) == $size;
}

my subset CChar of Int is export where ni $_, nqp::const::C_TYPE_CHAR;
my subset CShort of Int is export where ni $_, nqp::const::C_TYPE_SHORT;
my subset CInt of Int is export where ni $_, nqp::const::C_TYPE_INT;
my subset CLong of Int is export where ni $_, nqp::const::C_TYPE_LONG;
my subset CLLong of Int is export where ni $_, nqp::const::C_TYPE_LONGLONG;

my subset CUChar of Int is export where nu $_, nqp::const::C_TYPE_CHAR;
my subset CUShort of Int is export where nu $_, nqp::const::C_TYPE_SHORT;
my subset CUInt of Int is export where nu $_, nqp::const::C_TYPE_INT;
my subset CULong of Int is export where nu $_, nqp::const::C_TYPE_LONG;
my subset CULLong of Int is export where nu $_, nqp::const::C_TYPE_LONGLONG;

my subset CInt8 of Int is export where ni $_, 8;
my subset CInt16 of Int is export where ni $_, 16;
my subset CInt32 of Int is export where ni $_, 32;
my subset CInt64 of Int is export where ni $_, 64;
my subset CInt128 of Int is export where ni $_, 128;
my subset CIntPtr of Int is export where ni $_, PTRBITS;
my subset CIntX of Int is export where ni $_, 0;

my subset CUInt8 of Int is export where nu $_, 8;
my subset CUInt16 of Int is export where nu $_, 16;
my subset CUInt32 of Int is export where nu $_, 32;
my subset CUInt64 of Int is export where nu $_, 64;
my subset CUInt128 of Int is export where nu $_, 128;
my subset CUIntPtr of Int is export where nu $_, PTRBITS;
my subset CUIntX of Int is export where nu $_, 0;

my subset CFloat of Num is export where nn $_, nqp::const::C_TYPE_FLOAT;
my subset CDouble of Num is export where nn $_, nqp::const::C_TYPE_DOUBLE;
my subset CLDouble of Num is export where nn $_, nqp::const::C_TYPE_LONGDOUBLE;

my subset CFloat32 of Num is export where nn $_, 32;
my subset CFloat64 of Num is export where nn $_, 64;
my subset CFloatX of Num is export where nn $_, 0;

my subset CPointer of Mu is export where .REPR eq 'CPointer';
my subset CArray of Mu is export where .REPR eq 'CArray';
my subset VMArray of Mu is export where .REPR eq 'VMArray' || .WHAT ~~ Blob;

multi ctypeid(CChar) { 'char' }
multi ctypeid(CShort) { 'short' }
multi ctypeid(CInt) { 'int' }
multi ctypeid(CLong) { 'long' }
multi ctypeid(CLLong) { 'longlong' }

multi ctypeid(CUChar) { 'uchar' }
multi ctypeid(CUShort) { 'ushort' }
multi ctypeid(CUInt) { 'uint' }
multi ctypeid(CULong) { 'ulong' }
multi ctypeid(CULLong) { 'ulonglong' }

multi ctypeid(CInt8) { BEGIN INTMAP<8> // Str }
multi ctypeid(CInt16) { BEGIN INTMAP<16> // Str }
multi ctypeid(CInt32) { BEGIN INTMAP<32> // Str }
multi ctypeid(CInt64) { BEGIN INTMAP<64> // Str }
multi ctypeid(CInt128) { BEGIN INTMAP<128> // Str }
# -- dispatches to fixed-sized types
# multi ctypeid(CIntPtr) { BEGIN INTMAP{PTRBITS} // Str }

multi ctypeid(CIntX $_) {
    INTMAP{ CHAR_BIT * nqp::nativecallsizeof($_) } // Str;
}

multi ctypeid(CUInt8) { BEGIN INTMAP<8> // Str andthen "u$_" }
multi ctypeid(CUInt16) { BEGIN INTMAP<16> // Str andthen "u$_" }
multi ctypeid(CUInt32) { BEGIN INTMAP<32> // Str andthen "u$_" }
multi ctypeid(CUInt64) { BEGIN INTMAP<64> // Str andthen "u$_" }
multi ctypeid(CUInt128) { BEGIN INTMAP<128> // Str andthen "u$_" }
# -- dispatches to fixed-sized types
# multi ctypeid(CUIntPtr) { BEGIN INTMAP{PTRBITS} // Str andthen "u$_" }

multi ctypeid(CUIntX $_) {
    (INTMAP{ CHAR_BIT * nqp::nativecallsizeof($_) } // Str) andthen "u$_";
}

multi ctypeid(CFloat) { 'float' }
multi ctypeid(CDouble) { 'double' }
multi ctypeid(CLDouble) { 'longdouble' }

multi ctypeid(CFloat32) { BEGIN NUMMAP<32> // Str }
multi ctypeid(CFloat64) { BEGIN NUMMAP<64> // Str }

multi ctypeid(CFloatX $_) {
    NUMMAP{ CHAR_BIT * nqp::nativecallsizeof($_) } // Str;
}

multi ctypeid(CPointer) { 'cpointer' }
multi ctypeid(CArray) { 'carray' }
multi ctypeid(VMArray) { 'vmarray' }

multi ctypeid(Mu $_) { Str }

multi carray(Mu:U \T, *@values) {
    my uint $n = +@values;
    my $raw := carraytype(T).new;
    my $boxed := $raw.box($n);
    while ($n--) { $raw[$n] = @values[$n] }
    $boxed;
}

multi cval(Mu:U \T, $value, *%) {
    my $array := carraytype(T).new;
    $array[0] = $value;
    cpointer(T, $array);
}

multi cbind(Str $name, Signature $sig, Str :$lib) {
    my $argtypes := nqp::list();
    nqp::push($argtypes, nqp::hash('type', ctypeid(.type)))
        for $sig.params.grep(*.positional);

    # only necessary for Int?
    my $rtype := do given $sig.returns {
        when Int { Int }
        when Num { Num }
        default { $_ }
    }

    my $cs := nqp::create(Callsite);
    nqp::buildnativecall(
        $cs,
        $lib // '',
        $name,
        '', # calling convention
        $argtypes,
        nqp::hash('type', ctypeid($sig.returns) // 'void'),
    );

    sub (|args) {
        fail "Arguments { args.gist } do not match signature { $sig.gist }"
            unless args ~~ $sig;

        my $args := nqp::list();
        nqp::push($args, .?CT-UNBOX // $_)
            for args.list;

        nqp::nativecall($rtype, $cs, $args);
    }
}

multi cinvoke(Str $name, Signature $sig, Capture $args, Str :$lib) {
    cbind($name, $sig, :$lib).(|$args);
}

multi cinvoke(Str $name, Signature $sig, *@args, Str :$lib) {
    cbind($name, $sig, :$lib).(|@args);
}

my role CPtr[::T = void] is export {
    has $.raw handles <Int>; # is box_target -- ???

    method CT-SIZEOF { PTRSIZE }
    method CT-TYPEID { 'cpointer' }
    method CT-TYPE { "{ ctype(T) }*" }
    method CT-UNBOX { $!raw }

    multi method from(Int \address) { self.new(raw => VMPtr.new(address)) }
    multi method from(Mu \obj) { self.new(raw => VMPtr.from(obj)) }
    method Numeric { self.Int }
    method hex { "0x{ self.Int.base(16).lc }" }
    method gist { "({ T.^name }*){ self.hex }" }
    method to(Mu:U \type) { CPtr[type].new(:$!raw) }
    method of { T }

    method lv is rw { ScalarRef.new(self) }

    method rv {
        given ~T.REPR {
            when 'CPointer' {
                nqp::box_i(self.to(cuintptr).rv, T);
            }

            when 'P6int' {
                nqp::nativecallcast(nqp::decont(T), Int, nqp::decont($!raw));
            }

            when 'P6num' {
                nqp::nativecallcast(nqp::decont(T), Num, nqp::decont($!raw));
            }

            default {
                die "Cannot dereference pointers of type { T.^name }";
            }
        }
    }
}

multi cpointer(Mu:U \T, $value) { CPtr[T].from($value) }

my class ScalarRef {
    has $.ptr;
    has $.raw;

    method FETCH { $!raw.AT-POS(0) }
    method STORE(\value) { $!raw.ASSIGN-POS(0, value) }

    method new(CPtr \ptr) {
        once {
            nqp::loadbytecode('nqp.moarvm');
            EVAL q:to/__END__/, :lang<nqp>;
            my $FETCH := nqp::getstaticcode(-> $cont {
                my $var := nqp::p6var($cont);
                nqp::decont(nqp::findmethod($var,'FETCH')($var));
            });

            my $STORE := nqp::getstaticcode(-> $cont, $value {
                my $var := nqp::p6var($cont);
                nqp::findmethod($var, 'STORE')($var, $value);
                Mu;
            });

            my $pair := nqp::hash('fetch', $FETCH, 'store', $STORE);
            nqp::setcontspec(ScalarRef,  'code_pair', $pair);
            Mu;
            __END__
        }

        my \type = nqp::decont(carraytype(ptr.of));
        my \raw = nqp::nativecallcast(type, type, nqp::decont(ptr.raw));
        my \ref = nqp::create(ScalarRef);
        nqp::bindattr(ref, ScalarRef, '$!raw', raw);
        nqp::bindattr(ref, ScalarRef, '$!ptr', ptr);

        ref;
    }
}

my role BoxedArray[::T, UInt \elems] does Positional[T] {
    has $.raw handles <AT-POS ASSIGN-POS>;

    method CT-SIZEOF { self.elems * csizeof(nqp::decont(T)) }
    method CT-TYPEID { 'carray' }
    method CT-TYPE { "{ ctype(T) }[{elems}]" }
    method CT-UNBOX { $!raw }

    method ptr { CPtr[T].from($!raw) }
    method elems { elems }

    method iterator {
        my \array = self;
        my uint $elems = elems;
        .new given class :: does Iterator {
            has uint $!i = 0;
            method pull-one {
                $!i < $elems ?? array.AT-POS($!i++) !! IterationEnd;
            }
        }
    }
}

my role RawArray[::T] {
    method box($raw: uint \elems) { BoxedArray[T, elems].new(:$raw) }
}

my role IntegerArray[::T] does RawArray[T] {
    method AT-POS(uint \pos) { nqp::atpos_i(self, pos) }
    method ASSIGN-POS(uint \pos, \value) { nqp::bindpos_i(self, pos, value) }
}

my role FloatingArray[::T] does RawArray[T] {
    method AT-POS(uint \pos) { nqp::atpos_n(self, pos) }
    method ASSIGN-POS(uint \pos, \value) { nqp::bindpos_n(self, pos, value) }
}


my native cchar is Int is ctype<char> is repr<P6int> is export {}
my class CCharArray is repr<CArray> is array_type(cchar)
    does IntegerArray[cchar] {}
multi carraytype(CChar) { CCharArray }

my native cshort is Int is ctype<short> is repr<P6int> is export {}
my class CShortArray is repr<CArray> is array_type(cshort)
    does IntegerArray[cshort] {}
multi carraytype(CShort) { CShortArray }

my native cint is Int is ctype<int> is repr<P6int> is export {}
my class CIntArray is repr<CArray> is array_type(cint)
    does IntegerArray[cint] {}
multi carraytype(CInt) { CIntArray }

my native clong is Int is ctype<long> is repr<P6int> is export {}
my class CLongArray is repr<CArray> is array_type(clong)
    does IntegerArray[clong] {}
multi carraytype(CLong) { CLongArray }

my native cllong is Int is ctype<longlong> is repr<P6int> is export {}
my class CLLongArray is repr<CArray> is array_type(cllong)
    does IntegerArray[cllong] {}
multi carraytype(CLLong) { CLLongArray }


my native cuchar is Int is ctype<char> is unsigned is repr<P6int> is export {}
my class CUCharArray is repr<CArray> is array_type(cuchar)
    does IntegerArray[cuchar] {}
multi carraytype(CUChar) { CUCharArray }

my native cushort is Int is ctype<short> is unsigned is repr<P6int> is export {}
my class CUShortArray is repr<CArray> is array_type(cushort)
    does IntegerArray[cushort] {}
multi carraytype(CUShort) { CUShortArray }

my native cuint is Int is ctype<int> is unsigned is repr<P6int> is export {}
my class CUIntArray is repr<CArray> is array_type(cuint)
    does IntegerArray[cuint] {}
multi carraytype(CUInt) { CUIntArray }

my native culong is Int is ctype<long> is unsigned is repr<P6int> is export {}
my class CULongArray is repr<CArray> is array_type(culong)
    does IntegerArray[clong] {}
multi carraytype(CULong) { CULongArray }

my native cullong is Int is ctype<longlong> is unsigned is repr<P6int>
    is export {}
my class CULLongArray is repr<CArray> is array_type(cullong)
    does IntegerArray[cullong] {}
multi carraytype(CULLong) { CULLongArray }


my native cint8 is Int is nativesize(8) is repr<P6int> is export {}
my class CInt8Array is repr<CArray> is array_type(cint8)
    does IntegerArray[cint8] {}
multi carraytype(CInt8) { CInt8Array }

my native cint16 is Int is nativesize(16) is repr<P6int> is export {}
my class CInt16Array is repr<CArray> is array_type(cint16)
    does IntegerArray[cint16] {}
multi carraytype(CInt16) { CInt16Array }

my native cint32 is Int is nativesize(32) is repr<P6int> is export {}
my class CInt32Array is repr<CArray> is array_type(cint32)
    does IntegerArray[cint32] {}
multi carraytype(CInt32) { CInt32Array }

my native cint64 is Int is nativesize(64) is repr<P6int> is export {}
my class CInt64Array is repr<CArray> is array_type(cint64)
    does IntegerArray[cint64] {}
multi carraytype(CInt64) { CInt64Array }

# my native cint128 is Int is nativesize(128) is repr<P6int> is export {}
# my class CInt128Array is repr<CArray> is array_type(cint128)
#     does IntegerArray[cint128] {}
# multi carraytype(CInt128) { CInt128Array }


my native cuint8 is Int is nativesize(8) is unsigned is repr<P6int>
    is export {}
my class CUInt8Array is repr<CArray> is array_type(cuint8)
    does IntegerArray[cuint8] {}
multi carraytype(CUInt8) { CUInt8Array }

my native cuint16 is Int is nativesize(16) is unsigned is repr<P6int>
    is export {}
my class CUInt16Array is repr<CArray> is array_type(cuint16)
    does IntegerArray[cuint16] {}
multi carraytype(CUInt16) { CUInt16Array }

my native cuint32 is Int is nativesize(32) is unsigned is repr<P6int>
    is export {}
my class CUInt32Array is repr<CArray> is array_type(cuint32)
    does IntegerArray[cuint32] {}
multi carraytype(CUInt32) { CUInt32Array }

my native cuint64 is Int is nativesize(64) is unsigned is repr<P6int>
    is export {}
my class CUInt64Array is repr<CArray> is array_type(cuint64)
    does IntegerArray[cuint64] {}
multi carraytype(CUInt64) { CUInt64Array }

# my native cuint128 is Int is nativesize(128) is unsigned is repr<P6int>
#     is export {}
# my class CUInt128Array is repr<CArray> is array_type(cuint128)
#     does IntegerArray[cuint128] {}
# multi carraytype(CUInt128) { CUInt128Array }


my native cfloat is Num is ctype<float> is repr<P6num> is export {}
my class CFloatArray is repr<CArray> is array_type(cfloat)
    does FloatingArray[cfloat] {}
multi carraytype(CFloat) { CFloatArray }

my native cdouble is Num is ctype<double>  is repr<P6num> is export {}
my class CDoubleArray is repr<CArray> is array_type(cdouble)
    does FloatingArray[cdouble] {}
multi carraytype(CDouble) { CDoubleArray }

# my native cldouble is Num is ctype<longdouble>  is repr<P6num>
#     is export {}
# my class CLDoubleArray is repr<CArray> is array_type(cldouble)
#     does FloatingArray[cldouble] {}
# multi carraytype(CLDouble) { CLDoubleArray }


my native cfloat32 is Num is nativesize(32) is repr<P6num> is export {}
my class CFloat32Array is repr<CArray> is array_type(cfloat32)
    does FloatingArray[cfloat32] {}
multi carraytype(CFloat32) { CFloat32Array }

my native cfloat64 is Num is nativesize(64) is repr<P6num> is export {}
my class CFloat64Array is repr<CArray> is array_type(cfloat64)
    does FloatingArray[cfloat64] {}
multi carraytype(CFloat64) { CFloat64Array }

# -- preliminary helper functions
# -- likely to change with future revisions

sub cstrings(*@values, :$enc = 'utf8', :$stage) is export {
    Blob[cuintptr].new(|@values.map({
        my $blob := "$_\0".encode($enc);
        .push($blob) with $stage;
        VMPtr.from($blob)
    }), 0);
}

sub ceval(*@values) is export {
    @values.map: {
        when Numeric { ~.Numeric }
        when CPointer { "(void*){ nqp::unbox_i($_ // 0) }" }
        default { die "Mapping of value { .gist } not known" }
    }
}

my class CParameter {
    has $.name;
    has $.type;

    method Str {
        defined($!name) ?? "$!type $!name" !! $!type;
    }
}

my class CSignature {
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

sub csignature(Signature $s) is export { CSignature.frm($s) }