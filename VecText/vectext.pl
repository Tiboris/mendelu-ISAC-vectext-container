use lib '../VecText';
use Tk;
use Tk::BrowseEntry;
use Tk::JBrowseEntry;
use Tk::DialogBox;
use Tk::FileDialog;
use Tk::DirSelect;
use Tk::Help;
use Tk::widgets qw/VEntry VButton PrepareInputWindow/;
use File::Glob;
use Tk::ROText;
use Tk::Menu;
use Tk::Checkbutton;
use Tk::Radiobutton;
use Tk::Listbox;

#use Encode::Unicode;
use strict;
use locale;

if ($^O =~ /MSWin/) {
	use Win32::LongPath;
}

my $mw = MainWindow->new();
$mw->resizable(0, 0);

$mw->title("VecText (Vectorization of Texts)");


# main menu
$mw->configure(-menu => my $menubar = $mw->Menu);

my $project_mi = $menubar->cascade(-label => '~Project', -tearoff => 0);
my $help_mi = $menubar->cascade(-label => '~Help', -tearoff => 0);

$project_mi->command( -label => "Quit", -accelerator => 'Ctrl-q', -underline => 0, -command => \&exit, );

$help_mi->command(
    -label => 'About',
    -accelerator => 'Ctrl-t',
    -underline => 1,
    -command => \&About);
$help_mi->command( -label => 'Help',
    -accelerator => 'Ctrl-h',
    -underline => 1,
    -command => \&showhelp);



my @padding = (-padx => 2, -pady => 2);

# input and output file names and directories

my $f_frame = $mw->Frame(-label => 'Input and output files', -relief => 'groove', -border => 2,
  @padding)->pack;

my $if_frame = $f_frame->Frame(@padding)->pack;



###################
###################
###################
###################


my $input_rb_frame = $if_frame->Frame->pack(-side => "left");

my $input_file;					# name of the file with input data
my $read_directory;				# name of the directory with input data
my ($input_dir_entry, $input_dir_button, $input_file_entry, $input_file_button);
my $input_rb_option = 'file';

# input file radio button
my $radio_file = $input_rb_frame->Radiobutton(-text => "File:",
					-value => "file",
					-variable=> \$input_rb_option,
					-command => sub {
						$input_dir_entry->configure(-state => 'disabled');
						$input_dir_button->configure(-state => 'disabled');
						$input_file_entry->configure(-state => 'normal');
						$input_file_button->configure(-state => 'active');
						$read_directory = '';
					})->pack(-side => "left");

# input file line
$input_file_entry = $input_rb_frame->VEntry(
    -background => 'white',
    -textvariable => \$input_file,
    -width => 40,
    -rules => {
        'send' => 'notEmpty',
    },
    -message => 'You must choose an input file.',
)->pack(-side => 'left', @padding);

# input file button
$input_file_button = $input_rb_frame->Button(
    -text => 'Select a file',
    -command => sub {my $filename = $mw->getOpenFile;
                  $input_file = $filename;
                  },
  )->pack(-side => 'left', -after => $input_file_entry, @padding) or die $!;

# input directory radio button
my $radio_dir = $input_rb_frame->Radiobutton(-text => "Directory: ",
					-value => "dir",
					-variable=> \$input_rb_option,
					-command => sub {
						$input_dir_entry->configure(-state => 'normal');
						$input_dir_button->configure(-state => 'normal');
						$input_file_entry->configure(-state => 'disabled');
						$input_file_button->configure(-state => 'disabled');
						$input_file = '';
					})->pack(-side => "left");

# input directory entry
$input_dir_entry = $input_rb_frame->VEntry(
    -background => 'white',
    -textvariable => \$read_directory,
    -width => 50,
    -rules => {
        'send' => 'notEmpty',
    },
    #-message => 'You must choose to what folder the output file will be saved.',
 )->pack(-side => 'left', @padding);

$input_dir_button = $input_rb_frame->Button(
  -text => 'Select a directory',
  -command => sub {
            # TODO - maybe a more user friendly way of entering output directory and filename
            $read_directory = $input_rb_frame->chooseDirectory(-title => "Select an existing directory in the list below.",
                    -initialdir => "./",
                    -mustexist  => 0
					);

    }
)->pack(-side => 'left', #-after => $output_dir_entry,
@padding);

$input_dir_entry->configure(-state => 'disabled');
$input_dir_button->configure(-state => 'disabled');

my $input_options_frame = $f_frame->Frame->pack;

my $encoding = 'utf8';
my $encoding_label = $input_options_frame->Label(
  -text => 'Encoding ',
  @padding)->pack(-side => 'left');
