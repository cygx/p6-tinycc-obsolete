# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use nqp;
use NativeCall;

my \uintptr = do given nativesizeof(Pointer) {
    when 4 { uint32 }
    when 8 { uint64 }
    default { die }
}

my class nc is export {
    method array(Mu:U \type, *@args) { CArray[type].new(@args) }
    method cast(Mu:U \type, \value) { nativecast type, value }
    method cast-to-ptr(\value) { nativecast Pointer, value }
    method cast-to-ptr-of(Mu:U \type, \value) { nativecast Pointer[type], value; }
    method cast-to-array(Mu:U \type, \value) { nativecast(CArray[type], value) }
    method cast-ptr-to-array(\ptr) { nativecast(CArray[ptr.of], ptr) }

    method deref-ptr-of-ptr(\ptr) {
        nqp::box_i(ptr.of,
            nativecast(uintptr,
                nqp::box_i(Pointer[uintptr], nqp::unbox_i(ptr))));
    }
}

my class TCCState is repr<CPointer> is export {}

sub tcc_new(--> TCCState) {*}
sub tcc_delete(TCCState) {*}
sub tcc_set_lib_path(TCCState, Str) {*}
sub tcc_set_error_func(TCCState, Pointer, &cb (Pointer, Str)) {*}
sub tcc_set_options(TCCState, Str --> int32) {*}
sub tcc_add_include_path(TCCState, Str --> int32) {*}
sub tcc_add_sysinclude_path(TCCState, Str --> int32) {*}
sub tcc_define_symbol(TCCState, Str, Str) {*}
sub tcc_undefine_symbol(TCCState, Str) {*}
sub tcc_add_file(TCCState, Str, int32 --> int32) {*}
sub tcc_compile_string(TCCState, Str --> int32) {*}
sub tcc_set_output_type(TCCState, int32 --> int32) {*}
sub tcc_add_library_path(TCCState, Str --> int32) {*}
sub tcc_add_library(TCCState, Str --> int32) {*}
sub tcc_add_symbol(TCCState, Str, Pointer --> int32) {*}
sub tcc_output_file(TCCState, Str --> int32) {*}
sub tcc_run(TCCState, int32, CArray[Str] --> int32) {*}
sub tcc_relocate(TCCState, Pointer --> int32) {*}
sub tcc_get_symbol(TCCState, Str --> Pointer) {*}

my constant API is export = [ OUTER::.keys.grep(/^\&tcc_/) ];

my class api is export {
    method new-state($native) {
        trait_mod:<is>(&tcc_new.clone, :$native).();
    }

    method load($native) {
        Map.new(API.map: {
            .substr(5) => trait_mod:<is>(::($_).clone, :$native);
        });
    }

    method RELOCATE_AUTO {
        use nqp;
        once nqp::box_i(1, Pointer);
    }
}
