# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use nqp;

sub csizeof(\value) is export { value.?CSIZE // nqp::nativecallsizeof(value) }

my class CPtr { ... }
my class CArray { ... }
my class CScalarRef { ... }

my class cvoid is repr<Uninstantiable> is export {}

my role Typed[::T] { method of { T } }

my role Sized[\elems] {
    method elems { elems }
    method CSIZE { elems * csizeof self.of }
}

my role RawArray {
    method perl { "{ self.^name }.from([...])" }
    method from(@values) {
        my $value := self.bless;

        my uint $elems = +@values;
        loop (my uint $i = $elems; $i-- > 0;) {
            $value[$i] = @values[$i];
        }

        CArray.new(:$value) but (Sized[$elems], Positional[self.of]);
    }
}

my role RawIntegerArray is RawArray {
    method AT-POS(uint \pos) { nqp::atpos_i(self, pos) }
    method ASSIGN-POS(uint \pos, \value) { nqp::bindpos_i(self, pos, value) }
}

my role RawFloatingArray is RawArray {
    method AT-POS(uint \pos) { nqp::atpos_n(self, pos) }
    method ASSIGN-POS(uint \pos, \value) { nqp::bindpos_n(self, pos, value) }
}

my native cchar is Int is ctype<char> is repr<P6int> is export {}
my class RawCharArray is repr<CArray> is array_type(cchar) {
    also does Positional[cchar];
    also does RawIntegerArray;
}
proto cchar(*@) is export {*}
multi cchar(Int() $value) { RawCharArray.from(@$value).ptr }
multi cchar(List $list) { RawCharArray.from($list>>.Int) }
multi cchar(*@values) { &cchar(@values.List) }

my native cuchar is Int is ctype<char> is repr<P6int> is unsigned is export {}
my class RawUCharArray is repr<CArray> is array_type(cuchar) {
    also does Positional[cuchar];
    also does RawIntegerArray;
}
proto cuchar(*@) is export {*}
multi cuchar(Int() $value) { RawUCharArray.from(@$value).ptr }
multi cuchar(List $list) { RawUCharArray.from($list>>.Int) }
multi cuchar(*@values) { &cuchar(@values.List) }

my native cshort is Int is ctype<short> is repr<P6int> is export {}
my class RawShortArray is repr<CArray> is array_type(cshort) {
    also does Positional[cshort];
    also does RawIntegerArray;
}
proto cshort(*@) is export {*}
multi cshort(Int() $value) { RawShortArray.from(@$value).ptr }
multi cshort(List $list) { RawShortArray.from($list>>.Int) }
multi cshort(*@values) { &cshort(@values.List) }

my native cushort is Int is ctype<short> is repr<P6int> is unsigned is export {}
my class RawUShortArray is repr<CArray> is array_type(cushort) {
    also does Positional[cushort];
    also does RawIntegerArray;
}
proto cushort(*@) is export {*}
multi cushort(Int() $value) { RawUShortArray.from(@$value).ptr }
multi cushort(List $list) { RawUShortArray.from($list>>.Int) }
multi cushort(*@values) { &cushort(@values.List) }

my native cint is Int is ctype<int> is repr<P6int> is export {}
my class RawIntArray is repr<CArray> is array_type(cint) {
    also does Positional[cint];
    also does RawIntegerArray;
}
proto cint(*@) is export {*}
multi cint(Int() $value) { RawIntArray.from(@$value).ptr }
multi cint(List $list) { RawIntArray.from($list>>.Int) }
multi cint(*@values) { &cint(@values.List) }

my native cuint is Int is ctype<int> is repr<P6int> is unsigned is export {}
my class RawUIntArray is repr<CArray> is array_type(cuint) {
    also does Positional[cuint];
    also does RawIntegerArray;
}
proto cuint(*@) is export {*}
multi cuint(Int() $value) { RawUIntArray.from(@$value).ptr }
multi cuint(List $list) { RawUIntArray.from($list>>.Int) }
multi cuint(*@values) { &cuint(@values.List) }

my native clong is Int is ctype<long> is repr<P6int> is export {}
my class RawLongArray is repr<CArray> is array_type(clong) {
    also does Positional[clong];
    also does RawIntegerArray;
}
proto clong(*@) is export {*}
multi clong(Int() $value) { RawLongArray.from(@$value).ptr }
multi clong(List $list) { RawLongArray.from($list>>.Int) }
multi clong(*@values) { &clong(@values.List) }

my native culong is Int is ctype<long> is repr<P6int> is unsigned is export {}
my class RawULongArray is repr<CArray> is array_type(culong) {
    also does Positional[culong];
    also does RawIntegerArray;
}
proto culong(*@) is export {*}
multi culong(Int() $value) { RawULongArray.from(@$value).ptr }
multi culong(List $list) { RawULongArray.from($list>>.Int) }
multi culong(*@values) { &culong(@values.List) }

my native cllong is Int is ctype<longlong> is repr<P6int> is export {}
my class RawLLongArray is repr<CArray> is array_type(cllong) {
    also does Positional[cllong];
    also does RawIntegerArray;
}
proto cllong(*@) is export {*}
multi cllong(Int() $value) { RawLLongArray.from(@$value).ptr }
multi cllong(List $list) { RawLLongArray.from($list>>.Int) }
multi cllong(*@values) { &cllong(@values.List) }

my native cullong is Int is ctype<longlong> is repr<P6int> is unsigned
    is export {}
my class RawULLongArray is repr<CArray> is array_type(cullong) {
    also does Positional[cullong];
    also does RawIntegerArray;
}
proto cullong(*@) is export {*}
multi cullong(Int() $value) { RawULLongArray.from(@$value).ptr }
multi cullong(List $list) { RawULLongArray.from($list>>.Int) }
multi cullong(*@values) { &cullong(@values.List) }

my native cfloat is Num is ctype<float> is repr<P6num> is export {}
my class RawFloatArray is repr<CArray> is array_type(cfloat) {
    also does Positional[cfloat];
    also does RawFloatingArray;
}
proto cfloat(*@) is export {*}
multi cfloat(Num() $value) { RawFloatArray.from(@$value).ptr }
multi cfloat(List $list) { RawFloatArray.from($list>>.Num) }
multi cfloat(*@values) { &cfloat(@values.List) }

my native cdouble is Num is ctype<double> is repr<P6num> is export {}
my class RawDoubleArray is repr<CArray> is array_type(cdouble) {
    also does Positional[cdouble];
    also does RawFloatingArray;
}
proto cdouble(*@) is export {*}
multi cdouble(Num() $value) { RawDoubleArray.from(@$value).ptr }
multi cdouble(List $list) { RawDoubleArray.from($list>>.Num) }
multi cdouble(*@values) { &cdouble(@values.List) }

my constant cfloat32 is export = cfloat;
sub cfloat32(|c) is export { &cfloat(|c) }
my constant cfloat64 is export = cdouble;
sub cfloat64(|c) is export { &cdouble(|c) }

my constant INTTYPEMAP = Map.new(
    map { csizeof($_) * 8 => $_ }, cllong, clong, cint, cshort, cchar
);

my constant UINTTYPEMAP = Map.new(
    map { csizeof($_) * 8 => $_ }, cullong, culong, cuint, cushort, cuchar
);

my constant INTSUBMAP = Map.new(
    INTTYPEMAP.pairs.map: { .key => ::("\&{ .value.^name }") }
);

my constant UINTSUBMAP = Map.new(
    UINTTYPEMAP.pairs.map: { .key => ::("\&{ .value.^name }") }
);

my constant cint8  = INTTYPEMAP<8>;
my constant cint16 = INTTYPEMAP<16>;
my constant cint32 = INTTYPEMAP<32>;
my constant cint64 = INTTYPEMAP<64>;

my constant cuint8  = UINTTYPEMAP<8>;
my constant cuint16 = UINTTYPEMAP<16>;
my constant cuint32 = UINTTYPEMAP<32>;
my constant cuint64 = UINTTYPEMAP<64>;

my constant &cint8  = INTSUBMAP<8>;
my constant &cint16 = INTSUBMAP<16>;
my constant &cint32 = INTSUBMAP<32>;
my constant &cint64 = INTSUBMAP<64>;

my constant &cuint8  = UINTSUBMAP<8>;
my constant &cuint16 = UINTSUBMAP<16>;
my constant &cuint32 = UINTSUBMAP<32>;
my constant &cuint64 = UINTSUBMAP<64>;

my class cptr is repr<CPointer> is export {
    method Int { nqp::unbox_i(self) }
    method perl { "\&cptr(0x{ self.Int.base(16).lc })" }
    method Str { self.perl }

    multi method to(cptr:D: Mu:U \type) {
        CPtr.new(value => self) but Typed[type];
    }

    multi method to(cptr:U: Mu:U \type) {
        CPtr but Typed[type];
    }
}

my constant PTRSIZE = csizeof cptr;

my constant cintptr is export =  INTTYPEMAP{ PTRSIZE * 8 };
my constant cuintptr is export = UINTTYPEMAP{ PTRSIZE * 8 };
my constant &cintptr =  INTSUBMAP{ PTRSIZE * 8 };
my constant &cuintptr = UINTSUBMAP{ PTRSIZE * 8 };

my class RawPointerArray is repr<CArray> is array_type(cuintptr) { ... }

proto cptr(*@) is export {*}
multi cptr(Int:D \address) { nqp::box_i(address, cptr) }
multi cptr(Cool:D \address where .Numeric == .Int) {
    nqp::box_i(address.Int, cptr);
}
multi cptr(CPtr:D \ptr) { ptr.raw }
multi cptr(CArray:D \array) { array.rawptr }
multi cptr(Mu:U \type) { cptr.to(type) }
multi cptr(List $list) { RawPointerArray.from($list) }
multi cptr(*@values) { &cptr(@values.List) }

my class RawPointerArray is RawArray {
    also does Positional[cptr];

    method AT-POS(uint \pos) {
        nqp::box_i(nqp::box_i(nqp::atpos_i(self, pos), cptr), cptr);
    }

    method ASSIGN-POS(uint \pos, \value) {
        nqp::bindpos_i(self, pos, nqp::unbox_i(value));
    }
}

my class CScalarRef {
    has $.value;

    method FETCH { $!value.AT-POS(0) }
    method STORE(\value) { $!value.ASSIGN-POS(0, value) }

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
            nqp::setcontspec(CScalarRef,  'code_pair', $pair);
            Mu;
            __END__
        }

        my \type = nqp::decont(CArray.for(ptr.of));
        my \value = nqp::nativecallcast(type, type, nqp::decont(ptr.raw));
        my \ref = nqp::create(CScalarRef);
        nqp::bindattr(ref, CScalarRef, '$!value', value);

        ref;
    }

    method ptr {
        nqp::nativecallcast(cptr, cptr, nqp::decont($!value)).to(self.of);
    }
}

