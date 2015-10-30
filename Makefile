PROVE = prove
PERL6 = perl6

PM = lib/TinyCC.pm6
BC = blib/TinyCC.pm6.moarvm

export PERL6LIB = blib

all: README.md $(BC)

clean:
	rm -f $(BC)

README.md: build/README.md.in build/README.md.p6 $(PM)
	$(PERL6) build/$@.p6 <build/$@.in >$@

$(BC): $(PM)
	$(PERL6) --target=mbc --output=$@ $(PM)

test: $(BC)
	$(PROVE) -e '$(PERL6)' t

t-%: t/%-*.t $(BC)
	$<
