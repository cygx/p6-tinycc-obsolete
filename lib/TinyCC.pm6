# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use nqp;
use NativeCall;

class TCCState is repr('CPointer') {
    method new($value) {
        nqp::box_i(nqp::unbox_i(nqp::decont($value)), TCCState);
    }

    method Numeric { nqp::unbox_i(self) }
    method !hexval { sprintf '0x%x', +self }

    method gist { "TCCState<{ self!hexval }>" }
    method perl { "TCCState.new({ self!hexval })" }
}

enum TCCOutputType <UNSET MEM EXE DLL OBJ PREPROCESS>;

my \RELOCATE_AUTO = nqp::box_i(1, Pointer); # no constant as CPointer
                                            # cannot be serialized

role TCC[Map \api] {
    has TCCState $.state;
    has TCCOutputType $.output-type = UNSET;
    has Bool $!relocated = False;

    method new(:$state = api<new>()) {
        self.bless(:$state);
    }

    method delete {
        api<delete>($!state);
    }

    method setroot($path) {
        api<set_lib_path>($!state, $path);
        self;
    }

    multi method target($type) {
        $!output-type = $type;
        api<set_output_type>($!state, +$type);
        self;
    }

    multi method target(Bool :$MEM!) { self.target(MEM) }
    multi method target(Bool :$EXE!) { self.target(EXE) }
    multi method target(Bool :$DLL!) { self.target(DLL) }
    multi method target(Bool :$OBJ!) { self.target(OBJ) }

    method compile($code) {
        fail 'Compilation failure'
            if api<compile_string>($!state, $code) < 0;

        self;
    }

    method run(*@args) {
        fail "Already relocated"
            if $!relocated;

        self.target(:MEM)
            if $!output-type == UNSET;

        my $argc = +@args;
        my @argv := CArray[Str].new;
        @argv[$_] = @args[$_] for ^@args;
        @argv[$argc] = Nil;

        api<run>($!state, $argc, @argv);
    }

    multi method set(:$I, :$isystem, :$L, :$l, :$nostdlib) {
        fail sprintf "Unknown option%s %s passed",
            %_ > 1 ?? 's' !! '', %_.keys.map('-' ~ *).join(', ')
            if %_;

        api<add_include_path>($!state, $_) for $I // Empty;
        api<add_sysinclude_path>($!state, $_) for $isystem // Empty;
        api<add_library_path>($!state, $_) for $L // Empty;
        api<add_library>($!state, $_) for $l // Empty;
        self.set('-nostdlib') if $nostdlib;
        self;
    }

    multi method set($opts) {
        api<set_options>($!state, $opts);
        self;
    }

    multi method add(:$bin, :$c, :$asm, :$asmpp) {
        api<add_file>($!state, $_, 1) for $bin // Empty;
        api<add_file>($!state, $_, 2) for $c // Empty;
        api<add_file>($!state, $_, 3) for $asm // Empty;
        api<add_file>($!state, $_, 4) for $asmpp // Empty;
        self;
    }

    multi method add(*@srcfiles) {
        api<add_file>($!state, $_, 2) for @srcfiles;
        self;
    }

    method define(*%defs) {
        api<define_symbol>($!state, .key, .value) for %defs;
        self;
    }

    method undef(*@defs) {
        api<undefine_symbol>($!state, $_) for @defs;
        self;
    }

    method declare(*%symbols) {
        api<add_symbol>($!state, .key, .value) for %symbols;
        self;
    }

    method relocate($ptr = RELOCATE_AUTO) {
        api<relocate>($!state, $ptr);
        $!relocated = True;
        self;
    }

    method calcmemreq {
        fail "Invalid operation for output type $!output-type"
            unless $!output-type == MEM;

        api<relocate>($!state, Nil);
    }

    method lookup($symbol) {
        fail "Not relocated" unless $!relocated;
        api<get_symbol>($!state, $symbol);
    }

    method dump($file) {
        fail "Invalid operation for output type $!output-type"
            unless $!output-type == EXE | DLL | OBJ;

        fail "Already relocated"
            if $!relocated;

        fail "Failed to write output to '$file'"
            if api<output_file>($!state, $file) < 0;
    }

    method catch(&cb, :$payload) {
        api<set_error_func>($!state, $payload, &cb);
        self;
    }
}

sub tcc_new(--> TCCState) { * }
sub tcc_delete(TCCState) { * }
sub tcc_set_lib_path(TCCState, Str) { * }
sub tcc_set_error_func(TCCState, Pointer, &cb (Pointer, Str)) { * }
sub tcc_set_options(TCCState, Str --> int32) { * }
sub tcc_add_include_path(TCCState, Str --> int32) { * }
sub tcc_add_sysinclude_path(TCCState, Str --> int32) { * }
sub tcc_define_symbol(TCCState, Str, Str) { * }
sub tcc_undefine_symbol(TCCState, Str) { * }
sub tcc_add_file(TCCState, Str, int32 --> int32) { * }
sub tcc_compile_string(TCCState, Str --> int32) { * }
sub tcc_set_output_type(TCCState, int32 --> int32) { * }
sub tcc_add_library_path(TCCState, Str --> int32) { * }
sub tcc_add_library(TCCState, Str --> int32) { * }
sub tcc_add_symbol(TCCState, Str, Pointer --> int32) { * }
sub tcc_output_file(TCCState, Str --> int32) { * }
sub tcc_run(TCCState, int32, CArray[Str] --> int32) { * }
sub tcc_relocate(TCCState, Pointer --> int32) { * }
sub tcc_get_symbol(TCCState, Str --> Pointer) { * }

sub EXPORT(*@args) {
    constant API = [ OUTER::.keys.grep(/^\&tcc_/) ];

    for @args ||= %*ENV<LIBTCC> // 'libtcc' -> $native {
        my $state = try trait_mod:<is>(&tcc_new.clone, :$native).();
        next unless defined $state;

        return Map.new('tcc' => TCC[
            Map.new(API.map({
                .substr(5) => trait_mod:<is>(::($_).clone, :$native)
            }))
        ].new(:$state));
    }

    die 'Failed to load TinyCC from ' ~ @args.map("'" ~ * ~ "'").join(', ');
}
