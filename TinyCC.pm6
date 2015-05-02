use nqp;
use NativeCall;

class TCCState is repr('CPointer') {
    method gist { "TCCState<0x{ nqp::unbox_i(self).base(16).lc }>" }
}

role TCC[Hash \api] {
    has TCCState $.state;

    method new(:$state = api<new>()) {
        self.bless(:$state);
    }

    method delete {
        api<delete>($!state);
    }

    method path($path) {
        api<set_lib_path>($!state, $path);
        self;
    }

    multi method to(Bool :$mem!) { api<set_output_type>($!state, 1); self }
    multi method to(Bool :$exe!) { api<set_output_type>($!state, 2); self }
    multi method to(Bool :$dll!) { api<set_output_type>($!state, 3); self }
    multi method to(Bool :$obj!) { api<set_output_type>($!state, 4); self }
    multi method to(Bool :$pp!)  { api<set_output_type>($!state, 5); self }

    method compile($code) {
        die 'Compilation failure'
            if api<compile_string>($!state, $code) < 0;

        self;
    }

    method run(*@args) {
        my $argc = +@args;
        my @argv := CArray[Str].new;
        @argv[$_] = @args[$_] for ^@args;

        api<run>($!state, $argc, @argv);
    }

    multi method set(:$I, :$isystem, :$L, :$l) {
        api<add_include_path>($!state, $_) for $I.list;
        api<add_sysinclude_path>($!state, $_) for $isystem.list;
        api<add_library_path>($!state, $_) for $L.list;
        api<add_library>($!state, $_) for $l.list;
        self;
    }

    multi method set($opts) {
        api<set_options>($!state, $opts);
        self;
    }

    multi method add(:$bin, :$c, :$asm, :$asmpp) {
        api<add_file>($!state, $_, 1) for $bin.list;
        api<add_file>($!state, $_, 2) for $c.list;
        api<add_file>($!state, $_, 3) for $asm.list;
        api<add_file>($!state, $_, 4) for $asmpp.list;
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

    method dump($file) {
        api<output_file>($!state, $file);
    }
}

sub tcc_new(--> TCCState) { * }
sub tcc_delete(TCCState) { * }
sub tcc_set_lib_path(TCCState, Str) { * }

# /* set error/warning display callback */
# LIBTCCAPI void tcc_set_error_func(TCCState *s, void *error_opaque,
#     void (*error_func)(void *opaque, const char *msg));

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

# /* add a symbol to the compiled program */
# LIBTCCAPI int tcc_add_symbol(TCCState *s, const char *name, const void *val);

sub tcc_output_file(TCCState, Str --> int32) { * }
sub tcc_run(TCCState, int32, CArray[Str] --> int32) { * }

# /* do all relocations (needed before using tcc_get_symbol()) */
# LIBTCCAPI int tcc_relocate(TCCState *s1, void *ptr);
# /* possible values for 'ptr':
#    - TCC_RELOCATE_AUTO : Allocate and manage memory internally
#    - NULL              : return required memory size for the step below
#    - memory address    : copy code to memory passed by the caller
#    returns -1 if error. */
# #define TCC_RELOCATE_AUTO (void*)1

# /* return symbol value or NULL if not found */
# LIBTCCAPI void *tcc_get_symbol(TCCState *s, const char *name);

sub EXPORT(*@args) {
    constant API = OUTER::.keys.grep(/^\&tcc_/);

    for @args ||= %*ENV<LIBTCC> // 'libtcc' -> $native {
        my $state = try trait_mod:<is>(&tcc_new.clone, :$native).();
        next unless defined $state;

        return EnumMap.new('tcc' => TCC[
            %(API.map({ .substr(5) => trait_mod:<is>(::($_).clone, :$native) }))
        ].new(:$state));
    }

    die 'Failed to load TinyCC from ' ~ @args.map("'" ~ * ~ "'").join(', ');
}
