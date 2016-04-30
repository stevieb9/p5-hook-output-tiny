package Hook::Output::Tiny;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.05';

sub new {
    return bless {
        stdout => {_struct()},
        stderr => {_struct()},
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

    if (grep {$_ eq 'stdout'} @handles) {
        select STDOUT or die $!;
        $self->{stdout}{state} = 0;
    }
    if (grep {$_ eq 'stderr'} @handles) {
        $self->{stderr}{state} = 0;
        close STDERR;
        open STDERR, ">&$self->{stderr}{handle}" or die $!;
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
    my @handles = $self->_handles($handle);
    for (@handles){
        open my $wfh, '>>', $fn or die $!;
        print $wfh $self->{$_}{data};
        close $wfh;
        $self->flush($_);
    }
}
sub _stdout {
    my $self = shift;
    open $self->{stdout}{handle}, '>>', \$self->{stdout}{data}
      or die "can't hook STDOUT: $!";
    $self->{stdout}{state} = 1;
}
sub _stderr {
    my $self = shift;
    open $self->{stderr}{handle}, ">&STDERR"
      or die "can't hook STDERR: $!";
    close STDERR;
    open STDERR, '>>', \$self->{stderr}{data} or die $!;
}
sub _struct {
     return (
        state => 0,
        handle => *fh,
        data => '',
    );
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

Hook::Output::Tiny - Easily enable/disable trapping of STDOUT/STDERR

=for html
<a href="http://travis-ci.org/stevieb9/p5-hook-output-tiny"><img src="https://secure.travis-ci.org/stevieb9/p5-hook-output-tiny.png"/>
<a href='https://coveralls.io/github/stevieb9/p5-hook-output-tiny?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-hook-output-tiny/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Hook::Output::Tiny;

    my $output = Hook::Output::Tiny->new;

    # trap either

    $output->hook('stdout');
    my @out = $output->stdout;

    $output->hook('stderr');
    my @err = $output->stderr;

    # untrap either

    $output->unhook('stdout');
    $output->unhook('stderr');

    # trap/untrap both simultaneously

    $output->hook;
    $output->unhook;

    # delete all entries from both (can specify individually)

    $output->flush;

    # append to a file (can specify individually)

    $output->write('file.txt');

=head1 DESCRIPTION

Extremely lightweight mechanism for trapping C<STDOUT>, C<STDERR> or both.

We save the captured output internally, so on long running applications, memory
usage may become an issue if you don't C<flush()> out or C<write() out the data.

There are many modules that perform this task. I wrote this one for fun, and to
be as small and as simple as possible.

=head1 METHODS

=head2 new

Returns a new L<Hook::Output::Tiny> instance.

=head2 hook

You can send in either C<'stdout'> or C<'stderr'> and we'll trap that data.

If you don't specify an option, we'll trap both (the data remains separated).

=head2 unhook

Send in either C<'stdout'> or C<'stderr'>. If not specified, we'll untrap
both.

=head2 stdout

Returns a list of all the C<STDOUT> entries that have been trapped.

=head2 stderr

Returns a list of all the C<STDERR> entries that have been trapped.

=head2 write($filename, $handle)

Writes to C<$filename> the entries in C<$handle>, where C<$handle> is either
C<stdout> or C<stderr>. If no C<$handle> is specified, we'll write out both
handles to the same file.

We then C<flush()> (ie. delete) the respective handle data until the next
C<write()> or C<flush()>.

=head2 flush

Deletes all data for the handles. Send in either C<'stdout'> or C<'stderr'> to
specify which to delete, otherwise we'll delete both.

=head1 EXAMPLE

Testing scenario...

    use Foo::Bar;
    use Hook::Output::Tiny;
    use Test::More;

    my $output = Hook::Output::Tiny->new;

    $output->hook;

    my $thing = Foo::Bar->new;

    $output->unhook;

    is ($thing->do(), 1, "thing() ok");
    is ($output->stdout, 1, "got expected STDOUT");
    is ($output->stderr, 0, "got no STDERR");

    for ($output->stdout){
        like ($_, 'Foo::Bar object initialized', "STDOUT ok");
    }

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hook::Output::Tiny

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
