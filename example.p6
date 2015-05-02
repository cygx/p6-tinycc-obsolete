use lib '.';
use TinyCC;

tcc.set(:L<.>).to(:mem);
tcc.define(NAME => '"cygx"');

tcc.compile(q:to/__END__/);
    int puts(const char *);
    int main(void) {
        puts("Hello, " NAME "!");
        return 0;
    }
    __END__

tcc.run;
tcc.delete;
