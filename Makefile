PERL6 = perl6

blib/TinyCC.pm6.moarvm: TinyCC.pm6
	$(PERL6) --target=mbc --output=$@ TinyCC.pm6
