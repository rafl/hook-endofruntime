#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Hook::EndOfRuntime;

{
    my $i = 0;
    eval {
        BEGIN { after_runtime 1, sub { $i++ } }
        is($i, 0);
    };
    ok(!$@);
    is($i, 1);
}

{
    my $i = 0;
    eval {
        BEGIN { after_runtime 1, sub { $i++ } }
        is($i, 0);
        die "foo\n";
    };
    is($@, "foo\n");
    is($i, 1);
}

{
    my $i = 0;
    {
        eval {
            BEGIN { after_runtime 2, sub { $i++ } }
            is($i, 0);
        };
        ok(!$@);
        is($i, 0);
    }
    is($i, 1);
}

{
    my $i = 0;
    {
        eval {
            BEGIN { after_runtime 2, sub { $i++ } }
            is($i, 0);
            die "foo\n";
        };
        is($@, "foo\n");
        is($i, 0);
    }
    is($i, 1);
}

{
    my $i = 0;
    eval <<'EVAL';
    BEGIN { after_runtime 1, sub { $i++ } }
    is($i, 0);
EVAL
    ok(!$@);
    is($i, 1);
}

{
    my $i = 0;
    eval <<'EVAL';
    BEGIN { after_runtime 1, sub { $i++ } }
    is($i, 0);
    die "foo\n";
EVAL
    is($@, "foo\n");
    is($i, 1);
}

{
    my $i = 0;
    {
        eval <<'EVAL';
        BEGIN { after_runtime 2, sub { $i++ } }
        is($i, 0);
EVAL
        ok(!$@);
        is($i, 0);
    }
    local $TODO = "doesn't cross string eval boundaries properly?";
    is($i, 1);
}

{
    my $i = 0;
    {
        eval <<'EVAL';
        BEGIN { after_runtime 2, sub { $i++ } }
        is($i, 0);
        die "foo\n";
EVAL
        is($@, "foo\n");
        is($i, 0);
    }
    local $TODO = "doesn't cross string eval boundaries properly?";
    is($i, 1);
}

done_testing;
