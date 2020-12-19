package Hook;

use warnings;
use strict;

use Exporter qw(import);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(out err);

sub out {
    my ($str) = @_;
    $str = "default" if ! defined $str;
    print "$str\n";
}
sub err {
    my ($str) = @_;
    $str = "default" if ! defined $str;

    warn $str;
}
1;