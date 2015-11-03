# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use TinyCC::Types;
use NativeCall;

multi EXPORT { once Map.new  }
multi EXPORT(Whatever) { Map.new('tcc' => ::<TinyCC>.new) }
multi EXPORT(&cb) {
    cb my \tcc = ::<TinyCC>.new;
    Map.new('tcc' => tcc);
}

unit class TinyCC;

my enum  <LOAD SET DEF INC TARGET DECL COMP RELOC DONE>;
my &RELOCATE_AUTO = {
    use nqp;
    once nqp::box_i(1, Pointer);
}

my class TCCState is repr<CPointer> {
    method new($value) {
        use nqp;
        nqp::box_i(nqp::unbox_i($value), TCCState);
    }

    method Numeric {
        use nqp;
        nqp::unbox_i(self);
    }

    method gist { "TCCState|{ self.Numeric.base(16) }" }
    method perl { "TCCState.new({ self.Numeric.base(16) })" }
}

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

my constant API = [ OUTER::.keys.grep(/^\&tcc_/) ];

has $!state;
has $!api;
has $!stage = LOAD;
has @!candidates;
has %!settings;
has %!defs;
has %!decls;
has $!target = 1;
has @!code;
has $!errhandler;
has $!errpayload;

method gist { "TinyCC|$!stage" }

method load(*@candidates, *%_ ()) {
    die if $!stage > LOAD;
    @!candidates = @candidates || %*ENV<LIBTCC> || 'libtcc';
    $!stage = SET;
    self;
}

method set($opts?, *%_ (:$I, :$isystem, :$L, :$l, Bool :$nostdlib)) {
    die if $!stage > SET;
    %!settings<nostdlib> = True if $nostdlib;
    %!settings.push:
        defined($opts) ?? :$opts !! Empty,
        defined($I) ?? :$I !! Empty,
        defined($isystem) ?? :$isystem !! Empty,
        defined($L) ?? :$L !! Empty,
        defined($l) ?? :$l !! Empty;
    self;
}

method define(*%defs) {
    die if $!stage > DEF;
    %!defs = %(%!defs, %defs);
    $!stage = DEF;
    self;
}

method include(*@headers, *%_ ()) {
    die if $!stage > INC;
    @!code.append: @headers.map({ "#include \"$_\"" });
    $!stage = INC;
    self;
}

method sysinclude(*@headers, *%_ ()) {
    die if $!stage > INC;
    @!code.append: @headers.map({ "#include <$_>" });
    $!stage = INC;
    self;
}

proto method target(*%_) {
    die if $!stage > TARGET;
    die if defined $!target;
    {*}
    $!stage = DECL;
    self;
}
multi method target(*%_ (Bool :$MEM!)) { $!target = 1 }
multi method target(*%_ (Bool :$EXE!)) { $!target = 2 }
multi method target(*%_ (Bool :$DLL!)) { $!target = 3 }
multi method target(*%_ (Bool :$OBJ!)) { $!target = 4 }
multi method target(*%_ (Bool :$PRE!)) { $!target = 5 }

method declare(*%decls) {
    die if $!stage > DECL;
    %!decls = %(%!decls, %decls);
    $!stage = DECL;
    self;
}

multi method compile(Str $code) {
    die if $!stage > COMP;
    @!code.push: $code;
    $!stage = COMP;
    self;
}

multi method compile(Routine $r, Str $body) {
    die if $!stage > COMP;
    my $name := $r.name;
    my $sig := cparams($r.signature.params).join(', ');
    my $type := ctype($r.signature.returns);
    @!code.push: qq:to/__END__/;
        $type $name\($sig) \{
        { $body.chomp.indent(4) }
        }
        __END__
    $!stage = COMP;
    self;
}

method relocate {
    die if $!stage != COMP;
    die if $!target != 1;
    self!COMPILE;
    die if $!api<relocate>($!state, RELOCATE_AUTO) < 0;
    $!stage = RELOC;
    self;
}

method lookup(Str $name) {
    self.relocate if $!stage < RELOC;
    die if $!stage != RELOC;
    $!api<get_symbol>($!state, $name);
}

method run(*@args) {
    die if $!stage != COMP;
    die if $!target != 1;
    self!COMPILE;
    my $rv = $!api<run>($!state, +@args, CArray[Str].new(~<<@args, Str));
    self.destroy;
    $rv;
}

method dump {
    die if $!stage != COMP;
    die unless $!target == 2|3|4;
    self!COMPILE;
    ...;
    self.destroy;
}

method destroy {
    $!api<delete>($!state);
    $!stage = DONE;
    self;
}

method reset {
    die if $!stage != DONE;
    $!state := Nil;
    $!api := Nil;
    $!stage = LOAD;
    @!candidates = ();
    %!settings = ();
    %!defs = ();
    $!target = 1;
    @!code = ();
    $!errhandler = Nil;
    $!errpayload = Nil;
    self;
}

method catch(&cb:(Pointer, Str), Pointer :$payload) {
    die if $!stage == DONE;
    $!errhandler = &cb;
    $!errpayload = $payload;
    self;
}

method !COMPILE {
    self!LOAD;

    # TODO: settings

    $!api<set_error_func>($!state, $!errpayload, $!errhandler)
        if defined $!errhandler;

    $!api<define_symbol>($!state, .key, ~.value)
        for %!defs.pairs;

    die if $!api<set_output_type>($!state, $!target) < 0;

    for %!decls.pairs {
        die if $!api<add_symbol>(
            $!state, .key, nativecast(Pointer, .value)) < 0;
    }

    die if $!api<compile_string>($!state, @!code.join("\n")) < 0;
}

method !LOAD {
    for @!candidates || %*ENV<LIBTCC> || 'libtcc' -> $native {
        with try trait_mod:<is>(&tcc_new.clone, :$native).() -> $state {
            $!state := $state;
            $!api := Map.new(API.map: {
                .substr(5) => trait_mod:<is>(::($_).clone, :$native);
            });

            return;
        }
    }

    die;
}
