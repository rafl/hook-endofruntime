package My::Custom::Exporter;
use strict;
use warnings;

use done_testing ();

sub import {
    done_testing->import(into_level => 1);
}

1;
