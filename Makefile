PERL6 = perl6
PROVE = prove

PM := $(wildcard lib/*.pm lib/*/*.pm lib/*/*/*.pm)
BC := $(PM:lib/%=blib/%.moarvm)

export PERL6LIB = blib

dummy: blib/TinyCC.pm.moarvm

bc: $(BC)

clean:
	rm -f $(BC)

$(BC): blib/%.pm.moarvm: lib/%.pm
	$(PERL6) --target=mbc --output=$@ $<

test: $(BC)
	$(PROVE) -e '$(PERL6)' t

t-%: t/%-*.t $(BC)
	$<

blib/TinyCC.pm.moarvm: blib/TinyCC/API.pm.moarvm
blib/TinyCC/API.pm.moarvm: blib/CTypes.pm.moarvm