my $encoding_opt = $input_options_frame->BrowseEntry(
    -background => 'white',
    -choices => ['ascii',
		'iso-8859-1',
		'iso-8859-2',
		'utf8'],
    -variable => \$encoding,
    -width => 9,
	-state => 'readonly',
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$encoding_opt->Subwidget("slistbox")->configure(-height=>4);



# size of the subset of input data
my $subset_size;
my $subset_size_entry = $input_options_frame->VEntry(
    -background => 'white',
    -textvariable => \$subset_size,
    -width => 7,
    -rules => {
        'send' => 'number',		# TODO - not working
    },
    -message => 'The value must be numeric.',
)->pack(-side => 'left', @padding);
my $subset_size_label = $input_options_frame->Label(
    -text => 'Subset size:'
)->pack(-side => 'left', -before => $subset_size_entry, @padding);

# skipping tokens
my $skip_tokens;
my $skip_tokens_entry = $input_options_frame->VEntry(
    -background => 'white',
    -textvariable => \$skip_tokens,
    -width => 5,
    -rules => {
        'send' => 'number',		# TODO - not working
    },
    -message => 'The value must be numeric.',
)->pack(-side => 'left', @padding);
my $skip_tokens_label = $input_options_frame->Label(
    -text => 'Skip tokens:'
)->pack(-side => 'left', -before => $skip_tokens_entry, @padding);

my $randomize = '';
my $randomize_check = $input_options_frame->Checkbutton(
  -text => "Randomize",
  -variable => \$randomize,
)->pack(-side => 'left',  @padding);

# definition of classes
my $classes_frame = $f_frame->Frame()->pack;

# skipping tokens
my $class_position;
my $class_position_entry = $classes_frame->VEntry(
    -background => 'white',
    -textvariable => \$class_position,
    -width => 5,
    -rules => {
        'send' => 'number',		# TODO - not working
    },
    -message => 'The value must be numeric.',
)->pack(-side => 'left', @padding);
my $class_position_label = $classes_frame->Label(
    -text => 'Class position:'
)->pack(-side => 'left', -before => $class_position_entry, @padding);


# form for selecting processed classes
my $processed_classes = '';
my $processed_classes_entry = $classes_frame->VEntry(
  -background => 'white',
  -textvariable => \$processed_classes,
  -disabledbackground => '#eeeeee',
  -width => 30,
  -rules => {
        'send'  => 'notEmpty',
  },
  -message => 'You must specify classes to be processed.',
  -state => 'disabled'
)->pack(-side => 'left', @padding);

my $processed_classes_check = $classes_frame->Checkbutton(
  -text => 'Process only classes with the following labels:',
  -command => sub { my $state =  $processed_classes_entry->cget(-state);
					if ($state eq 'normal') {
						$processed_classes_entry->configure(-state => 'disabled');
						$processed_classes = undef;
					} else {
						$processed_classes_entry->configure(-state => 'normal');
					}
			}, # enabling/disabling input line containing classes to be processed
)->pack(-side => 'left', -before => $processed_classes_entry, @padding);


# form for processing only selected elements
my $tags = '';
my $split_into_elements = '';
my $tags_frame = $f_frame->Frame()->pack;

my $tags_split_check = $tags_frame->Checkbutton(
  -text => "Split into elements' content",
  -state => 'disabled',
  -variable => \$split_into_elements,
)->pack(-side => 'left',  @padding);

my $tags_entry = $tags_frame->VEntry(
  -background => 'white',
  -textvariable => \$tags,
  -disabledbackground => '#eeeeee',
  -width => 50,
  -rules => {
        'send'  => 'notEmpty',
  },
  -message => 'You must specify the tags to be extracted.',
  -state => 'disabled'
)->pack(-side => 'left', -before=> $tags_split_check, @padding);

my $tags_label = $tags_frame->Label(
  -text => 'Extracted elements:'
)->pack( -side => 'left', -before => $tags_entry, @padding);

my $tags_check = $tags_frame->Checkbutton(
  -text => 'Extract contents of given elements',
  -command => sub { my $state =  $tags_entry->cget(-state);

					if ($state eq 'normal') {
						$tags_entry->configure(-state => 'disabled');
						$tags_split_check->configure(-state => 'disabled');
						$tags = undef;
					} else {
						$tags_entry->configure(-state => 'normal');
						$tags_split_check->configure(-state => 'normal');
					}
			}, # enabling/disabling input line containing allowed tags
)->pack(-side => 'left', -before => $tags_label,  @padding);



# form for specification of splitting document into sentences
my $sentences = '';
my $sentences_frame = $f_frame->Frame()->pack;
my $sentences_entry = $sentences_frame->VEntry(
  -background => 'white',
  -textvariable => \$sentences,
  -disabledbackground => '#eeeeee',
  -width => 10,
  -rules => {
        'send'  => 'notEmpty',
  },
  -message => 'You must specify sentence delimiters.',
  -state => 'disabled'
)->pack(-side => 'left', @padding);

my $sentences_label = $sentences_frame->Label(
  -text => 'Sentence delimiters:'
)->pack( -side => 'left', -before => $sentences_entry, @padding);

my $sentences_check = $sentences_frame->Checkbutton(
  -text => 'Split documents into sentences ',
  -command => sub { my $state =  $sentences_entry->cget(-state);
					if ($state eq 'normal') {
						$sentences_entry->configure(-state => 'disabled');
						$sentences = undef;
					} else {
						$sentences_entry->configure(-state => 'normal');
						$sentences = '.!?;';
					}
			}, # enabling/disabling input line containing sentence delimiters
)->pack(-side => 'left', -before => $sentences_label,  @padding);



# name of the directory and file with output data
my ($output_dir, $output_file);

my $output_dir_entry;
my $output_dir_button;

my $of_frame = $f_frame->Frame(	)->pack;

# output directory frame, including radio buttons and file field
my $od_frame = $of_frame->Frame(@padding)->pack;

my $output_dir_option = 'same as input file';

my $output_dir_label = $od_frame->Label(
  -text => 'Output directory:'
)->pack(-side => 'left', @padding);

my $output_dir_rb = $od_frame->Frame->pack(-side => "left", -after => $output_dir_label);

my $radio_current = $output_dir_rb->Radiobutton(-text => "Current",
					-value => "current",
					-variable=> \$output_dir_option,
					-command => sub {
						$output_dir_entry->configure(-state => 'disabled');
						$output_dir_button->configure(-state => 'disabled');
						$output_dir = '';
					})->pack(-side => "left");

my $radio_same_as_input = $output_dir_rb->Radiobutton(-text => "Same as input file",
					-value => "same as input file",
					-variable=> \$output_dir_option,
					-command => sub {
						$output_dir_entry->configure(-state => 'disabled');
						$output_dir_button->configure(-state => 'disabled');
						$output_dir = '';
					})->pack(-side => "left");

my $radio_select = $output_dir_rb->Radiobutton(-text => "Select: ", -value => "select",
					-variable=> \$output_dir_option,
					-command => sub {
						$output_dir_entry->configure(-state => 'normal');
						$output_dir_button->configure(-state => 'normal');
					})->pack(-side => "left");


$output_dir_entry = $od_frame->VEntry(
    -background => 'white',
    -textvariable => \$output_dir,
    -width => 50,
    -rules => {
        'send' => 'notEmpty',
    },
    -message => 'You must choose to what folder the output file will be saved.',
 )->pack(-side => 'left', @padding);


$output_dir_button = $od_frame->Button(
  -text => 'Select a directory',
  -command => sub {
#        my $dialog = $of_frame->DirSelect();# -directory => '.' );
#         $output_dir = $dialog->Show;

            # TODO - maybe a more user friendly way of entering output directory and filename
            $output_dir = $od_frame->chooseDirectory(-title => "Select an existing directory in the list below or enter the name of a new directory in the following input field.",
                    -initialdir => "./",
                    #-mustexist  => 0
					);
#        my $out_dir = $of_frame->FileDialog(
#                  -title => 'Select output directory',
#                  -SelDir => 1,
#                  -Create => 1);
#        $output_dir = $out_dir->Show;
    }
)->pack(-side => 'left', #-after => $output_dir_entry,
@padding);

$output_dir_entry->configure(-state => 'disabled');
$output_dir_button->configure(-state => 'disabled');

my $ofile_frame = $of_frame->Frame(@padding)->pack;

my $output_file_label = $ofile_frame->Label(
  -text => 'Output file name:'
)->pack(-side => 'left',@padding);

my $output_file_option = 'same as input file';
my $output_file_entry;
my $radio_file_same_as_input = $ofile_frame->Radiobutton(-text => "Same as input file",
					-value => "same as input file",
					-variable=> \$output_file_option,
					-command => sub {
						$output_file = '';
	                    $output_file_entry->configure(-state => 'disabled');
						})->pack(
							-side => "left"
						);
my $radio_file_select = $ofile_frame->Radiobutton(-text => "Choose: ", -value => "choose",
					-variable=> \$output_file_option,
					-command => sub {
						$output_file_entry->configure(-state => 'normal');
					})->pack(
						-side => "left"
					);

$output_file_entry = $ofile_frame->VEntry(
  -background => 'white',
  -textvariable => \$output_file,
  -width => 30,
    -rules => {
        'send' => 'notEmpty',
    },
  -message => 'You must choose the output file name.',
  )->pack(-side => 'left', @padding);

$output_file_entry->configure(-state => 'disabled');

my $oformat_frame = $of_frame->Frame(@padding)->pack;

my $output_format = 'ARFF';
my $format_label = $oformat_frame->Label(
  -text => 'Output format',
  @padding)->pack(-side => 'left');

my $format_opt = $oformat_frame->BrowseEntry(
    -background => 'white',
    -choices => ['ARFF', 'Sparse ARFF', 'XRFF', 'Sparse XRFF', 'C5', 'SPARSE', 'CSV', 'CLUTO (sparse)', 'CLUTO (dense)', 'SVMlight', 'YALE'],
    -variable => \$output_format,
    -width => 12,
    -state => 'readonly',
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$format_opt->Subwidget("slistbox")->configure(-height=>11);

my $sort_atr = 'none';
my $sort_atr_label = $oformat_frame->Label(
  -text => 'Sort attributes',
  @padding)->pack(-side => 'left');

my $sort_atr_opt = $oformat_frame->BrowseEntry(
    -background => 'white',
    -choices => ['none', 'alphabetically', 'alphabetically inversely', 'document frequency (descending)', 'document frequency (ascending)'],
    -variable => \$sort_atr,
    -width => 25,
    -state => 'readonly',
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$sort_atr_opt->Subwidget("slistbox")->configure(-height=>5);

my $output_also_frame = $f_frame->Frame(
  @padding)->pack();

my $output_options_label = $output_also_frame->Label(
  -text => 'Output also:'
)->pack(-side => 'left', @padding);

my $print_statistics;
my $print_statistics_check = $output_also_frame->Checkbutton(
    -text => 'statistics',
    -variable => \$print_statistics,
)->pack(-side => 'left');

my $print_original_texts = '';
my $original_text_output = $output_also_frame->Checkbutton(
  -text => 'original texts',
  -variable => \$print_original_texts,
)->pack(-side => 'left',
@padding);

my $print_tokens = '';
my $tokens_output = $output_also_frame->Checkbutton(
  -text => 'tokens',
  -variable => \$print_tokens,
)->pack(-side => 'left',
@padding);

my $print_skipped_tokens = '';
my $skipped_tokens_output = $output_also_frame->Checkbutton(
  -text => 'skipped tokens',
  -variable => \$print_skipped_tokens,
)->pack(-side => 'left',
@padding);


my $create_dictionary = 'no';
my $create_dictionary_opt = $output_also_frame->BrowseEntry(
    -background => 'white',
    -choices => ['no',
		'plain',
		'with frequencies',
		'with frequencies for classes',
		'with document frequencies',
		'with document frequencies for classes',

		],
    -state => 'readonly',
    -variable => \$create_dictionary,
    -width => 28,
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$create_dictionary_opt->Subwidget("slistbox")->configure(-height=>6);
my $create_dictionary_label = $output_also_frame->Label(
 -text => 'dictionary',
  @padding)->pack(-side => 'left', -before => $create_dictionary_opt);


my $n_grams_opt2 = $output_also_frame->Scrolled("Listbox",
	-scrollbars => 'e',
    -background => 'white',
 #   -listvariable => \$list,
    -width => 2,
	-height => 3,
	-selectmode => 'multiple',
)->pack(-side => 'left');
$n_grams_opt2->insert('end',1..9);
$n_grams_opt2->selectionSet(0);
my $n_grams_label2 = $output_also_frame->Label(
  -text => 'N-gram lengths:'
)->pack(-side => 'left', -before => $n_grams_opt2, @padding);


###################################################
#     a frame with preprocessing parameters       #
###################################################

my ($min_local_freq, $max_local_freq, $min_global_freq, $max_global_freq,
	$min_document_freq, $max_document_freq, $min_rel_document_freq, $max_rel_document_freq, $min_w_length, $max_w_length, $df_percentage, $terms_to_keep);

my $prep_par_frame = $mw->Frame(-label => 'Attribute filtering',
  -borderwidth => 2,
  -relief => 'groove',
  @padding)->pack;

my $prep_par_frame1 = $prep_par_frame->Frame(
  @padding)->pack;

my $logarithm_type = 'natural';

my $min_l_f_entry = $prep_par_frame1->VEntry(
  -background => 'white',
  -textvariable => \$min_local_freq,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number'],
  },
  -message => 'Minimal local term frequency must be positive integer.',
  )->pack(-side => 'left', @padding);

my $min_max_l_f_label = $prep_par_frame1->Label(
  -text => 'Minimal/maximal local term frequency:'
)->pack(-side => 'left', -before => $min_l_f_entry, @padding);

my $max_l_f_entry = $prep_par_frame1->VEntry(
  -background => 'white',
  -textvariable => \$max_local_freq,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number', sub { $max_local_freq >= $min_local_freq }],
  },
  -message => 'Maximal local term frequency must be positive integer that is bigger than minimal term local frequency.',
  )->pack(-side => 'left', @padding);

my $min_g_f_entry = $prep_par_frame1->VEntry(
  -background => 'white',
  -textvariable => \$min_global_freq,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number'],
  },
  -message => 'Minimal global term frequency must be positive integer.',
)->pack(-side => 'left', @padding);

my $min_max_g_f_label = $prep_par_frame1->Label(
  -text => 'Minimal/maximal global term frequency:'
)->pack(-side => 'left', -before => $min_g_f_entry, @padding);

my $max_g_f_entry = $prep_par_frame1->VEntry(
  -background => 'white',
  -textvariable => \$max_global_freq,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number', sub { $max_global_freq >= $min_global_freq }],
   },
   -message => 'Maximal global term frequency must be positive integer that is bigger than minimal global term frequency.',
 )->pack(-side => 'left', @padding);


