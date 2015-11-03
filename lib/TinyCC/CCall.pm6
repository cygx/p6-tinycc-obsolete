# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use TinyCC;

multi trait_mod:<is>(Routine $r, :ccall([ TinyCC $tcc, Str :$name ])!) is export {
    ...
}
