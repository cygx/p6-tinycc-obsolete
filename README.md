# TinyCC [![Build Status](https://travis-ci.org/cygx/p6-tinycc.svg?branch=master)](https://travis-ci.org/cygx/p6-tinycc)

The Tiny C Compiler


# Synopsis

```
    use TinyCC *;

    tcc.define(NAME => '"cygx"');
    tcc.compile(q:to/__END__/).run;
        int puts(const char *);
        int main(void) {
            puts("Hello, " NAME "!");
            return 0;
        }
        __END__
```

```
    use TinyCC *;

    tcc.target(:EXE).compile(q:to/__END__/).dump('42.exe');
        int main(void) { return 42; }
        __END__

    run("./42.exe");
```

```
    use TinyCC::Eval;
    use TinyCC::Types;

    my $out = cval(uint64);

    EVAL q:to/__END__/, :lang<C>, init => { .define: N => 100; .declare: :$out };
        extern unsigned long long out;

        static unsigned long long fib(unsigned n) {
            return n < 2 ? n : fib(n - 1) + fib(n - 2);
        }

        int main(void) {
            out = fib(N);
            return 0;
        }
        __END__

    say $out.deref;
```

```
    use TinyCC *;
    use TinyCC::CFunc;

    sub plus(int \a, int \b --> int) is cfunc(tcc, { q:to/__END__/ }) {*}
        return a + b;
        __END__

    say plus(3, 4);
```

```
    use TinyCC *;
    use TinyCC::CCall;

    sub abort is ccall(tcc) {*}
    abort;
```


# Description

Too lazy to write anything up right now...


# Bugs and Development

Development happens at [GitHub](https://github.com/cygx/p6-tinycc). If you
found a bug or have a feature request, use the
[issue tracker](https://github.com/cygx/p6-tinycc/issues) over there.


# Copyright and License

Copyright (C) 2015 by <cygx@cpan.org>

Distributed under the
[Boost Software License, Version 1.0](http://www.boost.org/LICENSE_1_0.txt)
