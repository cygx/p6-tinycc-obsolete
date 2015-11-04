# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use TinyCC::NC;
use TinyCC::Types;

my class X::TinyCC is Exception {}

my class X::TinyCC::OutOfOrder is X::TinyCC {
    has $.action;
    has $.stage;
    method message { "Cannot perform '$!action' during stage $!stage" }
}

my enum  <LOAD SET DEF INC TARGET DECL COMP RELOC DONE>;

use MONKEY-TYPING;
augment class TCCState {
    use nqp;
    method new($value) { nqp::box_i(nqp::unbox_i($value), TCCState) }
    method Numeric { nqp::unbox_i(self) }
    method gist { "TCCState|{ self.Numeric.base(16) }" }
    method perl { "TCCState.new({ self.Numeric.base(16) })" }
}

class TinyCC {
    has $.state;
    has $.stage = LOAD;
    has $!api;
    has @!candidates;
    has $!root;
    has %!settings;
    has %!defs;
    has %!decls;
    has $!target = 1;
    has @!code;
    has $!errhandler;
    has $!errpayload;

    method gist { "TinyCC|$!stage" }

    method load(*@candidates) {
        X::TinyCC::OutOfOrder.new(:action<load>, :$!stage).fail
            if $!stage > LOAD;

        @!candidates = @candidates || %*ENV<LIBTCC> || 'libtcc';
        $!stage = SET;
        self;
    }

    method set($opts?,
        :$I, :$isystem, :$L, :$l,
        Bool :$nostdlib, Bool :$nostdinc, *% ()) {

        X::TinyCC::OutOfOrder.new(:action<set>, :$!stage).fail
            if $!stage > SET;

        %!settings<nostdlib> = True if $nostdlib;
        %!settings<nostdinc> = True if $nostdinc;
        %!settings.push:
            defined($opts) ?? :$opts !! Empty,
            defined($I) ?? :$I !! Empty,
            defined($isystem) ?? :$isystem !! Empty,
            defined($L) ?? :$L !! Empty,
            defined($l) ?? :$l !! Empty;

        self;
    }

    method setroot($root) {
        X::TinyCC::OutOfOrder.new(:action<setroot>, :$!stage).fail
            if $!stage > SET;

        $!root = $root;
        self;
    }

    method define(*%defs) {
        X::TinyCC::OutOfOrder.new(:action<define>, :$!stage).fail
            if $!stage > DEF;

        %!defs = %(%!defs, %defs);
        $!stage = DEF;
        self;
    }

    method include(*@headers) {
        X::TinyCC::OutOfOrder.new(:action<include>, :$!stage).fail
            if $!stage > INC;

        @!code.append: @headers.map({ "#include \"$_\"" });
        $!stage = INC;
        self;
    }

    method sysinclude(*@headers) {
        X::TinyCC::OutOfOrder.new(:action<sysinclude>, :$!stage).fail
            if $!stage > INC;

        @!code.append: @headers.map({ "#include <$_>" });
        $!stage = INC;
        self;
    }

    proto method target(*%) {
        X::TinyCC::OutOfOrder.new(:action<target>, :$!stage).fail
            if $!stage > TARGET;

        {*}
        $!stage = DECL;
        self;
    }

    multi method target(Bool :$MEM!, *% ()) { $!target = 1 }
    multi method target(Bool :$EXE!, *% ()) { $!target = 2 }
    multi method target(Bool :$DLL!, *% ()) { $!target = 3 }
    multi method target(Bool :$OBJ!, *% ()) { $!target = 4 }
    multi method target(Bool :$PRE!, *% ()) { $!target = 5 }

    method declare(*%decls) {
        X::TinyCC::OutOfOrder.new(:action<declare>, :$!stage).fail
            if $!stage > DECL;

        %!decls = %(%!decls, %decls);
        $!stage = DECL;
        self;
    }

    proto method compile(|) {
        X::TinyCC::OutOfOrder.new(:action<compile>, :$!stage).fail
            if $!stage > COMP;

        {*}
        $!stage = COMP;
        self;
    }

    multi method compile(Str $code) {
        @!code.push: $code;
    }

    multi method compile(Routine $r, Str $body) {
        my $name := $r.name;
        my $sig := cparams($r.signature.params).join(', ');
        my $type := ctype($r.signature.returns);
        @!code.push: qq:to/__END__/;
            $type $name\($sig) \{
            { $body.chomp.indent(4) }
            }
            __END__
    }

