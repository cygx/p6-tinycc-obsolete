PERL6 = perl6

blib/TinyCC.moarvm: TinyCC.pm6
	$(PERL6) --target=mbc --output=$@ TinyCC.pm6
