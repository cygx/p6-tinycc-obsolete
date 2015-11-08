# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use nqp;
use TinyCC::CTypes;

unit module TinyCC::Bootstrap;

my constant @API = <
    new
    delete
    set_lib_path
    set_error_func
    set_options
    add_include_path
    add_sysinclude_path
    define_symbol
    undefine_symbol
    add_file
    compile_string
    set_output_type
    add_library_path
    add_library
    add_symbol
    output_file
    run
    relocate
    get_symbol
>;

my constant %IDS = %(@API.pairs.invert);

my $CODE;
my constant BOOTLIB = $*DISTRO.is-win
    ?? 'p6tccboot.dll'
    !! 'libp6tccboot.so';

my class Callsite is repr<NativeCall> {}

my class TCCBootAPI is export {
    method new(|c) { self.FALLBACK('new', |c) }

    method FALLBACK(TCCBootAPI:U:
        Str:D $call where %IDS, cptr $vt, *@args --> cintptr) {

        nqp::nativecall(Int, nqp::decont($_), nqp::list(cptr, -42, +@args, cptr))
            given once {
                my $cs := nqp::create(Callsite);
                nqp::buildnativecall(
                    $cs,
                    BOOTLIB,
                    'P6TinyCC_dispatch',
                    '', # calling convention
                    nqp::list(
                        nqp::hash('type', 'cpointer'),  # struct vtable *vt
                        nqp::hash('type', 'int'),       # int id
                        nqp::hash('type', 'uint'),      # unsigned arity
                        nqp::hash('type', 'cpointer'),  # uintptr_t *args
                    ),
                    nqp::hash('type', 'longlong'),      # intptr_t -- FIXME
                );
                $cs;
            }
    }
}

sub tcc-dump-bootcode($file = '-', Bool :$w) is export {
    open($file, |($w ?? :w !! :x)).print($CODE);
}

sub tcc-make-bootlib($file = BOOTLIB) is export {
    my @err;
    my $proc = Proc::Async.new: |<tcc -shared -o p6tccboot.dll ->, :w;

    $proc.stderr.tap: -> $err { @err.push($err) }

    my $promise = $proc.start;
    $proc.print($CODE);
    $proc.close-stdin;

    if (await $promise).exitcode {
        die @err.join("\n");
    }
}

$CODE := q:to/__END__/;
/*  Copyright 2015 cygx <cygx@cpan.org>
    Distributed under the Boost Software License, Version 1.0

    cf http://repo.or.cz/w/tinycc.git/blob/HEAD:/libtcc.h
*/

#include <stdint.h>
#include <stdlib.h>

#ifdef _WIN32
#include <windows.h>
#define loadlib(PATH) (void *)(PATH ? LoadLibraryA : GetModuleHandleA)(PATH)
#define freelib(LIB) !FreeLibrary((HMODULE)(LIB))
#define findsym(LIB, SYM) (void *)GetProcAddress((HMODULE)(LIB), SYM)
#define EXPORT __declspec(dllexport)
#else
#include <dlfcn.h>
#define loadlib(PATH) dlopen(PATH, RTLD_LAZY)
#define freelib(LIB) dlclose(LIB)
#define findsym(LIB, SYM) dlsym(LIB, SYM)
#define EXPORT
#endif

#define PANIC 0
#include <assert.h>

enum {
    LOAD = -1,
    UNLOAD = -2,
    FORTY_TWO = -42,
    TCC_NEW = 0,
    TCC_DELETE,
    TCC_SET_LIB_PATH,
    TCC_SET_ERROR_FUNC,
    TCC_SET_OPTIONS,
    TCC_ADD_INCLUDE_PATH,
    TCC_ADD_SYSINCLUDE_PATH,
    TCC_DEFINE_SYMBOL,
    TCC_UNDEFINED_SYMBOL,
    TCC_ADD_FILE,
    TCC_COMPILE_STRING,
    TCC_SET_OUTPUT_TYPE,
    TCC_ADD_LIBRARY_PATH,
    TCC_ADD_LIBRARY,
    TCC_ADD_SYMBOL,
    TCC_OUTPUT_FILE,
    TCC_RUN,
    TCC_RELOCATE,
    TCC_GET_SYMBOL,
    SYMCOUNT_
};

typedef struct TCCState TCCState;

struct vtable {
    void *lib;
    void *symbols[SYMCOUNT_];
};

static const char *NAMES[] = {
    "tcc_new",
    "tcc_delete",
    "tcc_set_lib_path",
    "tcc_set_error_func",
    "tcc_set_options",
    "tcc_add_include_path",
    "tcc_add_sysinclude_path",
    "tcc_define_symbol",
    "tcc_undefine_symbol",
    "tcc_add_file",
    "tcc_compile_string",
    "tcc_set_output_type",
    "tcc_add_library_path",
    "tcc_add_library",
    "tcc_add_symbol",
    "tcc_output_file",
    "tcc_run",
    "tcc_relocate",
    "tcc_get_symbol",
};

