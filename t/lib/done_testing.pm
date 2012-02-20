package done_testing;

use Test::More 0.89 ();
use Hook::EndOfRuntime;

sub import {
    my $package = shift;
    my (%opts) = @_;
    $opts{into_level} //= 1;
    after_runtime $opts{into_level}, sub {
        Test::More::done_testing;
    };
}

1;
