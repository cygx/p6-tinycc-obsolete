# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use v6;
use nqp;

# -- messages
proto csize(Mu $_, *%_) is export { .?CSIZE(|%_) // {*} }
proto ctypeclass(Mu $_, *%_) is export { .?CTYPECLASS(|%_) // {*} }

proto cunbox(Mu:D $_, *%_) is export { .?CUNBOX(|%_) // {*} }
proto crawptr(Mu:D $_, *%_) is export { .?CRAWPTR(|%_) // {*} }
proto ceval(Mu:D $_, *%_) is export { .?CEVAL(|%_) // {*} }

proto cdecl(Mu:U $_, Str $name = '', *%_) is export { .?CDECL($name, |%_) // {*} }
proto crawarraytype(Mu:U $_, *%_) is export { .?CRAWARRAYTYPE(|%_) // {*} }
proto cvalue(Mu:U $_, $value, *%_) is export { .?CVALUE($value, |%_) // {*} }
proto carray(Mu:U $_, *@_, *%_) is export { .?CARRAY(@_, |%_) // {*} }

# -- a dumb pointer
my class RawPtr is repr<CPointer> {
    method new(Mu \address) { nqp::box_i(nqp::unbox_i(address), self) }
    method Numeric { nqp::unbox_i(self) }
    method Int { +self }
    method gist { "ptr|{ +self }" }
    method perl { "RawPtr.from({ +self })" }
}

my constant cvoidptr is export = RawPtr;

# -- some constants
my constant CHAR_BIT = 8;
my constant PTRSIZE = nqp::nativecallsizeof(RawPtr);
my constant PTRBITS = CHAR_BIT * PTRSIZE;

my constant INTMAP = Map.new(
    map { CHAR_BIT * nqp::nativecallsizeof($_) => .^name },
        my native longlong is repr<P6int> is ctype<longlong> {},
        my native long is repr<P6int> is ctype<long> {},
        my native int is repr<P6int> is ctype<int> {},
        my native short is repr<P6int> is ctype<short> {},
        my native char is repr<P6int> is ctype<char> {});

my constant NUMMAP = Map.new(
    map { CHAR_BIT * nqp::nativecallsizeof($_) => .^name },
#        my native longdouble is repr<P6num> is ctype<longdouble> {},
        my native double is repr<P6num> is ctype<double> {},
        my native float is repr<P6num> is ctype<float> {});


# -- some subs useful for what comes next
sub ni($_, $size) { .HOW.WHAT =:= int.HOW.WHAT && .HOW.nativesize($_) == $size && !.HOW.unsigned($_) }
sub nu($_, $size) { .HOW.WHAT =:= int.HOW.WHAT && .HOW.nativesize($_) == $size && ?.HOW.unsigned($_) }
sub nn($_, $size) { .HOW.WHAT =:= int.HOW.WHAT && .HOW.nativesize($_) == $size }

# -- subsets useful for matching native types
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
my subset VMArray of Mu is export where .REPR eq 'VMArray';

# -- numeric types
my native cchar is Int is ctype<char> is repr<P6int> is export {}
my native cshort is Int is ctype<short> is repr<P6int> is export {}
my native cint is Int is ctype<int> is repr<P6int> is export {}
my native clong is Int is ctype<long> is repr<P6int> is export {}
my native cllong is Int is ctype<longlong> is repr<P6int> is export {}

my native cuchar is Int is ctype<char> is unsigned is repr<P6int> is export {}
my native cushort is Int is ctype<short> is unsigned is repr<P6int> is export {}
my native cuint is Int is ctype<int> is unsigned is repr<P6int> is export {}
my native culong is Int is ctype<long> is unsigned is repr<P6int> is export {}
my native cullong is Int is ctype<longlong> is unsigned is repr<P6int> is export {}

my native cint8 is Int is nativesize(8) is repr<P6int> is export {}
my native cint16 is Int is nativesize(16) is repr<P6int> is export {}
my native cint32 is Int is nativesize(32) is repr<P6int> is export {}
my native cint64 is Int is nativesize(64) is repr<P6int> is export {}
# my native cint128 is Int is nativesize(128) is repr<P6int> is export {}
my native cintptr is Int is nativesize(PTRBITS) is repr<P6int> is export {}

my native cuint8 is Int is nativesize(8) is unsigned is repr<P6int> is export {}
my native cuint16 is Int is nativesize(16) is unsigned is repr<P6int> is export {}
my native cuint32 is Int is nativesize(32) is unsigned is repr<P6int> is export {}
my native cuint64 is Int is nativesize(64) is unsigned is repr<P6int> is export {}
# my native cuint128 is Int is nativesize(128) is unsigned is repr<P6int> is export {}
my native cuintptr is Int is nativesize(PTRBITS) is unsigned is repr<P6int> is export {}

my native cfloat is Num is ctype<float> is repr<P6num> is export {}
my native cdouble is Num is ctype<double>  is repr<P6num> is export {}
# my native cldouble is Num is ctype<longdouble>  is repr<P6num> is export {}

my native cfloat32 is Num is nativesize(32) is repr<P6num> is export {}
my native cfloat64 is Num is nativesize(64) is repr<P6num> is export {}

# -- a smart pointer
my class void is repr<Uninstantiable> {
    method CDECL($name) { $name ?? "void $name" !! 'void' }
}

my class ScalarRef { ... }

my role BoxedPtr[::T = void] {
    has $.raw handles <Int>; # is box_target -- ???

    method CSIZE { PTRSIZE }
    method CTYPECLASS { 'cpointer' }
    method CDECL($name) { cdecl(T, "*$name") }
    method CEVAL { "({ cdecl($, '*') }){ +self }" }
    method CUNBOX { $!raw }

    multi method from(Int \address) { self.new(raw => RawPtr.new(address)) }
    multi method from(Mu \obj) { self.new(raw => crawptr(obj)) }
    method Numeric { +self }
    method gist { self.CEVAL }
    method to(Mu:U \type) { BoxedPtr[type].new(:$!raw) }
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

# -- a scalar reference
my class ScalarRef {
    has $.ptr;
    has $.raw;

    method FETCH { $!raw.AT-POS(0) }
    method STORE(\value) { $!raw.ASSIGN-POS(0, value) }

    method new(BoxedPtr \ptr) {
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

        my \type = nqp::decont(crawarraytype(ptr.of));
        my \raw = nqp::nativecallcast(type, type, nqp::decont(ptr.raw));
        my \ref = nqp::create(ScalarRef);
        nqp::bindattr(ref, ScalarRef, '$!raw', raw);
        nqp::bindattr(ref, ScalarRef, '$!ptr', ptr);

        ref;
    }
}

# -- a boxed array
my role BoxedArray[::T, UInt \elems] does Positional[T] {
    has $.raw handles <AT-POS ASSIGN-POS>;

    method CSIZE { self.elems * csize(nqp::decont(T)) }
    method CTYPECLASS { 'carray' }
    method CDECL($name) { cdecl(T, $name ~ "[{ elems }]", |%_) }
    method CUNBOX { $!raw }

    method ptr { BoxedPtr[T].from($!raw) }
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

# -- raw arrays
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

my class CCharArray is repr<CArray> is array_type(cchar) does IntegerArray[cchar] {}
my class CShortArray is repr<CArray> is array_type(cshort) does IntegerArray[cshort] {}
my class CIntArray is repr<CArray> is array_type(cint) does IntegerArray[cint] {}
my class CLongArray is repr<CArray> is array_type(clong) does IntegerArray[clong] {}
my class CLLongArray is repr<CArray> is array_type(cllong) does IntegerArray[cllong] {}

my class CUCharArray is repr<CArray> is array_type(cuchar) does IntegerArray[cuchar] {}
my class CUShortArray is repr<CArray> is array_type(cushort) does IntegerArray[cushort] {}
my class CUIntArray is repr<CArray> is array_type(cuint) does IntegerArray[cuint] {}
my class CULongArray is repr<CArray> is array_type(culong) does IntegerArray[clong] {}
my class CULLongArray is repr<CArray> is array_type(cullong) does IntegerArray[cullong] {}

my class CInt8Array is repr<CArray> is array_type(cint8) does IntegerArray[cint8] {}
my class CInt16Array is repr<CArray> is array_type(cint16) does IntegerArray[cint16] {}
my class CInt32Array is repr<CArray> is array_type(cint32) does IntegerArray[cint32] {}
my class CInt64Array is repr<CArray> is array_type(cint64) does IntegerArray[cint64] {}
# my class CInt128Array is repr<CArray> is array_type(cint128) does IntegerArray[cint128] {}

my class CUInt8Array is repr<CArray> is array_type(cuint8) does IntegerArray[cuint8] {}
my class CUInt16Array is repr<CArray> is array_type(cuint16) does IntegerArray[cuint16] {}
my class CUInt32Array is repr<CArray> is array_type(cuint32) does IntegerArray[cuint32] {}
my class CUInt64Array is repr<CArray> is array_type(cuint64) does IntegerArray[cuint64] {}
# my class CUInt128Array is repr<CArray> is array_type(cuint128) does IntegerArray[cuint128] {}

my class CFloatArray is repr<CArray> is array_type(cfloat) does FloatingArray[cfloat] {}
my class CDoubleArray is repr<CArray> is array_type(cdouble) does FloatingArray[cdouble] {}
# my class CLDoubleArray is repr<CArray> is array_type(cldouble) does FloatingArray[cldouble] {}

my class CFloat32Array is repr<CArray> is array_type(cfloat32) does FloatingArray[cfloat32] {}
my class CFloat64Array is repr<CArray> is array_type(cfloat64) does FloatingArray[cfloat64] {}

# -- preliminary helper functions
# -- likely to change with future revisions

sub cstrings(*@values, :$enc = 'utf8', :$stage) is export {
    Blob[cuintptr].new(|@values.map({
        my $blob := "$_\0".encode($enc);
        .push($blob) with $stage;
        RawPtr.from($blob)
    }), 0);
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
            returns => cdecl($sig.returns),
            params => $sig.params.grep(*.positional).map({
                CParameter.new(name => .name, type => cdecl(.type));
            }),
        );
    }

    method prototype($name) {
        "{ $!returns } { $name }({ @!params ?? @!params.join(', ') !! 'void' })"
    }
}

sub csignature(Signature $s) is export { CSignature.from($s) }

# -- core functionality
proto cbind(Mu $, Signature $sig, *%) is export {*}
proto cinvoke(Mu $, Signature $sig, *@, *%) is export {*}

my class Callsite is repr<NativeCall> {}

multi cbind(Str $name, Signature $sig, Str :$lib) {
    my $argtypes := nqp::list();
    nqp::push($argtypes, nqp::hash('type', ctypeclass(.type)))
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
        nqp::hash('type', ctypeclass($sig.returns) // 'void'),
    );

    sub (|args) {
        fail "Arguments { args.gist } do not match signature { $sig.gist }"
            unless args ~~ $sig;

        my $args := nqp::list();
        nqp::push($args, cunbox($_))
            for args.list;

        nqp::nativecall($rtype, $cs, $args);
    }
}

multi cinvoke(Str $name, Signature $sig, Capture $args, Str :$lib) { cbind($name, $sig, :$lib).(|$args) }
multi cinvoke(Str $name, Signature $sig, *@args, Str :$lib) { cbind($name, $sig, :$lib).(|@args) }

# -- responses
multi csize(Mu $_, *%) { nqp::nativecallsizeof($_) }

multi ctypeclass(CChar) { 'char' }
multi ctypeclass(CShort) { 'short' }
multi ctypeclass(CInt) { 'int' }
multi ctypeclass(CLong) { 'long' }
multi ctypeclass(CLLong) { 'longlong' }

multi ctypeclass(CUChar) { 'uchar' }
multi ctypeclass(CUShort) { 'ushort' }
multi ctypeclass(CUInt) { 'uint' }
multi ctypeclass(CULong) { 'ulong' }
multi ctypeclass(CULLong) { 'ulonglong' }

multi ctypeclass(CInt8) { BEGIN INTMAP<8> // Str }
multi ctypeclass(CInt16) { BEGIN INTMAP<16> // Str }
multi ctypeclass(CInt32) { BEGIN INTMAP<32> // Str }
multi ctypeclass(CInt64) { BEGIN INTMAP<64> // Str }
multi ctypeclass(CInt128) { BEGIN INTMAP<128> // Str }
# multi ctypeclass(CIntPtr) { BEGIN INTMAP{PTRBITS} // Str } -- dispatches to fixed-sized types
multi ctypeclass(CIntX $_) { INTMAP{ CHAR_BIT * nqp::nativecallsizeof($_) } // Str; }

multi ctypeclass(CUInt8) { BEGIN INTMAP<8> // Str andthen "u$_" }
multi ctypeclass(CUInt16) { BEGIN INTMAP<16> // Str andthen "u$_" }
multi ctypeclass(CUInt32) { BEGIN INTMAP<32> // Str andthen "u$_" }
multi ctypeclass(CUInt64) { BEGIN INTMAP<64> // Str andthen "u$_" }
multi ctypeclass(CUInt128) { BEGIN INTMAP<128> // Str andthen "u$_" }
# multi ctypeclass(CUIntPtr) { BEGIN INTMAP{PTRBITS} // Str andthen "u$_" } -- dispatches to fixed-sized types
multi ctypeclass(CUIntX $_) { (INTMAP{ CHAR_BIT * nqp::nativecallsizeof($_) } // Str) andthen "u$_" }

multi ctypeclass(CFloat) { 'float' }
multi ctypeclass(CDouble) { 'double' }
multi ctypeclass(CLDouble) { 'longdouble' }

multi ctypeclass(CFloat32) { BEGIN NUMMAP<32> // Str }
multi ctypeclass(CFloat64) { BEGIN NUMMAP<64> // Str }
multi ctypeclass(CFloatX $_) { NUMMAP{ CHAR_BIT * nqp::nativecallsizeof($_) } // Str }

multi ctypeclass(CPointer) { 'cpointer' }
multi ctypeclass(CArray) { 'carray' }
multi ctypeclass(VMArray) { 'vmarray' }

multi ctypeclass(Blob) { 'vmarray' }
multi ctypeclass(Str) { 'vmarray' } # -- unboxes to Blob

multi ctypeclass(Mu $_, *%) { fail .^name }

multi crawarraytype(CChar) { CCharArray }
multi crawarraytype(CShort) { CShortArray }
multi crawarraytype(CInt) { CIntArray }
multi crawarraytype(CLong) { CLongArray }
multi crawarraytype(CLLong) { CLLongArray }

multi crawarraytype(CUChar) { CUCharArray }
multi crawarraytype(CUShort) { CUShortArray }
multi crawarraytype(CUInt) { CUIntArray }
multi crawarraytype(CULong) { CULongArray }
multi crawarraytype(CULLong) { CULLongArray }

multi crawarraytype(CInt8) { CInt8Array }
multi crawarraytype(CInt16) { CInt16Array }
multi crawarraytype(CInt32) { CInt32Array }
multi crawarraytype(CInt64) { CInt64Array }
# multi crawarraytype(CInt128) { CInt128Array }

multi crawarraytype(CUInt8) { CUInt8Array }
multi crawarraytype(CUInt16) { CUInt16Array }
multi crawarraytype(CUInt32) { CUInt32Array }
multi crawarraytype(CUInt64) { CUInt64Array }
# multi crawarraytype(CUInt128) { CUInt128Array }

multi crawarraytype(CFloat) { CFloatArray }
multi crawarraytype(CDouble) { CDoubleArray }
# multi crawarraytype(CLDouble) { CLDoubleArray }
multi crawarraytype(CFloat32) { CFloat32Array }
multi crawarraytype(CFloat64) { CFloat64Array }

multi crawarraytype(Mu $_, *%) { fail .^name }

multi cunbox(Str \value) { "{value}\0".encode }
multi cunbox(Mu $_, *%) { $_ }

multi crawptr(Mu $_, *%) { nqp::nativecallcast(RawPtr, RawPtr, nqp::decont($_)) }

multi ceval(Numeric $_, *%) { .Str }
multi ceval(CPointer $_, *%) { "(void*){ nqp::unbox_i($_) }" }
multi ceval(Mu $_, *%) { fail .^name }

multi cdecl(Mu $_, Str $name?, *%) { fail .^name }

multi cvalue(Mu:U $_, $value, *%_) {
    my $array := crawarraytype($_, |%_).new;
    $array[0] = $value;
    BoxedPtr[$_].new(raw => crawptr($array, |%_));
}

multi carray(Mu:U $_, *@_, *%_) {
    my uint $n = +@_;
    my $raw := crawarraytype($_, |%_).new;
    my $boxed := BoxedArray[$_, $n].new;
    while ($n--) { $raw[$n] = @_[$n] }
    $boxed;
}
