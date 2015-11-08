PROVE = prove
PERL6 = perl6
CLANG = clang

BC = blib/TCC.pm6.moarvm \
     blib/TinyCC.pm6.moarvm \
     blib/TinyCC/Bootstrap.pm6.moarvm \
     blib/TinyCC/CCall.pm6.moarvm \
     blib/TinyCC/CFunc.pm6.moarvm \
     blib/TinyCC/CSignature.pm6.moarvm \
     blib/TinyCC/CTypes.pm6.moarvm \
     blib/TinyCC/Invoke.pm6.moarvm \
     blib/TinyCC/Eval.pm6.moarvm \
     blib/TinyCC/Lib/C.pm6.moarvm

export PERL6LIB = blib

tcc: blib/TCC.pm6.moarvm

bc: $(BC)

clean:
	rm -f $(BC)

$(BC): blib/%.pm6.moarvm: lib/%.pm6
	$(PERL6) --target=mbc --output=$@ $<

blib/TCC.pm6.moarvm: blib/TinyCC/Bootstrap.pm6.moarvm
blib/TinyCC/Bootstrap.pm6.moarvm: blib/TinyCC/CTypes.pm6.moarvm

bootcheck: blib/TinyCC/Bootstrap.pm6.moarvm
	$(PERL6) -Iblib -MTinyCC::Bootstrap -etcc-dump-bootcode | \
	  $(CLANG) -std=c99 -fsyntax-only -Werror -Weverything -xc -

test: $(BC)
	$(PROVE) -e '$(PERL6)' t

t-%: t/%-*.t $(BC)
	$<
