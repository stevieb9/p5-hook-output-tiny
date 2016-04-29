package Hook::Output::Tiny;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    return bless {
        stdout => {
            state => 0,
            handle => *fh,
            data => '',
        },
        stderr => {
            state => 0,
            handle => *fh,
            data => '',
        },
    }, shift;
}

sub hook {
    my ($self, @handles) = @_;

    for (@handles){
        if ($_ eq 'stdout'){
            $self->_stdout;
            select $self->{stdout}{handle};
        }
        if ($_ eq 'stderr'){
            $self->_stderr;
        }
    }
}
sub unhook {
    my ($self, $handle) = @_;

    my @handles;

    if ($handle){
        push @handles, $handle;
    }
    else {
        @handles = qw(stdout stderr);
    }

    for (@handles){
        if ($_ eq 'stdout'){
            select uc $_ or die $!;
            $self->{stdout}{state} = 0;
        }
        if ($_ eq 'stderr'){
            close STDERR;
            open STDERR, ">&$self->{stderr}{handle}" or die $!;
            $self->{stderr}{state} = 0;
        }
    }
}
sub stdout {
    my $self = shift;
    return split /\n/, $self->{stdout}{data};
}
sub stderr {
    my $self = shift;
    return split /\n/, $self->{stderr}{data};
}
sub _stdout {
    my $self = shift;
    open $self->{stdout}{handle}, '>>', \$self->{stdout}{data}
      or die "Cannot duplicate STDOUT: $!";
    $self->{stdout}{state} = 1;
}
sub _stderr {
    my $self = shift;
    open $self->{stderr}{handle}, ">&STDERR" or die $!;
    close STDERR;
    open STDERR, '>>', \$self->{stderr}{data} or die $!;
}
=head1 NAME

Hook::Output::Tiny - Easily enable/disable capturing of STDOUT/STDERR

=head1 SYNOPSIS

=head1 METHODS

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hook::Output::Tiny

=head1 SEE ALSO


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Hook::Output::Tiny