my class CArray does Iterable {
    has $.value handles <AT-POS ASSIGN-POS>;

    method gist { "\&{ self.of.^name }({ join ', ', self })" }

    method iterator {
        my uint $elems = self.elems;
        my \array = $!value;
        .new given class :: does Iterator {
            has uint $!i = 0;
            method pull-one {
                $!i < $elems ?? array.AT-POS($!i++) !! IterationEnd;
            }
        };
    }

    method ptr { self.rawptr.to(self.of) }
    method rawptr { nqp::nativecallcast(cptr, cptr, nqp::decont($!value)) }

    method for(CArray:U: Mu:U $_) {
        when cchar   { RawCharArray }
        when cuchar  { RawUCharArray }
        when cshort  { RawShortArray }
        when cushort { RawUShortArray }
        when cint    { RawIntArray }
        when cuint   { RawUIntArray }
        when clong   { RawLongArray }
        when culong  { RawULongArray }
        when cllong  { RawLLongArray }
        when cullong { RawULLongArray }
        when cfloat  { RawFloatArray }
        when cdouble { RawDoubleArray }
        when cptr    { RawPointerArray }
        default { die "CArray does not support type { .^name }" }
    }
}

my class CPtr {
    has $.value is box_target handles <Int to>;

    method CSIZE { PTRSIZE }
    method raw { $!value }
    method lv is rw { CScalarRef.new(self) }

    method rv {
        given ~self.of.REPR {
            when 'CPointer' { &cptr(self.to(cuintptr).rv).to(self.of) }

            when 'P6int' {
                nqp::nativecallcast(
                    nqp::decont(self.of), Int, nqp::decont($!value));
            }

            when 'P6num' {
                nqp::nativecallcast(
                    nqp::decont(self.of), Num, nqp::decont($!value));
            }

            default {
                die "Cannot dereference pointers of type { self.of.^name }";
            }
        }
    }
}

