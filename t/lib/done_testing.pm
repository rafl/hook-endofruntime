package done_testing;

use Test::More 0.89 ();
use Hook::EndOfRuntime;
use Scope::Guard;

sub import {
    after_runtime 1, sub {
        Test::More::done_testing;
    };
}

1;
