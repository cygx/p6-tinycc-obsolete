my $method;
my %funcs;
my %methods;

sub dump(:$last) {
    take "    $method\n";

    take "  * wraps { %funcs.keys.sort.map({ "`tcc_$_`" }).join(', ') }"
        if %funcs;

    take "  * calls { %methods.keys.sort.map({ "`TCC.$_`" }).join(', ') }"
        if %methods;

    take "\n---\n" unless $last;

    %funcs = ();
    %methods = ();
}

my $api = join "\n", gather for 'TinyCC.pm6'.IO.lines {
    next unless /^ 'role TCC[' / ff False;

    if /^ '}' / {
        dump :last;
        last;
    }

    if /^ \s* (.* method .* '{') / {
        dump if $method;
        $method = "$0 ... }";
    }

    for .match(:g, / 'api<' (\w+) '>' /) -> $/ {
        %funcs{~$0} = True;
    }

    for .match(:g, / 'self.' (\w+) /) -> $/ {
        %methods{~$0} = True;
    }
}

for 'README.md.in'.IO.lines {
    say / __API__ / ?? $api !! $_;
}
