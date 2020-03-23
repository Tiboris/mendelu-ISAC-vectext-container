package Tk::VEntry;

use vars qw($VERSION);
$VERSION = '0.1';

use base qw(Tk::Derived Tk::Entry);
use strict;
use Carp;

import Tk qw(Ev);

Construct Tk::Widget 'VEntry';

my %bindings = (
    'key' => '<KeyRelease>',
    'focusIn' => '<FocusIn>',
    'focusOut' => '<FocusOut>',
);

#
#
#
sub ClassInit#{{{
{
    my ($class, $mw) = @_;

    $class->SUPER::ClassInit($mw);

    # Bind validations on all defined actions
    $mw->bind($class, $bindings{$_}, [\&validateIt, $_]) for grep { $_ ne 'key' } keys %bindings;
    $mw->bind($class, '<KeyPress>', [\&keyPress, Ev('A')]);
    #$mw->bind($class, '<BackSpace>', \&backspace);
}#}}}
sub Populate#{{{
{
    my ($self, $args) = @_;

    $self->SUPER::Populate($args);
    $self->ConfigSpecs(
        -bell       => ['PASSIVE',  undef, undef, 1],
        -rules      => ['PASSIVE',  undef, undef, {}],
        -message    => ['PASSIVE',  undef, undef, $self->defaultErrorMessage],
        -onSuccess  => ['CALLBACK', undef, undef, sub {}],
        -onFail     => ['CALLBACK', undef, undef, \&defaultOnFail],
    );
}#}}}
#
#
#
sub validateIt#{{{
{
    # NOTE added option to suppress default Callbacks
    my ($self, $key, $ins, $preventCallback) = @_;
    my @rules = $self->getAssociatedRules($key);
    my $args  = $self->getValidationArgs($ins);
    #print join(";", @rules), "\n";
    #warn 'validation happend';
    my $result = $self->callValidations($args, @rules);
    $self->doCallbacks($result, $args) unless $preventCallback;
    # NOTE instead of $result (true is right) returns error message
    # inverse logic --- possibly rename this method
    return $result ? undef : $self->msg;
}#}}}
sub doCallbacks#{{{
{
    my ($self, $result, $args) = @_;
    $self->doBell unless $result;
    $self->Callback(($result ? '-onSuccess' : '-onFail') => @$args);
}#}}}
sub callValidations#{{{
{
    my $self = shift;
    my $args = shift;
    my $result = 1;
    {
        no strict 'refs';
        $result &&= ref() ? &$_(@$args) : $self->$_(@$args) for @_;
    }
    return $result;
}#}}}
sub getAssociatedRules#{{{
{
    my ($self, $key) = @_;
    my %allRules = %{ $self->cget('-rules') };
    my @keys = grep { exists $allRules{$_} } ($key, 'all');
    my @rules = map { $self->mapRules($allRules{$_}) } @keys;
    return $self->filterRules(@rules);
}#}}}
sub getValidationArgs#{{{
{
    # NOTE added $self and message to @args
    no warnings;
    my ($self, $ins) = @_;
    my $msg = $self->msg;
    my $index = $self->index('insert');
    my $current = $self->get;
    my $proposed = substr($current, 0, $index) . $ins . substr($current, $index);
    my @args = ($proposed, $ins, $current, $index, $self, $msg);
    return \@args;
}#}}}
sub isValidRule#{{{
{
    my ($self, $rule) = @_;
    return ref $rule || $self->can($rule);
}#}}}
sub filterRules#{{{
{
    my $self  = shift;
    my @rules = @_;
    #$self->invalidRuleError($_) for grep { not $self->isValidRule($_) } @rules;
    grep { $self->isValidRule($_) } @rules;
}#}}}
sub mapRules#{{{
{
    my ($self, $key) = @_;
    return ref $key eq 'ARRAY' ? @$key : $key;
}#}}}
sub invalidRuleError#{{{
{
    my ($self, $rule) = @_;
    $self->Tk::Error("\"$rule\" isn't subroutine reference or predefined validation rule.");
}#}}}
sub defaultErrorMessage#{{{
{
    "$_[0] is not valid.";
}#}}}
sub defaultOnFail#{{{
{
    $_[4]->doBell;
    print STDERR $_[5];
}#}}}
sub doBell#{{{
{
    $_[0]->bell if $_[0]->cget('-bell');
}#}}}
sub msg#{{{
{
    $_[0]->cget('-message') . "\n";
}#}}}
sub keyPress#{{{
{
    my ($self, $a) = @_;
    return unless (defined $a && $a ne ''); 
    $self->SUPER::Insert($a) unless $self->validateIt('key', $a);
}#}}}
sub backspace#{{{
{
    #TODO retrieve deleted character and call validation
    # probably not even necessary
    my $self = shift;
    $self->SUPER::Backspace;
}#}}}
#
# Predefined validation rules
#
#TODO add new and polish current validation rules
sub notEmpty#{{{
{
    return $_[1] !~ /^$/;
}#}}}
sub ungsigned#{{{
{
    return $_[1] =~ /^[^-+]/;
}#}}}
sub realNumber#{{{
{
    return $_[1] =~ /^(()|([-+]?((\d+(\.\d+)?)|(\.\d+))))$/;
}#}}}
sub realNumberChar#{{{
{
    return $_[1] =~ /^[-+0-9\.]*$/;
}#}}}
sub percentNumber#{{{
{
    return $_[1] =~ /^(()|(1(\.0+)?)|(0(\.\d+)?)|(\.\d+))$/;
}#}}}
sub percentNumberChar#{{{
{
    return $_[1] =~ /^[\d\.]*$/
}#}}}
sub number#{{{
{
    return $_[1] =~ /^(()|([-+]?\d+))$/;
}#}}}
sub numberChar#{{{
{
    return $_[1] =~ /^[-+\d]*$/;
}#}}}