EXPORT intptr_t P6TinyCC_dispatch(struct vtable *, int, unsigned, uintptr_t *);
intptr_t P6TinyCC_dispatch(
    struct vtable *vt, int id, unsigned arity, uintptr_t *args)
{
#   define call(RV, ...) ((RV (*)(__VA_ARGS__))vt->symbols[id])
#   define voidcall(...) call(void, __VA_ARGS__)
#   define intcall(...) call(int, __VA_ARGS__)
#   define apicall(...) intcall(TCCState *, __VA_ARGS__)
#   define p(I) (void *)args[I]
#   define i(I) (int)args[I]
    typedef void errfn(void *, const char *);

    switch(id) {
    case LOAD: { // fail NULL
        if(arity != 1) return 0;

        void *lib = loadlib((void *)args[0]);
        if(!lib) return 0;

        vt = malloc(sizeof *vt);
        if(!vt) goto FAIL;

        for(int i = 0; i < SYMCOUNT_; ++i) {
            if((vt->symbols[i] = findsym(lib, NAMES[i])) == NULL)
                goto FAIL;
        }

        return (intptr_t)vt;

    FAIL:
        freelib(lib);
        return 0;
    }

    case UNLOAD: { // fail nonzero
        if(arity != 0) return 1;
        int rv = freelib(vt->lib);
        free(vt);
        return rv;
    }

    case FORTY_TWO:
        return 42;

    case TCC_NEW: // fail NULL
        if(arity != 0) return 0;
        return (intptr_t)(call(TCCState *, void)());

    case TCC_DELETE: // fail nonzero
        if(arity != 1) return 1;
        voidcall(TCCState *)(p(0));
        return 0;

    case TCC_SET_LIB_PATH: // fail nonzero
        if(arity != 2) return 1;
        voidcall(TCCState *, const char *)(p(0), p(1));
        return 0;

    case TCC_SET_ERROR_FUNC: // fail nonzero
        if(arity != 3) return 1;
        voidcall(TCCState *, void *, errfn)(p(0), p(1), (errfn *)args[2]);
        return 0;

    case TCC_SET_OPTIONS: // fail nonzero
        if(arity != 2) return 1;
        return apicall(const char *)(p(0), p(1));

    case TCC_ADD_INCLUDE_PATH: // fail nonzero
        if(arity != 2) return 1;
        return apicall(const char *)(p(0), p(1));

    case TCC_ADD_SYSINCLUDE_PATH: // fail nonzero
        if(arity != 2) return 1;
        return apicall(const char *)(p(0), p(1));

    case TCC_DEFINE_SYMBOL: // fail nonzero
        if(arity != 3) return 1;
        voidcall(TCCState *, const char *, const char *)(p(0), p(1), p(2));
        return 0;

    case TCC_UNDEFINED_SYMBOL: // fail nonzero
        if(arity != 2) return 1;
        voidcall(TCCState *, const char *)(p(0), p(1));
        return 0;

    case TCC_ADD_FILE: // fail nonzero
        if(arity != 3) return 1;
        return apicall(const char *, int)(p(0), p(1), i(2));

    case TCC_COMPILE_STRING: // fail nonzero
        if(arity != 2) return 1;
        return apicall(const char *)(p(0), p(1));

    case TCC_SET_OUTPUT_TYPE: // fail nonzero
        if(arity != 2) return 1;
        return apicall(int)(p(0), i(1));

    case TCC_ADD_LIBRARY_PATH: // fail nonzero
        if(arity != 2) return 1;
        return apicall(const char *)(p(0), p(1));

    case TCC_ADD_LIBRARY: // fail nonzero
        if(arity != 2) return 1;
        return apicall(const char *)(p(0), p(1));

    case TCC_ADD_SYMBOL: // fail nonzero
        if(arity != 3) return 1;
        return apicall(const char *, const void *)(p(0), p(1), p(2));

    case TCC_OUTPUT_FILE: // fail nonzero
        if(arity != 2) return 1;
        return apicall(const char *)(p(0), p(1));

    case TCC_RUN: // fail nonzero
        if(arity != 3) return -1;
        return apicall(int, char **)(p(0), i(1), p(2));

    case TCC_RELOCATE: // fail nonzero
        if(arity != 2) return 1;
        return apicall(void *)(p(0), p(1));

    case TCC_GET_SYMBOL: // fail NULL
        if(arity != 2) return 0;
        return (intptr_t)(call(void *, TCCState *, const char *)(p(0), p(1)));
    }

    assert(PANIC);
    return 0;
}
__END__
