use nqp;

my class Callsite is repr<NativeCall> {}
my class CPtr is repr<CPointer> {}

my $cs := nqp::create(Callsite);
nqp::buildnativecall(
    $cs,
    'p6tccboot.dll',
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

say nqp::nativecall(Int, $cs, nqp::list(CPtr, -42, 0, CPtr));