1;

__END__

=head1 NAME

Tk::VEntry -- Entry widget with extended validations

=head1 VERSION

This document describes Tk::VEntry version 0.1

=head1 SYNOPSIS

    use Tk::VEntry;

    $mw->VEntry(
        -bell       => 1,
        -rules      => {
            'key'       => 'numberChar',
            'focusIn'   => \&isNumber,
            'focusOut'  => ['number'],
            'send'      => ['number', 'notEmpty'],
        },
        -message    => 'value must be an integer',
        -onSuccess  => \&valid,
        -onFail     => sub { print 'Not valid: ', $_[0]->msg; },
    )->pack;

    sub isNumber {...}
    sub valid    {...}

=head1 DESCRIPTION

Tk::VEntry is extension to Tk::Entry widget. It provides new way to define
validation rules. You can choose multiple rules for each event that can trigger
validation and also use predefined rules. There are two possible callbacks, one
for successful validation and one for unsuccessful. If none are provided,
defaults will be used. You can also set an error message which can be  used in
callbacks. Last option allows you to automatically do "bell" sound, when
validation fails.

=head1 OPTIONS

=over

=item -bell

Allows you to automatically do "bell" sound, when validation fails. It accepts
true or false.

By default it's turned on.

=item -rules

Definition of validation rules by hash reference. Keys of this hash corresponds
to events that triggers the validation. Accepted values are either scalar or
array reference containing scalar values. Those scalars must be a subroutine
reference or string with name of predefined validation rule. Subroutine needs to
return true for valid value and false for invalid value.

By default it's empty.

=over

=item * key

validation will be called when key is pressed

=item * focusIn

validation will be called when widget gets focus

=item * focusOut

validation will be called when widget loses focus

=item * send

validation will be called when VButton is pressed

=item * all

validation will be called for all above

=back

=item -message

You can define message, that is (by default) used when validation fails. It can
be retrieved by calling method C<< $self->msg >>.

By default it's set to: C<"$widget is not valid.">

=item -onSuccess

This callback subroutine will be called if validations are successful. It
accepts Perl/Tk callback.

By default it does nothing.

=item -onFail

This callback subroutine will be called if validations are unsuccessful. It
accepts Perl/Tk callback.

By default it prints I<message> to STDERR.

=back

=head1 CALLBACK ARGUMENTS

Every callback subroutine (including validation rules) is called with following
arguments:

=over

=item * proposed value

=item * inserted character

=item * current value

=item * index of added or deleter character

=item * entry's reference

=item * error message

=back

=head1 PREDEFINED RULES

These rules can be included inside I<rules> definition by using string value with
name of predefined rule.

=over

=item notEmpty

Returns true if value isn't empty.

=item unsigned

Returns true if value's first char isn't plus or minus sign.

=item number

Returns true if value's number with optional plus or minus sign, or empty.

=item numberChar

Returns true if value's consiting only from numbers and plus or minus sign.

=item realNumber

Returns true if value's real number with optional plus or minus sign, or empty.
Accepts also shot notation without leading zeros.

=item realNumberChar

Returns true if value's consiting only from numbers, dot and plus or minus sign.

=item percentNumber

Returns true if value's a real number between 0 and 1 or empty.

=item percentNumberChar

Returns true if value's consiting only from numbers and dot.

=back

=head1 DIAGNOSTICS

=over 4

=item C<< "$rule" isn't subroutine reference or predefined validation rule. >>

You used scalar value that isn't subroutine reference or string that isn't name
of predefined rule (possibly misspelled) in rules definition.

=back

=head1 BUGS

To be found.

=head1 DEPENDENCIES

Requires: Tk::Entry as base widget

=head1 SEE ALSO

Tk, Tk::Entry, Tk::VButton

=cut