my $prep_par_frame2 = $prep_par_frame->Frame(
  @padding)->pack;

my $min_d_f_entry = $prep_par_frame2->VEntry(
  -background => 'white',
  -textvariable => \$min_document_freq,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number'],
  },
  -message => 'Minimal document term frequency must be positive integer.',
)->pack(-side => 'left', @padding);

my $min_d_f_label = $prep_par_frame2->Label(
  -text => 'Minimal/maximal document frequency:'
)->pack(-side => 'left', -before => $min_d_f_entry, @padding);

my $max_d_f_entry = $prep_par_frame2->VEntry(
  -background => 'white',
  -textvariable => \$max_document_freq,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number', sub { $max_document_freq >= $min_document_freq }],
  },
  -message => 'Maximal document term frequency must be a positive integer that is bigger than the minimal document term frequency.',
)->pack(-side => 'left', @padding);


my $min_rel_d_f_entry = $prep_par_frame2->VEntry(
  -background => 'white',
  -textvariable => \$min_rel_document_freq,
  -width => 5,
  -rules => {
        'key'   => ['percentNumberChar', 'unsigned'],
        'send'  => ['percentNumber', sub { $min_rel_document_freq > 0 and $min_rel_document_freq <= 1 } ],
  },
  -message => 'Minimal relative document term frequency must be a number from the interval (0,1>.',
)->pack(-side => 'left', @padding);

