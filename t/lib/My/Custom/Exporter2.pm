package My::Custom::Exporter2;
use strict;
use warnings;

sub import {
    eval "use done_testing into_level => 2";
}

1;
