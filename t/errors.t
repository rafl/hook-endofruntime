#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Hook::EndOfRuntime;

{
    my $i = 0;
    eval {
        after_runtime 1000, sub { $i++ };
    };
    { local $TODO = "this should be an error";
    like($@, qr/Can't go up 1000 scopes/);
    }
    is($i, 0);
}

done_testing;