my $min_rel_d_f_label = $prep_par_frame2->Label(
  -text => 'Minimal/maximal relative document frequency:'
)->pack(-side => 'left', -before => $min_rel_d_f_entry, @padding);

my $max_rel_d_f_entry = $prep_par_frame2->VEntry(
  -background => 'white',
  -textvariable => \$max_rel_document_freq,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number', sub { $max_rel_document_freq > 0 and $max_rel_document_freq <= 1 and $max_rel_document_freq >= $min_rel_document_freq }],
  },
  -message => 'Maximal relative document term frequency must be a number from the interval (0,1> that is bigger than the minimal relative document term frequency.',
)->pack(-side => 'left', @padding);


my $prep_par_frame3 = $prep_par_frame->Frame(
  @padding)->pack;

my $terms_to_keep_entry = $prep_par_frame3->VEntry(
  -background => 'white',
  -textvariable => \$terms_to_keep,
  -width => 6,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['number'],
  },
  -message => 'The number of terms to keep must be a number.',
)->pack(-side => 'left', @padding);

my $terms_to_keep_label = $prep_par_frame3->Label(
  -text => 'Number of terms to keep:'
)->pack(-side => 'left', -before => $terms_to_keep_entry, @padding);


my $df_percentage_entry = $prep_par_frame3->VEntry(
  -background => 'white',
  -textvariable => \$df_percentage,
  -width => 5,
  -rules => {
        'key'   => ['percentNumberChar'],
        'send'  => ['percentNumber', sub { $df_percentage > 0 and $df_percentage <= 1 }],
  },
  -message => 'Percentage of terms to keep must be a number from the interval (0,1>.',
)->pack(-side => 'left', @padding);

my $df_percentage_label = $prep_par_frame3->Label(
  -text => 'Percentage of terms to keep according to DF:'
)->pack(-side => 'left', -before => $df_percentage_entry, @padding);



my $min_w_length_entry = $prep_par_frame3->VEntry(
  -background => 'white',
  -textvariable => \$min_w_length,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number'],
  },
  -message => 'Minimal word length must be positive integer.',
)->pack(-side => 'left', @padding);

my $min_max__w_length_label = $prep_par_frame3->Label(
  -text => 'Minimal/maximal word length:'
)->pack(-side => 'left', -before => $min_w_length_entry, @padding);

my $max_w_length_entry = $prep_par_frame3->VEntry(
  -background => 'white',
  -textvariable => \$max_w_length,
  -width => 5,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['notEmpty', 'number', sub { $max_w_length > $min_w_length }],
  },
  -message => 'Maximal word length must be positive integer that is bigger than minimal word length.',
)->pack(-side => 'left', @padding);

my ($preserve_numbers, $remove_URIs, $case, $preserve_symbols, $preserve_emoticons) = (0,0,'lower case','',0);

#my $prep_par_frame = $mw->Frame(-label => 'Preprocessing parameters',
#  -borderwidth => 2,
#  -relief => 'groove',
#  @padding)->pack;

my $prep_par_frame4 = $prep_par_frame->Frame(
  @padding)->pack;

my $remove_URIs_check = $prep_par_frame4->Checkbutton(
    -text => 'Remove URIs',
    -variable => \$remove_URIs,
)->pack(-side => 'left');

my $preserve_numbers_check = $prep_par_frame4->Checkbutton(
    -text => 'Preserve numbers',
    -variable => \$preserve_numbers,
)->pack(-side => 'left');

my $preserve_emoticons_check = $prep_par_frame4->Checkbutton(
    -text => 'Preserve emoticons',
    -variable => \$preserve_emoticons,
)->pack(-side => 'left');

my $preserve_symbols_entry = $prep_par_frame4->VEntry(
  -background => 'white',
  -textvariable => \$preserve_symbols,
  -width => 10,
  )->pack(-side => 'left', @padding);
my $preserve_symbols_label = $prep_par_frame4->Label(
  -text => 'Preserve symbols:'
)->pack(-side => 'left', -before => $preserve_symbols_entry, @padding);

my $case_folding_label = $prep_par_frame4->Label(
  -text => 'Case folding',
  @padding)->pack(-side => 'left');
