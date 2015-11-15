PERL6  = perl6
PROVE  = prove
MKDEPS = 6make deps

PM := $(wildcard lib/*.pm lib/*/*.pm lib/*/*/*.pm)
BC := $(PM:lib/%=blib/%.moarvm)

export PERL6LIB = blib

bc: $(BC)

clean:
	rm -f $(BC)

rescan:
	cat Makefile.in > Makefile
	$(MKDEPS) >> Makefile

$(BC): blib/%.pm.moarvm: lib/%.pm
	$(PERL6) --target=mbc --output=$@ $<

test: $(BC)
	$(PROVE) -e '$(PERL6)' t

t-%: t/%-*.t $(BC)
	$<

# auto-generated module dependencies
blib/CTypes.pm.moarvm: blib/%.moarvm: ./lib/% 
blib/TinyCC/Lib/C.pm.moarvm: blib/%.moarvm: ./lib/%  blib/TinyCC/CCall.pm.moarvm blib/TinyCC.pm.moarvm
blib/TinyCC/CInvoke.pm.moarvm: blib/%.moarvm: ./lib/% blib/CTypes.pm.moarvm blib/TinyCC.pm.moarvm
blib/TinyCC.pm.moarvm: blib/%.moarvm: ./lib/% blib/CTypes.pm.moarvm blib/TinyCC/API.pm.moarvm
blib/TinyCC/Eval.pm.moarvm: blib/%.moarvm: ./lib/% blib/TinyCC.pm.moarvm
blib/TinyCC/CFunc.pm.moarvm: blib/%.moarvm: ./lib/% blib/TinyCC.pm.moarvm blib/TinyCC/CInvoke.pm.moarvm
blib/TinyCC/CCall.pm.moarvm: blib/%.moarvm: ./lib/% blib/TinyCC.pm.moarvm blib/CTypes.pm.moarvm
blib/TinyCC/API.pm.moarvm: blib/%.moarvm: ./lib/% blib/CTypes.pm.moarvm
