PERL6 = perl6
PROVE = prove

PM := $(wildcard lib/*.pm lib/*/*.pm lib/*/*/*.pm)
BC := $(PM:lib/%=blib/%.moarvm)

export PERL6LIB = blib

bc: $(BC)

ctypes: blib/CTypes.pm.moarvm
api: blib/TinyCC/API.pm.moarvm
tinycc: blib/TinyCC.pm.moarvm
eval: blib/TinyCC/Eval.pm.moarvm
cinvoke: blib/TinyCC/CInvoke.pm.moarvm

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
blib/TinyCC/CInvoke.pm.moarvm: blib/TinyCC.pm.moarvm
blib/TinyCC/Eval.pm.moarvm: blib/TinyCC.pm.moarvm
