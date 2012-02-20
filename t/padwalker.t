#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::Requires 'PadWalker';

use Hook::EndOfRuntime;

{
    my $i = 0;
    {
        BEGIN { after_runtime 1, sub { $i++ } }
        my $lexicals = PadWalker::peek_my(0);
        is_deeply($lexicals, { '$i' => \0 });
    }
    my $lexicals = PadWalker::peek_my(0);
    local $TODO = "hook visible in lexical pad - do we care?";
    is_deeply($lexicals, { '$i' => \1 });
}

done_testing;