proto ctype(Mu:U) is export {*}
multi ctype(Int $ where cchar) { 'signed char' }
multi ctype(Int $ where cshort) { 'short' }
multi ctype(Int $ where cint) { 'int' }
multi ctype(Int $ where clong) { 'long' }
multi ctype(Int $ where cllong) { 'long long' }
multi ctype(Int $ where cuchar) { 'unsigned char' }
multi ctype(Int $ where cushort) { 'unsigned short' }
multi ctype(Int $ where cuint) { 'unsigned' }
multi ctype(Int $ where culong) { 'unsigned long' }
multi ctype(Int $ where cullong) { 'unsigned long long' }
multi ctype(Num $ where cfloat) { 'float' }
multi ctype(Num $ where cdouble) { 'double' }
multi ctype(Blob) { 'char *' }
multi ctype(Mu $ where .REPR eq 'CPointer') { 'void*' }
multi ctype(Mu $ where .REPR eq 'VMArray') { 'void*' } # FIXME?

proto cnativetype(Mu:U) is export {*}
multi cnativetype(Int $ where cchar) { 'char' }
multi cnativetype(Int $ where cshort) { 'short' }
multi cnativetype(Int $ where cint) { 'int' }
multi cnativetype(Int $ where clong) { 'long' }
multi cnativetype(Int $ where cllong) { 'longlong' }
multi cnativetype(Int $ where cuchar) { 'uchar' }
multi cnativetype(Int $ where cushort) { 'ushort' }
multi cnativetype(Int $ where cuint) { 'uint' }
multi cnativetype(Int $ where culong) { 'ulong' }
multi cnativetype(Int $ where cullong) { 'ulonglong' }
multi cnativetype(Num $ where cfloat) { 'float' }
multi cnativetype(Num $ where cdouble) { 'double' }
multi cnativetype(Blob) { 'vmarray' }
multi cnativetype(Mu $ where nqp::decont($_) =:= Mu) { 'void' }
multi cnativetype(Mu $ where .REPR eq 'CPointer') { 'cpointer' }
multi cnativetype(Mu $ where .REPR eq 'VMArray') { 'vmarray' }
multi cnativetype(Mu $ where .REPR eq 'Uninstantiable') { 'void' }

sub EXPORT {
    BEGIN Map.new(
        '&cint8'    => &cint8,
        '&cint16'   => &cint16,
        '&cint32'   => &cint32,
        '&cint64'   => &cint64,
        '&cintptr'  => &cintptr,
        '&cuint8'   => &cuint8,
        '&cuint16'  => &cuint16,
        '&cuint32'  => &cuint32,
        '&cuint64'  => &cuint64,
        '&cuintptr' => &cuintptr,
    );
}
