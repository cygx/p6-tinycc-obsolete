require TinyCC::Bootstrap <&tcc-dump-bootcode &tcc-make-bootlib>;

sub bootcode is export { tcc-dump-bootcode }
sub bootstrap is export { tcc-make-bootlib }

# perl6 -MTCC -eeval EOF -istdio
sub eval is export { !!! }

CATCH {
    note $_;
    exit 1;
}
