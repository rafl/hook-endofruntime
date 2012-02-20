use strict;
use warnings;

package Hook::EndOfRuntime;

use XSLoader;

XSLoader::load(__PACKAGE__);

use Sub::Exporter -setup => {
    exports => ['after_runtime'],
    groups  => { default => ['after_runtime'] },
};

1;
