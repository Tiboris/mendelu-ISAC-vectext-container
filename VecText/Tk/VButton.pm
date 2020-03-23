package Tk::VButton;

use vars qw($VERSION);
$VERSION = '0.1';

use base qw(Tk::Derived Tk::Button);
use vars qw($entries);
use strict;

import Tk qw(Ev);

Construct Tk::Widget 'VButton';

#
#
#
sub ClassInit#{{{
{
    my ($class, $mw) = @_;

    $class->SUPER::ClassInit($mw);

    # Binds
    # NOTE none needed so far

    return $class;
}#}}}
sub Populate#{{{
{
    my ($self, $args) = @_;

    $self->SUPER::Populate($args);
    $self->ConfigSpecs(
        -include        => ['PASSIVE',  undef, undef, [$self->extractToplevel]],
        -exclude        => ['PASSIVE',  undef, undef, []],
        -ignoreDisabled => ['PASSIVE',  undef, undef, 1],
        -preventDefault => ['PASSIVE',  undef, undef, 0],
        -invalidCommand => ['CALLBACK', undef, undef, [\&defaultInvalidCommand]],
    );
}#}}}
#
#
#
sub invoke#{{{
{
    my $self = shift;
    $self->findWidgets;
    my @errors = $self->validateIt;
    @errors ? $self->Callback('-invalidCommand' => ($self, @errors)) : $self->SUPER::invoke;
}#}}}
sub findWidgets#{{{
{
    my $self = shift;
    $entries = [];
    # grab include and exclude references
    # fix anonymous array thing
    # extract widgets
    #   setup in/excludes by going through array
    #       check if widget is allowed
    #       VEntries keep as it is
    #       walk frames only for VEntries
    #   include minus exclude
    # validate in invoke method

    # grab include and exclude references
    my $include = $self->cget('-include');
    my $exclude = $self->cget('-exclude');

    # fix anonymous array thing
    my @include = $self->mapReferences($include);
    my @exclude = $self->mapReferences($exclude);

    # extract widgets
    @include = $self->getVEntryWidgets(@include);
    @exclude = $self->getVEntryWidgets(@exclude);

    # remove excluded widgets
    $entries = [ $self->diff(\@include, \@exclude) ];
}#}}}
sub validateIt#{{{
{
    my $self    = shift;
    my $result  = 1;
    my $prevent = $self->cget('-preventDefault');
    grep { defined } map { $_->validateIt('send', undef, $prevent) } @$entries;
    #$result &&= $_->validateIt('send', undef, $prevent) for @$entries;
    #return $result;
}#}}}
sub invalidReferenceError#{{{
{
    my ($self, $ref) = @_;
    $self->Tk::Error("\"$ref\" isn't Tk::Frame or Tk::VEntry.");
}#}}}
sub isValidReference#{{{
{
    my ($self, $r) = @_;
    # NOTE cause fatal error
    #my $result = $self->isFrame($r) || $self->isVEntry($r);
    my $result = (ref $r) =~ /^Tk::((Frame)|(VEntry))$/;
    $self->invalidReferenceError($r) unless $result;
    return $result;
}#}}}
sub extractToplevel#{{{
{
    $_[0]->extractFrame($_[0]->toplevel);
}#}}}
sub extractFrame#{{{
{
    my ($self, $w) = @_;
    my @result;
    $w->Walk(\&saveTo, \@result, $self);
    return @result;
}#}}}
sub saveTo#{{{
{
    my $w    = shift;
    my $arr  = shift;
    my $self = shift;
    push @$arr, $w if $self->isVEntry($w);
}#}}}
sub mapReferences#{{{
{
    my ($self, $ref) = @_;
    return ref $ref eq 'ARRAY' ? @$ref : $ref;
}#}}}
sub isFrame#{{{
{
    return $_[1]->class eq 'Frame';
}#}}}
sub isVEntry#{{{
{
    return $_[1]->class eq 'VEntry';
}#}}}
sub isDisabled#{{{
{
    $_[1]->cget('-state') eq 'disabled';
}#}}}
sub getVEntryWidgets#{{{
{
    my $self = shift;
    my @widgets = grep { $self->isValidReference($_) } @_;
    @widgets = map { $self->isFrame($_) ? $self->extractFrame($_) : $_ } @widgets;
    @widgets = grep { not $self->isDisabled($_) } @widgets if $self->cget('-ignoreDisabled');
    return @widgets;
}#}}}
sub diff#{{{
{
    my $self = shift;
    my $include = shift;
    my $exclude = shift;
    my %help = map { $_ => 1 } @$exclude;
    grep { not defined $help{$_} } @$include;
}#}}}
sub defaultInvalidCommand#{{{
{
    my $self = shift;
    my $box  = $self->toplevel->DialogBox(
        -title => 'Errors',
        -buttons => ['Close'],
    );
    $box->Label(-text => $_)->pack(-anchor => 'w') for @_;
    $box->Show;
}#}}}


