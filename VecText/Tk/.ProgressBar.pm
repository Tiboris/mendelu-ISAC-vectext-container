##################################################
##################################################
##						##
##	ProgressBar - a reusable Tk-widget	##
##		  giving a Thermometer display	##
##						##
##	Version 1.0				##
##						##
##	Brent B. Powers	(B2Pi)			##
##	Merrill Lynch				##
##	powers@.ml.com				##
##						##
##						##
##################################################
##################################################

###############################################################################
###############################################################################
## ProgressBar
##    Object Oriented Thermometer Bar for Perl/Tk
##
##
## Changes:
## Ver 1.0 Initial Release
##
## Documentation:
##    See POD after _END_
##
## To Do
##    Add support for vertical meters, allow reversal
##
###############################################################################
###############################################################################

package Tk::ProgressBar;

use strict;
require Tk::Widget;

@Tk::ProgressBar::ISA = qw ( Tk::Frame Tk::Dervied);

Tk::Widget->Construct('ProgressBar');

$Tk::ProgressBar::VERSION = 1.0;

### A couple of convenience variables
my(@bw2) = (-borderwidth => 2);
my (@bothfill) = (-fill => 'both');
my(@expand) = (-expand => 1);

sub Populate {
    ### ProgressBar constructor.  Uses new inherited from base class
    my($self) = shift;

    $self->SUPER::Populate(@_);

    ## Put a frame on the base
    my($base) = $self->{base} = $self->Frame(@bw2)->pack(@expand,@bothfill);

    my($c) = $base->Canvas->pack(@expand,@bothfill);

    my($baseFrame) =$base->Frame(@bw2)->pack(@expand,@bothfill);

    $c->create('window',0,0,
	       -window => $baseFrame,
	       -anchor => 'nw');

    ## Finally, throw the bar into the base frame
    my($bar) = $self->{bar} = $baseFrame->Frame(-width => 0)
	    ->pack(-fill => 'y', -side => 'left');

    ### Set up configuration
    $self->ConfigSpecs(
		       -foreground  => ['METHOD',undef,undef,'blue'],
		       -background  => [$c,undef,undef,'white'],
		       -relief      => [$baseFrame,'relief','Relief','raised'],
		       -backrelief  => ['METHOD','relief','Relief','sunken'],
		       -height	    => ['DESCENDANTS',,'height','Height',20],
		       -UpdateHook  => ['PASSIVE',undef,undef,undef],
		       -max         => ['PASSIVE',undef,undef,100],
		       -step        => ['PASSIVE',undef,undef,0]
		      );
}

1;

sub Version {return $Tk::ProgressBar::VERSION;}

sub backrelief {
    shift->{base}->configure(-relief => shift);
}

sub foreground {
    shift->{bar}->configure(-background => shift);
}

sub DoWhenIdle {
    my($self, $m, $s, $p) = shift;

    $m = $self->{Configure}{-max};
    $s = $self->{Configure}{-step};
    $p = int($s*100/$m);

    $self->{bar}->configure(-width => $p/100*$self->Width);
    if (defined($self->{Configure}{-UpdateHook})) {
	&{$self->{Configure}{-UpdateHook}}($p, $s, $m);
    }
    $self->update;
}

__END__

=head1 NAME - Tk::ProgressBar

=head1 DESCRIPTION

An Object-Oriented, sort-of animated Thermometer (Bells, Whistles) display for Perl/Tk, often useful for Wait Boxes (See Tk::WaitBox) and other cpu-intensive tasks.

=head1 SYNOPSIS

=over 4

=item Basic Usage

To use, just create and configure (I<See sample code>)

=item Configuration

Configuration may be done at creation or via the configure method.  The following methods are configurable:

=over 4

=item -foreground

Sets the color of the filled portion of the ProgressBar. I<Default 'blue'>

=item -background

Sets the color of the empty (unfilled) portion of the ProgressBar. I<Default 'white'>

=item -relief

Sets the relief of the filled portion of the ProgressBar.  I<Default 'raised'>

=item -backrelief

Sets the relief of the empty (unfilled) portion of the ProgressBar. I<Default 'sunken'>

=item -height

Sets the width of the ProgressBar. No provision is currently made for ProgressBars that fill top-to-bottom, bottom-to-top, or anything other than left-to-right.  Maybe someday.  I<Default 20>


=item -UpdateHook

Sets a routine to be called whenever the ProgressBar is updated.  This routine will be called with parameters of (in order) current percentage, current value, and max value. (I<See -step, -max, and, again, sample code>) I<Default none>

=item -step

Sets the current value of the ProgressBar.  The 'fullness' of the ProgressBar will be calculated as int(step/max*100)  I<Default 0>

=item -max

Sets the maximum range of the ProgressBar. I<Default 100>

=back


=item Sample Code

=over 4

=item

  #!/usr/local/bin/perl -w

  use Tk;
  use Tk::WaitBox;
  use Tk::ProgressBar;

  use strict;

  my($root) = MainWindow->new;

  my($utxtbase) = "Initializing";
  my($utxt) = $utxtbase;

  $root->Label(-textvariable => \$utxt)
	  ->pack(-expand => 1, -fill => 'x');

  my($t) = $root->ProgressBar->pack;

  $t->configure(-UpdateHook => \&Hook,
		-relief => 'sunken',
		-backrelief => 'raised');

  $root->update;
  $root->deiconify;

  my($i,@a);
  my($tot) = 2000;

  $t->configure(-step => 0, -max => $tot);

  $utxtbase = "Filling";

  srand(time|$$);

  for ($i = 0; $i <= $tot; $i++) {
      if (($i % 10) == 0) {
	  $t->configure(-step => $i);
      }
      @a[$i] = int(rand(10001));
  }

  $i = 0;
  my($max) = int(2 * $tot * log($tot));
  print "Maybe $max steps?\n";

  $t->configure(-max => $max);

  $max = $max /1000;
  $utxtbase = "Sorting";

  foreach (sort {
      if (($i % $max) == 0) {
	  $t->configure(-step => $i);
      }
      $i++;
      $a <=> $b
  } @a) {
  }
  print "$i sort steps for $tot\n";

  sub Hook {
      my($percent) = shift;
      $utxt = "$utxtbase $percent%";

      ## Alternatively,
      #     my($percent, $step, $max) = @_;
      #     $utxt = "$utxtbase $percent% step $step of $max";
  }

=back

=back

=head1 Author

B<Brent B. Powers, (B2Pi)>
 powers@ml.com

This code may be distributed under the same conditions as perl itself.

=cut
