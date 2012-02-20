use strict;
use warnings;
use Test::More;

use Scope::Guard;
use Hook::EndOfRuntime;

{
    my $i = 0;

    is do {
        after_runtime 1, Scope::Guard->new(sub { $i++ });
        is $i, 0;
        23;
    }, 23;

    is $i, 1;

}

{
    my $i = 0;

    {
        my $e = \42;
        is do {
            eval {
                after_runtime 1, Scope::Guard->new(sub { $i++ });
                is $i, 0;
                die $e;
            };

            is $i, 1;

            $@;
        }, $e;
    }

    is $i, 1;
}

{
    my $i = 0;

    {
        my $e = \42;
        is do {
            eval {
                after_runtime 1, Scope::Guard->new(sub { $i++ });
                # with this, the test in the do starts passing. probably
                # appending to the wrong bit of the op tree
                # is $i, 0;
                die $e;
            };

            is $i, 1;

            $@;
        }, $e;
    }

    is $i, 1;
}

{
    my $i = 0;

    {
        {
            after_runtime 2, Scope::Guard->new(sub { $i++ });
            is $i, 0;
        }

        is $i, 0;
    }

    is $i, 1;
}

done_testing;
