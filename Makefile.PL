use strict;
use warnings;
use Devel::CallChecker;
use IO::File;

use ExtUtils::MakeMaker;

IO::File->new('callchecker0.h', 'w')->print(
    Devel::CallChecker::callchecker0_h
);

WriteMakefile(
    NAME => 'Hook::EndOfRuntime',
);
