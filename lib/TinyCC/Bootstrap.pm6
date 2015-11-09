# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use nqp;
use TinyCC::CTypes;

unit class TinyCC::Bootstrap;

class Call is repr<NativeCall> is Callable {
    multi nctype(cptr) { 'cpointer' }
    multi nctype(Blob) { 'vmarray' }
    multi nctype(Int $ where cint) { 'int' }

    method build(Str $name, Signature $sig, Str :$lib) {
        my $argtypes := nqp::list();
        nqp::push($argtypes, nqp::hash('type', nqp::decont(nctype($_))))
            for $sig.params.grep(*.positional)>>.type;

        my $cs := nqp::create(self);
        nqp::buildnativecall(
            $cs,
            $lib,
            $name,
            '', # calling convention
            $argtypes,
            nqp::hash('type', nqp::decont(nctype($sig.returns))),
        );

        $cs;
    }

    method CALL-ME(Mu:U $rtype is raw, *@args) {
        nqp::nativecall($rtype, self, nqp::list(|@args))
    }
}

method eval(Str:D $code, %symbols?, Str:D :$lib = %*ENV<LIBTCC> || 'libtcc') {
    my &tcc_new := Call.build('tcc_new', :(), :$lib);
    my &tcc_delete := Call.build('tcc_delete', :(), :$lib);
    my &tcc_set_output_type := Call.build('tcc_set_output_type, :(), :$lib');

}

## TCCState *tcc_new(void)
#sub tcc_new(--> cptr) {
#    nqp::nativecall(cptr, nqp::decont($_), nqp::list())
#        given once Callsite.build(&?ROUTINE, 'libtcc');
#}
#
## void tcc_delete(TCCState *s)
#sub tcc_delete(cptr \tcc) {
#    nqp::nativecall(Mu, nqp::decont($_), nqp::list(tcc))
#        given once Callsite.build(&?ROUTINE, 'libtcc');
#}
#
## int tcc_compile_string(TCCState *s, const char *buf)
#sub tcc_compile_string(cptr \tcc, Blob \blob --> cint) {
#    nqp::nativecall(Int, nqp::decont($_), nqp::list(tcc, blob))
#        given once Callsite.build(&?ROUTINE, 'libtcc');
#}
#
## int tcc_set_output_type(TCCState *s, int output_type)
#sub tcc_set_output_type(cptr \tcc, cint \type --> cint) {
#    nqp::nativecall(Int, nqp::decont($_), nqp::list(tcc, type))
#        given once Callsite.build(&?ROUTINE, 'libtcc');
#}
#
## int tcc_run(TCCState *s, int argc, char **argv)
#sub tcc_run(cptr \tcc --> cint) {
#    nqp::nativecall(Int, nqp::decont($_), nqp::list(tcc, 0, cptr))
#        given once Callsite.build(&?ROUTINE, 'libtcc');
#}