1;

__END__

=head1 NAME

Tk::VButton -- Button widget with extended validations

=head1 VERSION

This document describes Tk::VButton version 0.1

=head1 SYNOPSIS

    use Tk::VButton;

    $ventry_one = $mw->VEntry(...)->pack;
    $frame      = $mw->Frame(...)->pack;
    $ventry_two = $frame->VEntry(...)->pack;

    $mw->VButton(
        -include        => [$frame, $ventry_one],
        -exclude        => [$ventry_two],
        -ignoreDisabled => 1,
        -preventDefault => 0,
        -invalidCommand => \&invalid,
    )->pack;

    sub invalid {...}

=head1 DESCRIPTION

Tk::VButton is extension to Tk::Button widget. It's used in combination with
Tk::VEntry to provide send event for validation. Every VButton is bind to
certain amount of VEntries, which determines what VEntry widgets will be
validated by clicking VButton. This can be specified by two options --
C<include> and C<exclude>. Both options accepts multiple references of
Tk::VEntry or Tk::Frame. If Tk::Frame is supplied, widget automatically extracts
VEntry widgets from it, thus you can easily wrap a group of VEntries into Frame
and use just the Frame reference. It's possible to suppress callbacks defined at
individual VEntry widgets and ignore disabled VEntry widgets. If validation
fails, callback subroutine from invalidCommand option is called. To define
callback for successful validation, you can use C<command> option defined by
original I<Button> widget.

Validation will be considered as successful if for all included VEntry widgets
all rules defined at I<send> key in it's C<rules> option returns C<true>
value.

=head1 OPTIONS

=over

=item -include

Accepts scalar value or array reference containing scalar values. Those scalars
must be references to Tk::VEntry or Tk::Frame.

By default it's set to VButton's toplevel, thus includes all VEntry widgets from
same window as VButton's placed.

=item -exclude

Accepts scalar value or array reference containing scalar values. Those scalars
must be references to Tk::VEntry or Tk::Frame. VEntry widgets supplied by this
option will be skipped during validation.

By default it's set to nothing.

=item -ignoreDisabled

Setting this option to true will remove disabled VEntry widgets from validation.
It accepts true/false value.

By default it's turned on.

=item -preventDefault

Setting this option to true will prevent calls of callbacks defined by VEntry
options C<onSuccess> and C<onFail>. It accepts true/false value.

By default it's turned off.

=item -invalidCommand

This callback subroutine will be called if validations are unsuccessful. It
accepts Perl/Tk callback.

By default it shows all error messages in popup window.

This callback subroutine is called with following arguments:

=over 8

=item * reference to VButton itself

=item * array of error messages

=back

=back

=head1 METHODS

=head1 DIAGNOSTICS

=over 4

=item C<< "$ref" isn't Tk::Frame or Tk::VEntry. >>

You used reference that isn't Tk::Frame or Tk::VEntry in C<include> or
C<exclude> definition.

=back

=head1 BUGS

To be found.

=head1 DEPENDENCIES

Requires: Tk::Button as base widget

=head1 SEE ALSO

Tk, Tk::Button, Tk::VEntry

=cut
