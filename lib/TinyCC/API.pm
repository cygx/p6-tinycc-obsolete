# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use CTypes;

unit class TinyCC::API;

my class TCCState is repr<CPointer> is cvoidptr {
    method gist { "TCCState|{ self.Int.base(16) }" }
    method perl { "TCCState.new({ self.Int.base(16) })" }
}

my constant cptr = cvoidptr;
my constant cstr = Str;
my constant cstrarray = Blob[cuintptr];
my constant ccallback = cvoidptr;

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
        tcc_new => cbind(:$lib,
            'tcc_new', :(--> TCCState)),

        tcc_delete => cbind(:$lib,
            'tcc_delete', :(TCCState)),

        tcc_set_lib_path => cbind(:$lib,
            'tcc_set_lib_path', :(TCCState, cstr)),

        tcc_set_error_func => cbind(:$lib,
            'tcc_set_error_func', :(TCCState, cptr, &cb (cptr, cstr)),
            check => :(TCCState, cptr, &)),

        tcc_set_options => cbind(:$lib,
            'tcc_set_options', :(TCCState, cstr --> cint)),

        tcc_add_include_path => cbind(:$lib,
            'tcc_add_include_path', :(TCCState, cstr --> cint)),

        tcc_add_sysinclude_path => cbind(:$lib,
            'tcc_add_sysinclude_path', :(TCCState, cstr --> cint)),

        tcc_define_symbol => cbind(:$lib,
            'tcc_define_symbol', :(TCCState, cstr, cstr)),

        tcc_undefine_symbol => cbind(:$lib,
            'tcc_undefine_symbol', :(TCCState, cstr)),

        tcc_add_file => cbind(:$lib,
            'tcc_add_file', :(TCCState, cstr, cint --> cint)),

        tcc_compile_string => cbind(:$lib,
            'tcc_compile_string', :(TCCState, cstr --> cint)),

        tcc_set_output_type => cbind(:$lib,
            'tcc_set_output_type', :(TCCState, cint --> cint)),

        tcc_add_library_path => cbind(:$lib,
            'tcc_add_library_path', :(TCCState, cstr --> cint)),

        tcc_add_library => cbind(:$lib,
            'tcc_add_library', :(TCCState, cstr --> cint)),

        tcc_add_symbol => cbind(:$lib,
            'tcc_add_symbol', :(TCCState, cstr, cptr --> cint)),

        tcc_output_file => cbind(:$lib,
            'tcc_output_file', :(TCCState, cstr --> cint)),

        tcc_run => cbind(:$lib,
            'tcc_run', :(TCCState, cint, cstrarray --> cint)),

        tcc_relocate => cbind(:$lib,
            'tcc_relocate', :(TCCState, cptr --> cint)),

        tcc_get_symbol => cbind(:$lib,
            'tcc_get_symbol', :(TCCState, cstr --> cvoidptr)),
    );
}
