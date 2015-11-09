# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use TinyCC::CTypes;
use TinyCC::NC;

unit class TinyCC::API;

my class TCCState is repr<CPointer> {
    use nqp;
    method new($value) { nqp::box_i(nqp::unbox_i($value), TCCState) }
    method Int { nqp::unbox_i(self) }
    method gist { "TCCState|{ self.Int.base(16) }" }
    method perl { "TCCState.new({ self.Int.base(16) })" }
}

my constant cstr = Blob;
my constant cstrarray = cptr; # FIXME
my constant ccallback = cptr; # FIXME

has &.tcc_new;
has &.tcc_delete;
has &.tcc_set_lib_path;
has &.tcc_set_error_func;
has &.tcc_set_options;
has &.tcc_add_include_path;
has &.tcc_add_sysinclude_path;
has &.tcc_define_symbol;
has &.tcc_undefine_symbol;
has &.tcc_add_file;
has &.tcc_compile_string;
has &.tcc_set_output_type;
has &.tcc_add_library_path;
has &.tcc_add_library;
has &.tcc_add_symbol;
has &.tcc_output_file;
has &.tcc_run;
has &.tcc_relocate;
has &.tcc_get_symbol;

method new($lib) {
    self.bless(
        tcc_new => nc.bind(:$lib,
            'tcc_new', :(--> TCCState)),

        tcc_delete => nc.bind(:$lib,
            'tcc_delete', :(TCCState)),

        tcc_set_lib_path => nc.bind(:$lib,
            'tcc_set_lib_path', :(TCCState, cstr)),

        tcc_set_error_func => nc.bind(:$lib,
            'tcc_set_error_func', :(TCCState, cptr, ccallback)),

        tcc_set_options => nc.bind(:$lib,
            'tcc_set_options', :(TCCState, cstr)),

        tcc_add_include_path => nc.bind(:$lib,
            'tcc_add_include_path', :(TCCState, cstr)),

        tcc_add_sysinclude_path => nc.bind(:$lib,
            'tcc_add_sysinclude_path', :(TCCState, cstr)),

        tcc_define_symbol => nc.bind(:$lib,
            'tcc_define_symbol', :(TCCState, cstr, cstr)),

        tcc_undefine_symbol => nc.bind(:$lib,
            'tcc_undefine_symbol', :(TCCState, cstr)),

        tcc_add_file => nc.bind(:$lib,
            'tcc_add_file', :(TCCState, cstr, cint)),

        tcc_compile_string => nc.bind(:$lib,
            'tcc_compile_string', :(TCCState, cstr)),

        tcc_set_output_type => nc.bind(:$lib,
            'tcc_set_output_type', :(TCCState, cint)),

        tcc_add_library_path => nc.bind(:$lib,
            'tcc_add_library_path', :(TCCState, cstr)),

        tcc_add_library => nc.bind(:$lib,
            'tcc_add_library', :(TCCState, cstr)),

        tcc_add_symbol => nc.bind(:$lib,
            'tcc_add_symbol', :(TCCState, cstr, cptr)),

        tcc_output_file => nc.bind(:$lib,
            'tcc_output_file', :(TCCState, cstr)),

        tcc_run => nc.bind(:$lib,
            'tcc_run', :(TCCState, cint, cstrarray)),

        tcc_relocate => nc.bind(:$lib,
            'tcc_relocate', :(TCCState, cptr)),

        tcc_get_symbol => nc.bind(:$lib,
            'tcc_get_symbol', :(TCCState, cstr)),
    );
}