my $case_folding_opt = $prep_par_frame4->BrowseEntry(
    -background => 'white',
    -choices => ['no',
		'lower case',
		'upper case'],
    -variable => \$case,
    -width => 10,
	-state => 'readonly',
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$case_folding_opt->Subwidget("slistbox")->configure(-height=>3);




##################################################
#              output vector format              #
##################################################

my $local_weights = 'Binary (Term Presence)';
my $global_weights = 'none';
my $normalization = 'none';
my $output_decimal_places = 0;
my $n_grams = '1';

my ($real_k_value_entry, $real_k_value_label, $real_k_value);

my $out_format_frame = $mw->Frame(-label => 'Attribute weighting',
  -borderwidth => 2,
  -relief => 'groove',
  @padding)->pack;

my $out_format_frame1 = $out_format_frame->Frame(
  @padding)->pack;

my $local_weights_label = $out_format_frame1->Label(
  -text => 'Local weights',
  @padding)->pack(-side => 'left');
my $local_weights_opt = $out_format_frame1->BrowseEntry(
    -background => 'white',
    -choices => ['Binary (Term Presence)',
				'Term Frequency (TF)',
				'Squared TF',
				'Thresholded TF',
				'Logarithm',
				'Alternate Logarithm',
				'Normalized Logarithm',
				'Augmented Normalized TF',
				'Changed-coefficient Average TF',
				'Square Root',
				'Augmented Logarithm',
				'Augmented Average TF',
				'DFR-like Normalization',
				"Okapi's TF Factor"],
    -state => 'readonly',
    -variable => \$local_weights,
    -width => 27,
    -disabledbackground => 'white',
    -disabledforeground => 'black',
    -browsecmd => sub {
        # enable/disable entry box
        #my $state = $local_weights eq 'Augmented Normalized Term Frequency' ? 'normal' : 'disabled';
        #$real_k_value_entry->configure('-state', $state);

        # show/hide entry box
        if ($local_weights eq 'Augmented Normalized TF' or
			$local_weights eq 'Augmented Average TF' or
			$local_weights eq 'Augmented Log' or
			$local_weights eq 'Changed-coefficient Average TF')
        {
            $real_k_value_entry->pack(-side => 'left', @padding);
            $real_k_value_label->pack(-side => 'left', -before => $real_k_value_entry, @padding);
            $real_k_value_entry->configure(-state, 'normal');
        }
        else
        {
            $real_k_value_entry->packForget;
            $real_k_value_label->packForget;
        }
    },
)->pack(-side => 'left');
$local_weights_opt->Subwidget("slistbox")->configure(-height=>13);

my $global_weights_label = $out_format_frame1->Label(
  -text => 'Global weights',
  @padding)->pack(-side => 'left');
my $global_weights_opt = $out_format_frame1->BrowseEntry(
    -background => 'white',
    -choices => ['none',
		'Inverse Document Frequency (IDF)',
		'Squared IDF',
		'Probabilistic IDF',
		'Global Frequency IDF',
		'Entropy',
		'Incremented Global Frequency IDF',
		'Log-Global Frequency IDF',
		'Square Root Global Frequency IDF',
		'Inverse Total Term Frequency'],
    -state => 'readonly',
    -variable => \$global_weights,
    -width => 28,
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$global_weights_opt->Subwidget("slistbox")->configure(-height=>10);


my $normalization_label = $out_format_frame1->Label(
  -text => 'Normalization',
  @padding)->pack(-side => 'left');
my $normalization_opt = $out_format_frame1->BrowseEntry(
    -background => 'white',
    -choices => ['none',
		'Cosine',
		'Sum of Weights',
		'Max Weight',
		'Max TF',
		'Square root',
		'Logarithm',
		'Fourth Normalization'],
    -state => 'readonly',
    -variable => \$normalization,
    -width => 14,
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$normalization_opt->Subwidget("slistbox")->configure(-height=>8);

=pod
my $n_grams_opt = $out_format_frame->BrowseEntry(
    -background => 'white',
    -choices => ['-',2..9],
    -variable => \$n_grams,
    -width => 3,
    -state => 'readonly',
    -disabledbackground => 'white',
    #-disabledforeground => 'black',
)->pack(-side => 'left');
$n_grams_opt->Subwidget("slistbox")->configure(-height=>9);
my $n_grams_label = $out_format_frame->Label(
  -text => 'N-grams:'
)->pack(-side => 'left', -before => $n_grams_opt, @padding);
=cut

my $out_format_frame2 = $out_format_frame->Frame(
  @padding)->pack;

my $logarithm_type_label = $out_format_frame2->Label(
  -text => 'Logarithm type',
  @padding)->pack(-side => 'left');
my $logarithm_type_opt = $out_format_frame2->BrowseEntry(
    -background => 'white',
    -choices => ['natural',
		'common'],
    -variable => \$logarithm_type,
    -width => 10,
	-state => 'readonly',
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$logarithm_type_opt->Subwidget("slistbox")->configure(-height=>2);


$real_k_value_entry = $out_format_frame2->VEntry(
    -background => 'white',
    -textvariable => \$real_k_value,
    -width => 5,
    -state => 'disabled',
    -rules => {
        'key'   => ['percentChar', 'unsigned'],
        'send'  => ['notEmpty', 'percent'],
    },
    -message => 'K value must be a float number between 0 and 1.',
)->pack(-side => 'left', @padding);
$real_k_value_label = $out_format_frame2->Label(
    -text => 'K:',
)->pack(-side => 'left', -before => $real_k_value_entry, @padding);
$real_k_value_entry->packForget;
$real_k_value_label->packForget;

my $output_decimal_places_entry = $out_format_frame2->VEntry(
	-background => 'white',
	-textvariable => \$output_decimal_places,
	-width => 3,
	-rules => {
		'key'   => ['numberChar', 'unsigned'],
		'send'  => ['notEmpty', 'number'],
	},
	-message => 'Number of decimal places must be a positive integer.',
	)->pack(-side => 'left', @padding);
my $output_decimal_places_label = $out_format_frame2->Label(
  -text => 'Decimal places:'
)->pack(-side => 'left', -before => $output_decimal_places_entry, @padding);


=pod
my $output_lines;
my $output_lines_label = $out_format_frame->Label(
  -text => 'Records in output file',
  @padding)->pack(-side => 'left');

my $output_lines_entry = $out_format_frame->VEntry(
  -background => 'white',
  -textvariable => \$output_lines,
  -width => 10,
  -rules => {
        'key'   => ['numberChar', 'unsigned'],
        'send'  => ['number'],
  },
  -message => 'Records in output file must be positive integer.',
)->pack(-side => 'left', -after => $output_lines_label);
=cut
###################################################
#    a frame for providing language resources     #
###################################################

my $lr_frame = $mw->Frame(-label => 'Language resources',
  -borderwidth => 2,
  -relief => 'groove',
  @padding)->pack;

my $dictionary_file = '';
my $dictionary_frame = $lr_frame->Frame->pack;
my $dictionary_entry = $dictionary_frame->VEntry(
  -background => 'white',
  -textvariable => \$dictionary_file,
  -disabledbackground => '#eeeeee',
  -width => 50,
  -rules => {
        'send'  => 'notEmpty',
  },
  -message => 'You must choose a dictionary file.',
  -state => 'disabled'
)->pack( -side =>'left', @padding);

my $dictionary_label = $dictionary_frame->Label(
  -text => 'Dictionary file:'
)->pack( -side =>'left', -before => $dictionary_entry, @padding);

my $dictionary_button = $dictionary_frame->Button(
  -text => 'Select a file',
  -command => sub {my $filename = $mw->getOpenFile;
                  $dictionary_file = $filename;
                  },
                  -state => 'disabled'
  )->pack(  -side => 'left', -after => $dictionary_entry, @padding);

my $dictinonary_check = $dictionary_frame->Checkbutton(
  -text => 'Use a dictionary',
  -command => sub { my $state =  $dictionary_entry->cget(-state);

                  if ($state eq 'normal') {
                    $dictionary_entry->configure(-state => 'disabled');
                    $dictionary_button->configure(-state => 'disabled');
                    $dictionary_file = undef;
                  } else {
                    $dictionary_entry->configure(-state => 'normal');
                    $dictionary_button->configure(-state => 'active');
                   }
				}, # enabling/disabling input line containing dictionary file name
)->pack( -side =>'left', -before => $dictionary_label,  @padding);

# selecting a file with stopword list
my $stopwords_file = '';
my $sw_frame = $lr_frame->Frame->pack;
my $stopwords_entry = $sw_frame->VEntry(
  -background => 'white',
  -textvariable => \$stopwords_file,
  -disabledbackground => '#eeeeee',
  -width => 50,
  -rules => {
        'send'  => 'notEmpty',
  },
  -message => 'You must choose a file with a list of stopwords.',
  -state => 'disabled'
)->pack(-side => 'left', @padding);

my $stopwords_label = $sw_frame->Label(
  -text => 'File with stopwords:'
)->pack(-side => 'left', -before => $stopwords_entry, @padding);

my $stopwords_button = $sw_frame->Button(
  -text => 'Select a file',
  -command => sub {my $filename = $mw->getOpenFile;
                  $stopwords_file = $filename;
                  },
                  -state => 'disabled'
  )->pack( -side =>'left', -after => $stopwords_entry, @padding);

my $stopwords_check = $sw_frame->Checkbutton(
  -text => 'Use a stopword list',
  -command => sub { my $state =  $stopwords_entry->cget(-state);

                  if ($state eq 'normal') {
                    $stopwords_entry->configure(-state => 'disabled');
                    $stopwords_button->configure(-state => 'disabled');
                    $stopwords_file = undef;
                  } else {
                    $stopwords_entry->configure(-state => 'normal');
                    $stopwords_button->configure(-state => 'active');

                   }
                   }, # enabling/disabling input line containing the name of a file with stopwords
)->pack(-before => $stopwords_label, -side =>'left', @padding);


# selecting a file with allowed symbols
my $allowed_symbols_file = '';
my $allowed_symbols_frame = $lr_frame->Frame->pack;
my $allowed_symbols_entry = $allowed_symbols_frame->VEntry(
  -background => 'white',
  -textvariable => \$allowed_symbols_file,
  -disabledbackground => '#eeeeee',
  -width => 50,
  -rules => {
        'send'  => 'notEmpty',
  },
  -message => 'You must choose a file with allowed symbols.',
  -state => 'disabled'
)->pack(-side => 'left', @padding);

my $allowed_symbols_label = $allowed_symbols_frame->Label(
  -text => 'File with allowed symbols:'
)->pack(-side => 'left', -before => $allowed_symbols_entry, @padding);

my $allowed_symbols_button = $allowed_symbols_frame->Button(
  -text => 'Select a file',
  -command => sub {my $filename = $mw->getOpenFile;
                  $allowed_symbols_file = $filename;
                  },
                  -state => 'disabled'
  )->pack( -side =>'left', -after => $allowed_symbols_entry, @padding);

my $allowed_symbols_check = $allowed_symbols_frame->Checkbutton(
  -text => 'Use a list of allowed symbols',
  -command => sub { my $state =  $allowed_symbols_entry->cget(-state);

                  if ($state eq 'normal') {
                    $allowed_symbols_entry->configure(-state => 'disabled');
                    $allowed_symbols_button->configure(-state => 'disabled');
                    $allowed_symbols_file = undef;
                  } else {
                    $allowed_symbols_entry->configure(-state => 'normal');
                    $allowed_symbols_button->configure(-state => 'active');

                   }
                   }, # enabling/disabling input line containing the name of a file with allowed symbols
)->pack(-before => $allowed_symbols_label, -side =>'left', @padding);

# selecting a file with replacement rules
my $replacement_rules_file = '';
my $replacement_rules_frame = $lr_frame->Frame->pack;
my $replacement_rules_entry = $replacement_rules_frame->VEntry(
  -background => 'white',
  -textvariable => \$replacement_rules_file,
  -disabledbackground => '#eeeeee',
  -width => 50,
  -rules => {
        'send'  => 'notEmpty',
  },
  -message => 'You must choose a file with replacement rules.',
  -state => 'disabled'
)->pack(-side => 'left', @padding);

my $replacement_rules_label = $replacement_rules_frame->Label(
  -text => 'File with replacement rules:'
)->pack(-side => 'left', -before => $replacement_rules_entry, @padding);

my $replacement_rules_button = $replacement_rules_frame->Button(
  -text => 'Select a file',
  -command => sub {my $filename = $mw->getOpenFile;
                  $replacement_rules_file = $filename;
                  },
                  -state => 'disabled'
  )->pack( -side =>'left', -after => $replacement_rules_entry, @padding);

my $replacement_rules_check = $replacement_rules_frame->Checkbutton(
  -text => 'Use a list of replacement rules',
  -command => sub { my $state =  $replacement_rules_entry->cget(-state);

                  if ($state eq 'normal') {
                    $replacement_rules_entry->configure(-state => 'disabled');
                    $replacement_rules_button->configure(-state => 'disabled');
                    $replacement_rules_file = undef;
                  } else {
                    $replacement_rules_entry->configure(-state => 'normal');
                    $replacement_rules_button->configure(-state => 'active');

                   }
                   }, # enabling/disabling input line containing the name of a file with replacement rules
)->pack(-before => $replacement_rules_label, -side =>'left', @padding);


# selecting language for stemming
my $stemming = 'none';
my $stemming_frame = $lr_frame->Frame->pack;

my $stemming_opt = $stemming_frame->BrowseEntry(
    -background => 'white',
    -choices => ['none',
		'Danish' ,
		'Dutch' ,
		'English' ,
		'Finnish' ,
		'French' ,
		'German' ,
		'Hungarian' ,
		'Italian' ,
		'Norwegian' ,
		'Portuguese' ,
		'Romanian' ,
		'Russian' ,
		'Spanish' ,
		'Swedish' ,
		'Turkish',
		],
    -state => 'readonly',
    -variable => \$stemming,
    -width => 6,
    -disabledbackground => 'white',
    -disabledforeground => 'black',
)->pack(-side => 'left');
$stemming_opt->Subwidget("slistbox")->configure(-height=>8);

my $stemming_label = $stemming_frame->Label(
  -text => 'Stemming:'
)->pack(-side => 'left', -before => $stemming_opt, @padding);


# program parameters
my $less_memory;

#my $program_parameters_frame = $mw->Frame(-label => 'Program parameters', -relief => 'groove', -border => 2, @padding)->pack;

=pod
my $less_memory_check = $program_parameters_frame->Checkbutton(
    -text => 'Use less memory',
    -variable => \$less_memory,
)->pack;
=cut

my $button_f = $mw->Frame->pack;
$button_f->Button(-text => 'Generate output', -command => \&generate_output, -underline => 1)->pack(-side =>'left', @padding);
$button_f->Button(-text => 'Preprocess data', -command => \&preprocess_data, -underline => 0)->pack(-side =>'left', @padding);
$button_f->Button(-text => 'Command line parameters', -command => \&command_line, -underline => 0)->pack(-side =>'left', @padding);
$button_f->Button(-text => 'Exit', -command => sub {exit}, -underline => 1)->pack(-side =>'left', @padding);



center_window($mw);
MainLoop;

sub preprocess_data { generate_output(1); }
sub command_line { generate_output(2); }

sub generate_output {
	my $param = shift;

	my $ok = 1;

	my $_output_dir = $output_dir;
	my $_output_file = $output_file;

	if ($output_dir_option eq 'current') {
		$_output_dir = '.';
	}
	# setting the output file name when 'same as input file' is chosen
	if ($output_file_option eq 'same as input file') {
		unless ($read_directory) {
			$input_file =~ /[^\\\/]+$/;
			$& =~ /\.[^.]*$|$/;		# selecting the file name without extension
			$_output_file = $`;
		} else {
			$read_directory =~ /[^\\\/]+\/?$/;
			$& =~ /[^\/]+/;
			$_output_file = $&;
		}
	}

	unless ($input_file or $read_directory) {
		warning('Error','Missing input file name or input directory name');
		return;
	}
	$ok &&= check_file($input_file, "input file") if $input_file;

	unless ($_output_file ) {
		warning('Error','Missing output file name');
		return;
	}
	$ok &&= check_existing_file($_output_file, "Output file");

	$n_grams = undef if $n_grams eq '-';

	if ($ok) {

    use VecText;

    # TODO working with dictionary
    # checking or creating output directory

	my @parameters = ();

	if ($param == 1) {
		push @parameters, (-preprocess_data => 1);
	}

	# retrieving the list of desired n-gram sizes from the listbox
	my @n_grams = $n_grams_opt2->curselection;
	map $_++, @n_grams; # the indices start with 0, but the first element represents 1-grams
	#@n_grams = (1) unless @n_grams;	# generate 1-grams when not specified


	if ($param == 2) {
		my $cmd = '';
		$cmd .= qq!--input_file="$input_file" ! if $input_file;
		$cmd .= qq!--read_directory="$read_directory" ! if $read_directory;
		$cmd .= qq!--encoding="$encoding" ! if $encoding;
		$cmd .= qq!--subset_size=$subset_size ! if $subset_size;
		$cmd .= qq!--skip_tokens=$skip_tokens ! if $skip_tokens;
		$cmd .= qq!--randomize ! if $randomize;
		$cmd .= qq!--class_position=$class_position ! if $class_position;
		$cmd .= qq!--processed_classes="$processed_classes" ! if $processed_classes;
		$cmd .= qq!--output_dir="$_output_dir" ! if $_output_dir;
		$cmd .= qq!--output_file="$_output_file" ! if $_output_file;
		$cmd .= qq!--local_weights="$local_weights" ! if $local_weights;
		$cmd .= qq!--global_weights="$global_weights" ! if $global_weights;
		$cmd .= qq!--min_word_length=$min_w_length ! if $min_w_length;
		$cmd .= qq!--max_word_length=$max_w_length ! if $max_w_length;
		$cmd .= qq!--min_global_frequency=$min_global_freq ! if $min_global_freq;
		$cmd .= qq!--max_global_frequency=$max_global_freq ! if $max_global_freq;
		$cmd .= qq!--min_local_frequency=$min_local_freq ! if $min_local_freq;
		$cmd .= qq!--max_local_frequency=$max_local_freq ! if $max_local_freq;
        $cmd .= qq!--min_document_frequency=$min_document_freq ! if $min_document_freq;
        $cmd .= qq!--max_document_frequency=$max_document_freq ! if $max_document_freq;
		$cmd .= qq!--min_rel_document_frequency=$min_rel_document_freq ! if $min_rel_document_freq;
        $cmd .= qq!--max_rel_document_frequency=$max_rel_document_freq ! if $max_rel_document_freq;
		$cmd .= qq!--df_percentage=$df_percentage ! if $df_percentage;
		$cmd .= qq!--terms_to_keep=$terms_to_keep ! if $terms_to_keep;
		$cmd .= qq!--normalization="$normalization" ! if $normalization;
        $cmd .= qq!--output_format="$output_format" ! if $output_format;
        #-max_records_in_output_file ! if  $output_lines;
        $cmd .= qq!--less_memory ! if $less_memory;
		$cmd .= qq!--create_dictionary="$create_dictionary" ! if $create_dictionary;
        $cmd .= qq!--print_statistics ! if $print_statistics;
        $cmd .= qq!--dictionary_file="$dictionary_file" ! if $dictionary_file;
		$cmd .= qq!--stopwords_file="$stopwords_file" ! if $stopwords_file;
		$cmd .= qq!--allowed_symbols_file="$allowed_symbols_file" ! if $allowed_symbols_file;
		$cmd .= qq!--replacement_rules_file="$replacement_rules_file" ! if $replacement_rules_file;
		$cmd .= qq!--logarithm_type="$logarithm_type" ! if $logarithm_type;
		$cmd .= qq!--tag="$tags" ! if $tags;
		$cmd .= qq!--split_into_elements=$split_into_elements ! if $split_into_elements;
		$cmd .= qq!--sentences="$sentences" ! if $sentences;
		$cmd .= qq!--print_original_texts ! if $print_original_texts;
		$cmd .= qq!--print_tokens ! if $print_tokens;
		$cmd .= qq!--print_skipped_tokens ! if $print_skipped_tokens;
		$cmd .= qq!--preserve_numbers ! if $preserve_numbers;
		$cmd .= qq!--remove_URIs ! if $remove_URIs;
		$cmd .= qq!--case="$case" ! if $case;
		$cmd .= qq!--preserve_emoticons ! if $preserve_emoticons;
		$cmd .= qq!--output_decimal_places=$output_decimal_places ! if $output_decimal_places;
		$cmd .= qq!--sort_attributes="$sort_atr" ! if $sort_atr;
		$cmd .= qq!--n_grams=!.join(',',@n_grams).' ' if @n_grams;	# TODO: modify for @n_grams
		$cmd .= qq!--stemming=$stemming ! if $stemming and $stemming ne 'none';

		if ($preserve_symbols) { $preserve_symbols =~ s/"/\\"/g; $cmd .= qq!--preserve_symbols="$preserve_symbols"!; }

		my $cmd_w = $mw->DialogBox(
		   -title=>"Command line parameters",
		   -buttons=>["OK"]
		   );
		$cmd_w->resizable(0,0);
		my $cmd_text = $cmd_w->Text(-width=>60, -height=>10)->pack();
		#my $srl_y = $cmd_text->Scrollbar(-orient=>'v',-command=>[yview => $cmd_text]);
		#$cmd_text->configure(-yscrollcommand=>['set', $srl_y]);
		$cmd_text->Insert($cmd);
		$cmd_w->Show();
		return;
	}

	my @messages = VecText::configure(
		-input_file => $input_file,
		-read_directory => $read_directory,
		-encoding => $encoding,
		-subset_size => $subset_size,
		-randomize => $randomize,
		-processed_classes => $processed_classes,
		-class_position => $class_position,
		-skip_tokens => $skip_tokens,
		-output_dir => $_output_dir,
		-output_file => $_output_file,
		-local_weights => $local_weights,
		-global_weights => $global_weights,
		-min_word_length => $min_w_length,
		-max_word_length => $max_w_length,
		-min_global_frequency => $min_global_freq,
		-max_global_frequency => $max_global_freq,
		-min_local_frequency => $min_local_freq,
		-max_local_frequency => $max_local_freq,
        -min_document_frequency => $min_document_freq,
        -max_document_frequency => $max_document_freq,
        -min_rel_document_frequency => $min_rel_document_freq,
        -max_rel_document_frequency => $max_rel_document_freq,
		-df_percentage => $df_percentage,
		-terms_to_keep => $terms_to_keep,
        -normalization => $normalization,
        -output_format => $output_format,
        #-max_records_in_output_file => $output_lines,
        -less_memory => $less_memory,
		-create_dictionary => $create_dictionary,
        -print_statistics => $print_statistics,
        -dictionary_file => $dictionary_file,
		-stopwords_file => $stopwords_file,
		-allowed_symbols_file => $allowed_symbols_file,
		-replacement_rules_file => $replacement_rules_file,
		-logarithm_type => $logarithm_type,
		-tags => $tags,
		-split_into_elements => $split_into_elements,
		-sentences => $sentences,
		-print_original_texts => $print_original_texts,
		-print_tokens => $print_tokens,
		-print_skipped_tokens => $print_skipped_tokens,
		-preserve_numbers => $preserve_numbers,
		-remove_URIs => $remove_URIs,
		-case => $case,
		-preserve_symbols => $preserve_symbols,
		-preserve_emoticons => $preserve_emoticons,
		-output_decimal_places => $output_decimal_places,
		-sort_attributes => $sort_atr,
		-n_grams => join (',', @n_grams),
		-stemming => $stemming,
		@parameters
		);

    if (@messages) {

        my $answer_dialog = $mw->DialogBox(-title => 'Missing or incorrect parameters',
                        -default_button => 'Yes',
                        -buttons => [ 'Yes', 'No'],);
        $answer_dialog->add("Label", -text => "The following problems appeared:\n")->pack(-anchor => 'w');
        $answer_dialog->add("Label", -text => "- $_\n")->pack(-anchor => 'w') for @messages;
        $answer_dialog->add("Label", -text => "\n\nDo you want to continue?")->pack;

		return if $answer_dialog->Show() eq 'No';


    }


	# creating a window with a progress bar
	my $percent_done = 0;

	my $progress_w = $mw->Toplevel(-title => 'Processing');
	$progress_w->minsize(400,100);
	$progress_w->resizable(0, 0);

		my $pw_label = $progress_w->Label(-text => "Initialization")->pack;			# information about the step

	my $pw_progress_bar = $progress_w->ProgressBar(
					-width => 20,
					-length => 350,
					-variable => \$percent_done,
					-blocks => 1,
					-colors => [0, 'blue']
                  )->pack(-padx => 20, -pady => 20);

	my $pw_info = $progress_w->Label(-text => "")->pack;						# information about some results

	my $pw_stop = 0;
	$progress_w->Button(-text=>"Stop",
					-command => sub { $pw_stop = 1;}
		)->pack(-padx => 20, -pady => 20);

	center_window($progress_w);
	$progress_w->grab;

	# TODO: enable stopping the process, deleting all files etc.
    VecText::process_data_file(-pw_label => $pw_label, -pw_info=> $pw_info, -pw_progress_bar => $pw_progress_bar, -pw => $progress_w, -pw_stop => \$pw_stop);
	$progress_w->destroy;
	}
}


sub create_dictionary {
  my $ok = 1;
  unless ($input_file) {
    warning('Error','Missing input file name');
    return;
  }
  $ok &&= check_file($input_file, "input file");
  unless ($output_file) {
    warning('Error','Missing output file name');
    return;
  }
  $ok &&= check_existing_file($output_file, "Output file");
}

sub check_file {
	my ($file, $file_type) = @_;

	my $exists;
	my $error;

	if ($^O =~ /MSWin/) {

		$file =~ s/\//\\/g;

		$exists = testL('f', "$file");

		eval {
			openL \*F, "<", "$file" or die "$!\n";
		};
		$error = $@;

	} else {
		$exists = -f "$file";
		eval {
			open F, "<", "$file" or die "$!\n";
		};
		$error = $@;
	}

	if (not $exists or $error) {
		my $dialog = $mw->DialogBox( -title => "Error",
                                -buttons => [ "OK" ] );
		$dialog->add("Label", -text => "Error while opening $file_type $file: \n$error")->pack;
		$dialog->Show;
		return undef;
	} else {
		close F;
		return 1;
	}
}

sub check_existing_file {
  my ($file, $file_type) = @_;

  eval {
    open F, "$file" or die "$!\n";
  };
  my $error = $@;
  unless ($@) {
    my $dialog = $mw->DialogBox( -title => "Warning",
                                -buttons => [ "No", "Yes" ] );
    $dialog->add("Label", -text => "$file_type $file already exists.\nOverwrite?")->pack;
    my $button = $dialog->Show;
    return 1 if $button eq 'Yes';
    return undef;
  } else {
    return 1;
  }
}

sub warning {
  my ($title, $text) = @_;
  my $dialog = $mw->DialogBox( -title => $title,
                                -buttons => [ "OK" ] );
    $dialog->add("Label", -text => $text)->pack;
    $dialog->Show;
}


 sub showhelp {
        my @helparray = ([{-title  => "VecText",
                           -header => "VecText",
                           -text   => "VecText is an application that converts raw text to a structured format suitable for various data mining software (e.g., Weka, C5, CLUTO). The application is written in the interpreted programming language Perl which runs on more than 100 platforms. A part of the functionality is realized by external modules (e.g., Lingua::Stem::Snowball for stemming) freely available at the Comprehensive Perl Archive Network (CPAN)(www.cpan.org). The graphical user interface is  implemented in Perl/Tk, a widely used graphical interface for Perl. This extension can be also obtained from the CPAN archive.
\n
Graphical user interface enables user friendly software employment without requiring specialized technical skills and knowledge of a particular programming language, names of libraries and their functions, etc. All preprocessing actions are specified using common graphical elements organized into logically related blocks.
\n
In the command line interface mode all preprocessing options must be specified using command line parameters. This way of non-interactive communication enables incorporating the application into a more complicated data mining process integrating several software packages or performing multiple conversions in a batch.
\n
To help the users define all necessary and desired parameters for the command line mode the application with the graphical interface enables generating the string with command line parameters based on the current values of all form elements in the application window. These parameter settings are returned in the form of a text string and might be simply copied to, e.g., a batch file or script.
"}]

                         );

        #my $helpicon = $mw->Photo(-file => "./help.gif");


        my $help = $mw->Help(
                               -title    => "My Application - Help",
                               -variable => \@helparray);

}

sub About {
    my $about = $mw->DialogBox(
		   -title=>"About",
		   -buttons=>["OK"]
		   );

    $about->add('Label',
		-anchor => 'w',
		-justify => 'left',
		-text => "VecText\n(Vectorization of Text)\nVersion: 1.0\n\nAuthor: Frantisek Darena\nfrantisek.darena\@gmail.com
        "
		)->pack;

    $about->Show();
}

sub center_window {
  my $win = shift;

  $win->withdraw;   # Hide the window while we move it about
  $win->update;     # Make sure width and height are current

  # Center window
  my $xpos = int(($win->screenwidth  - $win->width ) / 2);
  my $ypos = int(($win->screenheight - $win->height) / 2);
  $win->geometry("+$xpos+$ypos");

  $win->deiconify;  # Show the window again
}