    method relocate {
        X::TinyCC::OutOfOrder.new(:action<relocate>, :$!stage).fail
            if $!stage != COMP;

        die if $!target != 1;
        self!COMPILE;
        die if $!api<relocate>($!state, api.RELOCATE_AUTO) < 0;
        $!stage = RELOC;
        self;
    }

    multi method lookup(Str $name) {
        self.relocate if $!stage < RELOC;
        X::TinyCC::OutOfOrder.new(:action<lookup>, :$!stage).fail
            if $!stage != RELOC;

        $!api<get_symbol>($!state, $name);
    }

    multi method lookup(Str $name, Mu:U $type) {
        nc.cast-to-ptr-of($type, self.lookup($name));
    }

    multi method lookup(Str $name, Mu:U :$var!) is rw {
        my $ptr := self.lookup($name);
        nc.cast-to-array($var, $ptr).AT-POS(0);
    }

    method run(*@args) {
        X::TinyCC::OutOfOrder.new(:action<run>, :$!stage).fail
            if $!stage != COMP;

        die if $!target != 1;
        self!COMPILE;
        my $rv = $!api<run>($!state, +@args, nc.array(Str, ~<<@args, Str));
        self.destroy;
        $rv;
    }

    method dump(Str() $path) {
        X::TinyCC::OutOfOrder.new(:action<dump>, :$!stage).fail
            if $!stage != COMP;

        die unless $!target == 2|3|4;
        self!COMPILE;
        die if $!api<output_file>($!state, $path) < 0;
        self.destroy;
    }

    method destroy {
        die unless $!state;
        $!api<delete>($!state);
        $!stage = DONE;
        self;
    }

    method reset {
        X::TinyCC::OutOfOrder.new(:action<reset>, :$!stage).fail
            if $!stage != DONE;

        $!state := Nil;
        $!stage = LOAD;
        $!api := Nil;
        @!candidates = ();
        $!root = Nil;
        %!settings = ();
        %!defs = ();
        %!decls = ();
        $!target = 1;
        @!code = ();
        $!errhandler = Nil;
        $!errpayload = Nil;
        self;
    }

    method catch(&cb, :$payload) {
        X::TinyCC::OutOfOrder.new(:action<catch>, :$!stage).fail
            if $!stage == DONE;

        $!errhandler = &cb;
        $!errpayload = $payload;
        self;
    }

    method !COMPILE {
        self!LOAD;

        $!api<set_lib_path>($!state, $_) with $!root || %*ENV<TCCROOT> || Nil;

        for %!settings<opts nostdinc I isystem nostdlib L l>:kv ->
                $opt, $values {

            for @$values -> $value {
                die if $_ < 0 given do given $opt {
                    when 'opts' { $!api<set_options>($!state, ~$value) }
                    when 'nostdinc' { $!api<set_options>($!state, '-nostdinc') }
                    when 'I' { $!api<add_include_path>($!state, ~$value) }
                    when 'isystem' {
                        $!api<add_sysinclude_path>($!state, ~$value);
                    }
                    when 'L' { $!api<add_library_path>($!state, ~$value) }
                    when 'l' { $!api<add_library>($!state, ~$value) }
                    when 'nostdlib' { $!api<set_options>($!state, '-nostdlib') }
                }
            }
        }

        $!api<set_error_func>($!state, $!errpayload, $!errhandler)
            if defined $!errhandler;

        $!api<define_symbol>($!state, .key, ~.value)
            for %!defs.pairs;

        die if $!api<set_output_type>($!state, $!target) < 0;

        for %!decls.pairs {
            die if $!api<add_symbol>($!state, .key, nc.cast-to-ptr(.value)) < 0;
        }

        die if $!api<compile_string>($!state, @!code.join("\n")) < 0;
    }

    method !LOAD {
        for @!candidates || %*ENV<LIBTCC> || 'libtcc' -> $lib {
            with try api.new-state($lib) -> $state {
                $!state := $state;
                $!api := api.load($lib);
                return;
            }
        }

        die;
    }
}

multi EXPORT { once Map.new  }
multi EXPORT(Whatever) { Map.new('tcc' => TinyCC.new) }
multi EXPORT(&cb) {
    cb my \tcc = TinyCC.new;
    Map.new('tcc' => tcc);
}
