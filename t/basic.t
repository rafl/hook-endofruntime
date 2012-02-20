use strict;
use warnings;
use Test::More;

use Hook::EndOfRuntime;

{
    my $i = 0;

    is do {
        BEGIN { after_runtime 1, sub { $i++ } };
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
                BEGIN { after_runtime 1, sub { $i++ } };
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
                BEGIN { after_runtime 1, sub { $i++ } };
                # with this, the test in the do starts passing. probably
                # appending to the wrong bit of the op tree
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
        {
            BEGIN { after_runtime 2, sub { $i++ } };
            BEGIN { after_runtime 1, sub { $i++ } };
            BEGIN { after_runtime 2, sub { $i++ } };
            is $i, 0;
        }

        is $i, 1;
    }

    is $i, 3;
}

for my $n (1, 0) {
    my $i = 0;

    is do {
        BEGIN { after_runtime 1, sub { $i++ } };
        is $i, 0;
        23;
    }, 23;

    is $i, $n;
}

done_testing;
