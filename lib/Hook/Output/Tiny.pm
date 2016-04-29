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
    my ($self, $handle) = @_;

    my @handles = $self->_handles($handle);

    if (grep {$_ eq 'stderr'} @handles){
        $self->_stderr;
    }
    if (grep {$_ eq 'stdout'} @handles){
        $self->_stdout;
        select $self->{stdout}{handle};
    }
}
sub unhook {
    my ($self, $handle) = @_;

    my @handles = $self->_handles($handle);

    if (grep {$_ eq 'stderr'} @handles){
        close STDERR;
        open STDERR, ">&$self->{stderr}{handle}" or die $!;
        $self->{stderr}{state} = 0;
    }
    if (grep {$_ eq 'stdout'} @handles){
        select STDOUT or die $!;
        $self->{stdout}{state} = 0;
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
sub flush {
    my ($self, $handle) = @_;

    my @handles = $self->_handles($handle);

    for (@handles){
        delete $self->{$_}{data};
    }
}
sub write {
    my ($self, $fn, $handle) = @_;

    open my $wfh, '>>', $fn or die $!;

    my @handles = $self->_handles($handle);

    for (@handles) {
        print $wfh $_ for @{ $self->{$_}{data} };
        $self->flush($_);
    }

    close $wfh;
}
sub _stdout {
    my $self = shift;
    open $self->{stdout}{handle}, '>>', \$self->{stdout}{data}
      or die "can't hook STDOUT: $!";
    $self->{stdout}{state} = 1;
}
sub _stderr {
    my $self = shift;
    open $self->{stderr}{handle}, ">&STDERR" or die $!;
    close STDERR;
    open STDERR, '>>', \$self->{stderr}{data} or die $!;
}
sub _handles {
    my ($self, $handle) = @_;

    my @handles;

    if ($handle){
        push @handles, $handle;
    }
    else {
        push @handles, 'stdout', 'stderr';
    }
    return @handles;
}
=head1 NAME

Hook::Output::Tiny - Easily enable/disable capturing of STDOUT/STDERR

=head1 SYNOPSIS

use Hook::Output::Tiny;

my $h = Hook::Output::Tiny->new;

# capture either STDOUT or STDERR

$h->hook('stdout');
my @out = $h->stdout;

$h->hook('stderr');
my @err = $h->stderr;

# un-capture either

$h->unhook('stdout');
$h->unhook('stderr');

# capture and un-capture both simultaneously

$h->hook;
$h->unhook;

=head1 DESCRIPTION

Extremely lightweight mechanism for capturing C<STDOUT>, C<STDERR> or both.

We save the captured output internally for the entire process run, so on long
running applications, memory usage may become an issue if you don't flush out
the data.

There are many modules that perform this task. I wrote this one for fun, and to
be as small as possible.

=head1 METHODS

=head2 new

Returns a new L<Hook::Output::Tiny> instance.

=head2 hook

You can send in either C<'stdout'> or C<'stderr'> and we'll capture that data.
If you don't specify an option, we'll capture both (and keep the data separate
internally).

=head2 unhook

Send in either C<'stdout'> or C<'stderr'>. If not specified, we'll un-capture
both.

=head2 stdout

Returns a list of all the C<STDOUT> entries that have been caught.

=head2 stderr

Returns a list of all the C<STDERR> entries that have been caught.

=head2 write($filename, $handle)

Writes to C<$filename> the entries in C<$handle>, where C<$handle> is either
C<stdout> or C<stderr>. If no C<$handle> is specified, we'll write out both
handles to the same file.

We then C<flush()> the respective handle data.

=head2 flush

Deletes all data for the handles. Send in either C<'stdout'> or C<'stderr'> to
specify which to delete, otherwise we'll delete both.

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
