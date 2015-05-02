use nqp;
use NativeCall;

sub tcc_new(--> Pointer) { * }
sub tcc_delete(Pointer) { * }
sub tcc_set_lib_path(Pointer, Str) { * }

# /* set error/warning display callback */
# LIBTCCAPI void tcc_set_error_func(TCCState *s, void *error_opaque,
#     void (*error_func)(void *opaque, const char *msg));

sub tcc_set_options(Pointer, Str --> int32) { * }
sub tcc_add_include_path(Pointer, Str --> int32) { * }
sub tcc_add_sysinclude_path(Pointer, Str --> int32) { * }
sub tcc_define_symbol(Pointer, Str, Str) { * }
sub tcc_undefine_symbol(Pointer, Str) { * }
sub tcc_add_file(Pointer, Str, int32 --> int32) { * }
sub tcc_compile_string(Pointer, Str --> int32) { * }
sub tcc_set_output_type(Pointer, int32 --> int32) { * }
sub tcc_add_library_path(Pointer, Str --> int32) { * }
sub tcc_add_library(Pointer, Str --> int32) { * }

# /* add a symbol to the compiled program */
# LIBTCCAPI int tcc_add_symbol(TCCState *s, const char *name, const void *val);

sub tcc_output_file(Pointer, Str --> int32) { * }
sub tcc_run(Pointer, int32, CArray[Str] --> int32) { * }

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
    my $lib;
    my $native = { $lib };

    my &new = trait_mod:<is>(&tcc_new, :$native);
    my &delete = trait_mod:<is>(&tcc_delete, :$native);
    my &to = trait_mod:<is>(&tcc_set_output_type, :$native);
    my &compile = trait_mod:<is>(&tcc_compile_string, :$native);
    my &run = trait_mod:<is>(&tcc_run, :$native);
    my &path = trait_mod:<is>(&tcc_set_lib_path, :$native);
    my &set-I = trait_mod:<is>(&tcc_add_include_path, :$native);
    my &set-isystem = trait_mod:<is>(&tcc_add_sysinclude_path, :$native);
    my &set-L = trait_mod:<is>(&tcc_add_library_path, :$native);
    my &set-l = trait_mod:<is>(&tcc_add_library, :$native);
    my &dump = trait_mod:<is>(&tcc_output_file, :$native);
    my &options = trait_mod:<is>(&tcc_set_options, :$native);
    my &add = trait_mod:<is>(&tcc_add_file, :$native);
    my &define = trait_mod:<is>(&tcc_define_symbol, :$native);
    my &undef = trait_mod:<is>(&tcc_undefine_symbol, :$native);

    class TCCState is repr('CPointer') {
        method new { nativecast(TCCState, new) }
        method delete { delete(self) }

        method path($path) { path(self, $path); self }

        multi method to(Bool :$mem!) { to(self, 1); self }
        multi method to(Bool :$exe!) { to(self, 2); self }
        multi method to(Bool :$dll!) { to(self, 3); self }
        multi method to(Bool :$obj!) { to(self, 4); self }
        multi method to(Bool :$pp!)  { to(self, 5); self }

        method compile($code) {
            die 'Compilation failure'
                if compile(self, $code) < 0;

            self;
        }

        method run(*@args) {
            my $argc = +@args;
            my @argv := CArray[Str].new;
            @argv[$_] = @args[$_] for ^@args;
            run(self, $argc, @argv);
        }

        multi method set(:$I, :$isystem, :$L, :$l) {
            set-I(self, $_) for $I.list;
            set-isystem(self, $_) for $isystem.list;
            set-L(self, $_) for $L.list;
            set-l(self, $_) for $l.list;
            self;
        }

        multi method set($opts) { options(self, $opts); self }

        multi method add(:$bin, :$c, :$asm, :$asmpp) {
            add(self, $_, 1) for $bin.list;
            add(self, $_, 2) for $c.list;
            add(self, $_, 3) for $asm.list;
            add(self, $_, 4) for $asmpp.list;
            self;
        }

        multi method add(*@cfiles) {
            add(self, $_, 2) for @cfiles;
            self;
        }

        method define(*%defs) {
            define(self, .key, .value) for %defs;
            self;
        }

        method undef(*@defs) {
            undef(self, $_) for @defs;
            self;
        }

        method dump($file) { dump(self, $file) }

        method gist { "TCCState<0x{ nqp::unbox_i(self).base(16).lc }>" }
    }

    for @args ||= 'libtcc' {
        $lib = $_;
        return EnumMap.new('tcc' => try { TCCState.new } // next);
    }

    die 'Failed to load TinyCC from ' ~ @args.map("'" ~ * ~ "'").join(', ');
}
