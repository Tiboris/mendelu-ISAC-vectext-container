package PrepareInputWindow;

use vars qw/$VERSION/;
$VERSION = 1.0;

use base qw/Tk::Derived Tk::Toplevel/;
use Tk::widgets qw/Button Entry Label ProgressBar ROText/;
use strict;
use Carp;

Tk::Widget->Construct('PrepareInputWindow');

my $input;
my $output;
my $step;

my $detail_toggle = 0;
my $interrupt = 0;

sub ClassInit#{{{
{
    my ($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
    #$mw->bind($class, "<FocusOut>" => sub { $mw->focusNext; });

    return $class;
}#}}}
sub Populate#{{{
{
    my ($self, $args) = @_;
    $self->SUPER::Populate($args);

    $self->protocol("WM_DELETE_WINDOW", [\&Close, $self]);
    $self->transient($self->parent);
    $self->withdraw;

    # FILLING WITH STUFF
    # MAIN #{{{
    my $main = $self->Frame(
        -borderwidth => 2,
    )->grid;

    # FILES {{{
    my $input_l = $main->Label(
        -text => "Input file:",
    );
    my $input_e = $main->Entry(
        -width => 25,
        -textvariable => \$input,
    ),
    my $input_b = $main->Button(
        -text => "Select a file",
        -command => sub{
            $input = $self->getOpenFile;
        },
    );
    $input_l->grid(-row => 0, -column => 0, -sticky => 'e');
    $input_e->grid(-row => 0, -column => 1);
    $input_b->grid(-row => 0, -column => 2);

    my $output_l = $main->Label(
        -text => "Output file:",
    );
    my $output_e = $main->Entry(
        -width => 25,
        -textvariable => \$output,
    ),
    my $output_b = $main->Button(
        -text => "Select a file",
        -command => sub{
            $output = $self->getSaveFile;
        },
    );
    $output_l->grid(-row => 1, -column => 0, -sticky => 'e');
    $output_e->grid(-row => 1, -column => 1);
    $output_b->grid(-row => 1, -column => 2);
    # }}}
    # PROGRESS {{{
    my ($bar) = $main->ProgressBar(
        -variable => \$step, -gap => 0, -width => 20, -relief => "sunken",
        -borderwidth => 2, 
    )->grid(-column => 0, -columnspan => 3, -sticky => 'ew'); #}}}

    my $detail_t = $main->Scrolled("ROText", -scrollbars => "e",
        -width => 30,
        -height => 10,
        -bg => 'white',
        -wrap => 'word',
    );
    $detail_t->grid(-column => 0, -columnspan => 3, -sticky => 'ew') if $detail_toggle;
    # }}}
    # OPTIONS {{{
    my $options = $self->Frame(
        -borderwidth => 2, 
    )->grid;
    # }}}
    # BUTTONS {{{
    my $buttons = $self->Frame(
        -borderwidth => 2,
    )->grid;

    my $prepare_b;
    my $detail_b;
    my $close_b;

    $prepare_b = $buttons->Button(
        -text => "Stem it!",
        -underline => 0,
        -command => sub {
            # set interrupt based on text of main button
            my $text = $prepare_b->cget("-text");
            $interrupt = (scalar ($text eq "Cancel")) ? 1 : 0;
            unless ($interrupt)
            {
                my %settings = (
                    -locale => undef, #$choices{$lang},
                    -level => 0,
                );
                # deny closing window with X and close button
                $self->protocol("WM_DELETE_WINDOW", undef);
                $close_b->configure(-state => "disable"); 

                my $prepare_text = $prepare_b->cget('-text');
                $prepare_b->configure(-text => "Cancel");

                # empty detail text
                $detail_t->delete('1.0','end');
                $step = 0;

                # Print prepare info
                $detail_t->insert('end', "Preparing data...\n\n");
                $self->update;
                $detail_t->yview('end');

                # Files check
                if ($input ne "" && $input eq $output)
                {
                    $detail_t->insert('end', "Please choose different files for input and output file.\n");
                    $detail_t->parent->parent->update;
                    $detail_t->yview('end');
                }

                # Backup to keep original $output if Cancel occures
                rename $output, $output.".bkp" if -e $output;

                open IN,  "<", $input  or $detail_t->insert('end', "Problem with input file \"$input\": either it doesn't exists or it isn't readable.\n");
                open OUT, ">", $output or $detail_t->insert('end', "Problem with output file \"$output\": either it doesn't exists or it isn't writable.\n");
                if (-r $input && -w $output)
                {
                    my $max = 0;
                    $max++ while <IN>;
                    $bar->configure(-from => 0, -to => $max);
                    $step = 0;

                    open IN, "<", $input;
                    while (<IN>)
                    {
                        last if $interrupt;
                        chomp;
                        my @args = ($_);
                        print OUT $self->Callback('-command' => @args);
                        my $text = "processing: line\t"." "x(length($max)-length(++$step)). $step ."/$max\n";
                        $detail_t->insert('end', $text);
                        $detail_t->yview('end');
                    }
                    my $status = $interrupt ? "Canceled" : "Done";
                    $detail_t->insert('end', "\n$status!");
                    $detail_t->yview('end');
                }
                close IN;
                close OUT;

                if ($interrupt)
                {
                    # Cancled -> restore $output from bkp
                    rename $output.".bkp", $output;
                }
                else
                {
                    # Not canceled -> remove bkp
                    unlink $output.".bkp";
                }

                $prepare_b->configure(-text => $prepare_text);

                # allow closing window again
                $close_b->configure(-state => "normal"); 
                $self->protocol("WM_DELETE_WINDOW", [\&Close, $self]);
            }
        },
    ); 

    $detail_b = $buttons->Button(
        -text => "Detail",
        -underline => 1,
        -command => sub {
            # toggle text detail
            if ($detail_toggle)
            {
                $detail_t->gridForget;
            }
            else
            {
                $detail_t->grid(-row => 4, -column => 0, -columnspan => 3, -sticky => 'ew');
            }
            $detail_toggle = !$detail_toggle;
        },
    );

    $close_b = $buttons->Button(
        -text => "Close",
        -underline => 2,
        -command => [\&Close, $self],
    );

    $prepare_b->grid(
        -row => 0, -column => 0, -columnspan => 1, -sticky => 'ew',
    );
    $detail_b->grid(
        -row => 0, -column => 1, -columnspan => 1, -sticky => 'ew',
    );
    $close_b->grid(
        -row => 0, -column => 2, -sticky => 'ew',
    );
    # }}}

    # CONFIG SPECS
    $self->ConfigSpecs(
        #-foreground => ['DESCENDANTS', 'foreground', 'Foreground', 'black'],
        #-background => ['DESCENDANTS', 'background', 'Background',  undef],
        -input      => ['PASSIVE', undef, undef, "Input file:"],
        -output     => ['PASSIVE', undef, undef, "Output file:"],
        #-step       => ['PASSIVE', undef, undef, undef],
        #-title      => ['SELF', undef, undef, "Prepare input"],
        -text       => [$prepare_b, 'text', 'Text', "Prepare"],
        -command    => ['CALLBACK', 'command', 'Command', undef],
    );
    $self->Delegates('Construct', $options);
}#}}}
sub Show#{{{
{
    croak "FOO" if scalar @_ < 1;
    my $self = shift;
    my ($grab) = @_;
    $self->Popup(@_);
    $self->grab;
}#}}}
sub Close#{{{
{
    $_[0]->destroy;
}#}}}

1;
