use strict;
use warnings;

package Hook::EndOfRuntime;

use XSLoader;

XSLoader::load(__PACKAGE__);

use Sub::Exporter -setup => {
    exports => ['after_runtime'],
    groups  => { default => ['after_runtime'] },
};

use Scope::Guard;

sub _make_guard {
    return Scope::Guard->new($_[0]);
}

1;
