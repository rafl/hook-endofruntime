#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $i = 0;

BEGIN {
    package My::Hook;
    use Hook::EndOfRuntime;
    sub import {
        after_runtime 1, sub { $i++ };
    }
    $INC{'My/Hook.pm'} = __FILE__;
}

{
    is($i, 0);
    use My::Hook;
    is($i, 0);
}
is($i, 1);

done_testing;
