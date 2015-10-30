PROVE = prove
PERL6 = perl6

BC = blib/TinyCC.pm6.moarvm blib/TinyCC/Eval.pm6.moarvm

export PERL6LIB = blib

all: README.md $(BC)

clean:
	rm -f $(BC)

README.md: build/README.md.in build/README.md.p6 lib/TinyCC.pm6
	$(PERL6) build/$@.p6 <build/$@.in >$@

$(BC): blib/%.pm6.moarvm: lib/%.pm6
	$(PERL6) --target=mbc --output=$@ $<

blib/TinyCC/Eval.pm6.moarvm: blib/TinyCC.pm6.moarvm

test: $(BC)
	$(PROVE) -e '$(PERL6)' t

t-%: t/%-*.t $(BC)
	$<
