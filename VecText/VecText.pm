=todo

PREPROCESSING
- check allowed attribute names when, e.g., numbers or emoticons are preserved (e.g., in Weka, an attribute name must start with an alphabetic character)
- include some lists of stopwords

OUTPUT
- Probabilistic IDF - for words with DF = N (number of documents) set GW to -INF
- optional creation of files, such as *.rlabel for CLUTO
- rename TOKENS to TERMS
- optional warnings regarding parameter values for the command line version
- adding skipped tokens to the output when desired

INPUT
- removing \r, \x{FEFF}  etc.
- enable creating N subsets from the input
- removing e-mails, hashtags, ...
- processing JSON files
- keeping some parts of the input (e.g., headers) unchanged
- balancing the classes
- filtering too short or too long documents

OPTIMIZATION
- change string comparisons to number comparisons, e.g., $local_weights eq 'TERM FREQUENCY' to numbers, e.g., $local_weights == 1, or  $local_weights == TERM_FREQUENCY, where TERM_FREQUENCY is a constant function?
- global variables -> lexical variables when possible?
- enable saving the memory: text data will not be stored; the input file will be processed twice
		- dictionary and global weights will be calculated in the first step,
		- output will be generated in the following step row by row

=cut
BEGIN {unshift @INC, '.'};

package VecText;


our $VERSION = 1.0;

use Exporter;
our @ISA = ('Exporter');
# TODO - export
our @EXPORT = 'process_data_file';

use strict;

if ($^O =~ /MSWin/) {
	require Win32::LongPath;
}


our $_DEBUG = 1;

my $min_word_length = undef;
my $max_word_length = undef;
my $min_global_frequency = undef;
my $max_global_frequency = undef;
my $min_local_frequency = undef;
my $max_local_frequency = undef;
my $min_document_frequency = undef;
my $max_document_frequency = undef;
my $min_rel_document_frequency = undef;
my $max_rel_document_frequency = undef;
my $df_percentage = undef;
my $terms_to_keep = undef;
my $normalization = undef;
my $output_format = undef;
my $local_weights = undef;
my $global_weights = undef;
my $dictionary_file = undef;
my $preprocess_data = undef;
my $stopwords_file = undef;
my $allowed_symbols_file = undef;
my $replacement_rules_file = undef;
my $input_file = undef;
my $read_directory = undef;
my $randomize = undef;
my $encoding = '';
my $output_file = undef;
my $output_dir = undef;
my $max_records_in_output_file = undef;
my $subset_size = undef;
my $natural_logarithm = undef;
my $write_dictionary = undef;
my $write_dictionary_freq = undef;
my $write_dictionary_freq_classes = undef;
my $write_dictionary_df = undef;
my $write_dictionary_df_classes = undef;
my $print_statistics = undef;
my $real_k_value = undef;
my @tags = ();
my $sentences  = undef;
my @processed_classes = ();
my $split_into_elements = undef;
my @allowed_symbols = ();
my @replacement_rules_L = (); my @replacement_rules_R = ();
my @numbers = ();
my @emoticons = ();
my @symbols = ();
my %global_weights = ();
my $sort_attributes = undef;
my $n_grams = 1;
my $skip_tokens = undef;
my $class_position = undef;

my $output_decimal_places = 0;
my $print_original_texts = 0;
my $print_tokens = 0;
my $print_skipped_tokens = 0;
my $create_dictionary = 0;

my $remove_URIs = undef;
my $remove_multiple_characters = 0;
my $case = 2;
my $preserve_numbers = 0;
my $preserve_emoticons = 0;
my $emoticons_file = undef;
my $preserve_symbols = undef;

my %dictionary = ();
my %dictionary_classes = ();
my %document_frequency = ();
my %document_frequency_classes = ();

my @classes = ();
my %stopwords = ();
my %emoticons = ();

my $allowed_symbols_re = '';
my $emoticons_re = '';
my $symbols_re = '';
my $numbers_re = qr$
   [+-]?          # optional sign
   (?:
     (?:
       \d*        # some digits, optionally before the decimal point
       [.,]\d+    # decimal point or comma and some (more than zero) decimal places
     )
	 |            # or
     (?:
       \d+        # just digits
	 )
   )
   (?:            # optionally followed by the semilogarithmic notation
    [eE][+-]?\d+  # letter e or E, optional sign, and at least one digit
   )?
$x;

my $stemming = undef;
my %lang_codes = (
	'DANISH'	=>	'da',
	'DUTCH'		=>	'nl',
	'ENGLISH'	=>	'en',
	'FINNISH'	=>	'fi',
	'FRENCH'	=>	'fr',
	'GERMAN'	=>	'de',
	'HUNGARIAN'	=>	'hu',
	'ITALIAN'	=>	'it',
	'NORWEGIAN'	=>	'no',
	'PORTUGUESE'=>	'pt',
	'ROMANIAN'	=>	'ro',
	'RUSSIAN'	=>	'ru',
	'SPANISH'	=>	'es',
	'SWEDISH'	=>	'sv',
	'TURKISH'	=>	'tr ',

);

# for graphical interface - showing the progress
my $pw_label;
my $pw_progress_bar;
my $pw_info;
my $pw;
my $pw_stop;

sub configure {
    my %params = @_;

    my @message = ();

    if (defined $params{-min_word_length} and $params{-min_word_length} =~ /^[1-9]\d*$/) {
        # minimal word length is entered and it is a positive integer
        $min_word_length = $params{-min_word_length};
    } else {
        $min_word_length = 0;

        push @message, 'Minimal word length - incorrect or missing value. Set to 0.'
    }

    if (defined $params{-max_word_length} and $params{-max_word_length} =~ /^[1-9]\d*$/) {
        # maximal word length is entered and it is a positive integer
        $max_word_length = $params{-max_word_length};
    } else {
        $max_word_length = 0;

        push @message, 'Maximal word length - incorrect or missing value. Set to INF.'
    }

    if (defined $params{-min_global_frequency} and $params{-min_global_frequency} =~ /^[1-9]\d*$/) {
        # minimal global frequency is entered and it is a positive integer
        $min_global_frequency = $params{-min_global_frequency};
    } else {
        $min_global_frequency = 0;

        push @message, 'Minimal global word frequency - incorrect or missing value. Set to 0.'
    }

    if (defined $params{-max_global_frequency} and $params{-max_global_frequency} =~ /^[1-9]\d*$/) {
        # maximal global frequency is entered and it is a positive integer
        $max_global_frequency = $params{-max_global_frequency};
    } else {
        $max_global_frequency = 0;

        push @message, 'Maximal global word frequency - incorrect or missing value. Set to INF.'
    }

    if (defined $params{-min_local_frequency} and $params{-min_local_frequency} =~ /^[1-9]\d*$/) {
        # minimal local frequency is entered and it is a positive integer
        $min_local_frequency = $params{-min_local_frequency};
    } else {
        $min_local_frequency = 0;

        push @message, 'Minimal local word frequency - incorrect or missing value. Set to 0.'
    }

    if (defined $params{-max_local_frequency} and $params{-max_local_frequency} =~ /^[1-9]\d*$/) {
        # maximal local frequency is entered and it is a positive integer
        $max_local_frequency = $params{-max_local_frequency};
    } else {
        $max_local_frequency = 0;

        push @message, 'Maximal local word frequency - incorrect or missing value. Set to INF.'
    }

    if (defined $params{-min_document_frequency} and $params{-min_document_frequency} =~ /^[1-9]\d*$/) {
        # minimal document frequency is entered and it is a positive integer
        $min_document_frequency = $params{-min_document_frequency};
    } else {
        $min_document_frequency = 0;

        push @message, 'Minimal document frequency - incorrect or missing value. Set to 0.'
    }

    if (defined $params{-max_document_frequency} and $params{-max_document_frequency} =~ /^[1-9]\d*$/ and $params{-max_document_frequency} >= $params{-min_document_frequency}) {
		# maximal document frequency is entered and it is a positive integer
		$max_document_frequency = $params{-max_document_frequency};
    } else {
		$max_document_frequency = 0;

		push @message, 'Maximal document frequency - incorrect or missing value. Set to INF.'
    }
   if (defined $params{-min_rel_document_frequency} and $params{-min_rel_document_frequency} =~ /^0?\.\d+|1(\.0+)?$/ and $params{-min_rel_document_frequency} > 0 ) {
        # minimal relative document frequency is entered and it is a real number from (0,1>
        $min_rel_document_frequency = $params{-min_rel_document_frequency};
    } else {
        $min_rel_document_frequency = 0;

        push @message, 'Minimal relative document frequency - incorrect or missing value. Set to 0.'
    }

    if (defined $params{-max_rel_document_frequency} and $params{-max_rel_document_frequency} =~ /^0?\.\d+|1(\.0+)?$/ and $params{-max_rel_document_frequency} > 0
		and $params{-max_rel_document_frequency} >= $params{-min_rel_document_frequency}) {
		# maximal relative document frequency is entered and it is a real number from (0,1>
		$max_rel_document_frequency = $params{-max_rel_document_frequency};
    } else {
		$max_rel_document_frequency = 0;

		push @message, 'Maximal relative document frequency - incorrect or missing value. Set to 1.'
    }

	if (defined $params{-df_percentage} and $params{-df_percentage} =~ /^0?\.\d+|1(\.0+)?$/ and $params{-df_percentage} > 0) {
		# the percentage of most frequent words to keep in the dictionary is entered and it is a real number from (0,1>
		$df_percentage = $params{-df_percentage};
    } else {
		$df_percentage = undef;
		push @message, 'The percentage of most frequent terms to keep in the dictionary - incorrect or missing value. Set to 1.'
    }

	if (defined $params{-terms_to_keep} and $params{-terms_to_keep} =~ /^\d+$/ and $params{-terms_to_keep} > 0) {
		# the number of terms to keep in the dictionary is entered and it is a number
		$terms_to_keep = $params{-terms_to_keep};
    } else {
		$terms_to_keep = undef;
		push @message, 'The number of terms to keep in the dictionary - incorrect or missing value. Set to INF.'
    }


    if (defined $params{-subset_size} and $params{-subset_size} =~ /^[1-9]\d*$/) {
		# subset size is entered and it is a positive integer
		$subset_size = $params{-subset_size};
    } else {
		push @message, 'Subset size - incorrect or missing value. Set to ALL.';
		undef $subset_size;
    }

    if (defined $params{-skip_tokens} and $params{-skip_tokens} =~ /^[1-9]\d*$/) {
		# number of skipped tokens is entered and it is a positive integer
		$skip_tokens = $params{-skip_tokens};
    } else {
		push @message, 'Skip tokens - incorrect or missing value. Set to 0.';
		undef $skip_tokens;
    }

    if (defined $params{-class_position} and $params{-class_position} =~ /^[1-9]\d*$/) {
		# class position is entered and it is a positive integer
		$class_position = $params{-class_position};
    } else {
		push @message, 'Class position - incorrect or missing value. Set to NONE.';
		undef $class_position;
    }


	if (defined $params{-processed_classes} and $params{-processed_classes}) {
		$params{-processed_classes} =~ s/^\s+//; $params{-processed_classes} =~ s/\s+$//;
		@processed_classes = split /[\s,]+/, $params{-processed_classes};	# more possibilities of entering the list of processed classes
	} else {
		@processed_classes = ();
	}

    $normalization = uc $params{-normalization};

    $output_format = uc $params{-output_format};

	#if (defined $params{-n_grams} and $params{-n_grams} ne '-' and $params{-n_grams} =~ /^[1-9]\d*$/) {
	#	# n-gram size is entered
	#	$ngrams = $params{-n_grams};
    #} else {
	#	push @message, 'N-gram size - incorrect or missing value. Set to 1.'
    #}

	if (defined $params{-n_grams} and $params{-n_grams} =~ /^[1-9](?:,\d)*$/) {
		# n-gram size is entered
		$n_grams = $params{-n_grams};
    } else {
		$n_grams = 1;
		push @message, 'N-gram size - incorrect or missing value. Set to 1.'
    }



    #if ($params{-max_records_in_output_file} and $params{-max_records_in_output_file} =~ /^[1-9]\d*$/ ) {
	#	$max_records_in_output_file = $params{-max_records_in_output_file};
	#} else {
    #    push @message, 'Maximal number of records in output file - incorrect or missing value. Set to INF.'
    #}

    $local_weights = uc $params{-local_weights};
    $global_weights = uc $params{-global_weights};

	$create_dictionary = uc $params{-create_dictionary} || undef;

	$write_dictionary = $create_dictionary eq 'PLAIN';
	$write_dictionary_freq = $create_dictionary eq 'WITH FREQUENCIES';
	$write_dictionary_freq_classes =  $create_dictionary eq 'WITH FREQUENCIES FOR CLASSES';
	$write_dictionary_df = $create_dictionary eq 'WITH DOCUMENT FREQUENCIES';
	$write_dictionary_df_classes =  $create_dictionary eq 'WITH DOCUMENT FREQUENCIES FOR CLASSES';

	$preprocess_data = $params{-preprocess_data} || 0;

	$randomize = $params{-randomize} || 0;

	$remove_multiple_characters = $params{-remove_multiple_characters} || 0;

	$remove_URIs = $params{-remove_URIs} || undef;

	# upper case by default
	$case = 0 if uc $params{-case} eq 'NO';
	$case = 1 if uc $params{-case} eq 'LOWER CASE';
	$case = 2 if uc $params{-case} eq 'UPPER CASE';

	$preserve_numbers = $params{-preserve_numbers} || 0;
	$preserve_emoticons = $params{-preserve_emoticons} || 0;
	if ($params{-preserve_symbols }) {
		$symbols_re = "[" . quotemeta($params{-preserve_symbols})."]";
		$preserve_symbols = $params{-preserve_symbols};
	} else {
		$preserve_symbols = undef;
	}

	$sort_attributes = uc $params{-sort_attributes} || 'NONE';

	if (defined $params{-output_decimal_places} and $params{-output_decimal_places} >= 0 and $params{-output_decimal_places} < 11) {
		$output_decimal_places = $params{-output_decimal_places};
	} else {
		$output_decimal_places = 3;
		push @message, "Number of decimal places for the output vectors ommited or too big. Set to 3.";
	}

    if ($params{-dictionary_file}) {
		$dictionary_file = $params{-dictionary_file};
	} else {
		undef $dictionary_file;
	}

	if ($params{-stopwords_file}) {
		$stopwords_file = $params{-stopwords_file};
	} else {
		undef $stopwords_file;
		%stopwords = ();
	}

	if ($params{-allowed_symbols_file}) {
		$allowed_symbols_file = $params{-allowed_symbols_file};
	} else {
		undef $allowed_symbols_file;
	}

	if ($params{-replacement_rules_file}) {
		$replacement_rules_file = $params{-replacement_rules_file};
	} else {
		undef $replacement_rules_file;
	}

    $input_file = $params{-input_file};
    $output_file = $params{-output_file};

	if ($params{-read_directory}) {
		$read_directory = $params{-read_directory};
		if ($^O =~ /MSWin/) {
			unless (Win32::LongPath::testL('d', $read_directory)) {
				$read_directory = '.';
				push @message, "Input directory doesn't exist. Set to currect directory.";
			}
		} else {
			unless (-d $read_directory) {
				$read_directory = '.';
				push @message, "Input directory doesn't exist. Set to currect directory.";
			}
		}
    }

    if ($params{-output_dir}) {
		$output_dir = $params{-output_dir};
		if ($^O =~ /MSWin/) {
			unless (Win32::LongPath::testL('d', $output_dir)) {
				$output_dir = '.';
				push @message, "Output directory doesn't exist. Set to currect directory.";
			}
		} else {
			unless (-d $output_dir) {
				$output_dir = '.';
				push @message, "Output directory doesn't exist. Set to currect directory.";
			}
		}
    } else {
        $output_dir = '.';
        push @message, 'Output directory name omitted. Set to currect directory.';
    }

	$stemming = uc $params{-stemming} || undef;
	undef $stemming if $stemming eq 'NONE';
	if ($stemming) {
		require Lingua::Stem::Snowball;
	}

    $print_statistics = $params{-print_statistics} || undef;
	$print_skipped_tokens = $params{-print_skipped_tokens} || undef;

    if ($local_weights eq 'AUGMENTED NORMALIZED TF'
		or $local_weights eq 'AUGMENTED AVERAGE TF'
		or $local_weights eq 'AUGMENTED LOG'
		or $local_weights eq 'CHANGED-COEFFICIENT AVERAGE TF') {
        if (defined $params{-real_k_value} and $params{-real_k_value} =~ /^\d+(?:\.\d+)?$/) {
            $real_k_value = $params{-real_k_value};
        } else {
            $real_k_value = 0.5;
            push @message, 'K -- incorrect or missing value. Set to 0.5.';
        }
    }


	if (uc $params{-logarithm_type} eq 'COMMON') {
		$natural_logarithm = 0;
	} else {
		$natural_logarithm = 1;
	}

	if ($params{-tags}) {
		$params{-tags} =~ s/^\s+//; $params{-tags} =~ s/\s+$//;
		@tags = map {uc} split /[\s,]+/, $params{-tags};	# more possibilities of entering the list of processed tags
	} else {
		@tags = ();
	}

	if ($params{-encoding}) {
		# TODO: check correctness of the supplied encoding name
		$encoding = ":encoding($params{-encoding})";
	}

	$split_into_elements = $params{-split_into_elements} || undef;

	$sentences = $params{-sentences} || undef;
	$print_original_texts = $params{-print_original_texts} || undef;
	$print_tokens = $params{-print_tokens} || undef;

	# decimal places are not needed when the output contains only integer values
	$output_decimal_places = 0 if  ($local_weights eq 'BINARY (TERM PRESENCE)' or
								 $local_weights eq 'TERM FREQUENCY (TF)' or
								 $local_weights eq 'SQUARED TF' or
								 $local_weights eq 'THRESHOLDED TF')
								and
								($global_weights eq 'NONE' or not $global_weights)
								and
								($normalization eq 'NONE' or not $normalization);
    return @message;

    # TODO: checking mandatory parameters and the correctness of the parameters


}

sub process_data_file {
	# processes a file with texts and produces their vector representations according to the parameters

	my %params = @_;

	my @files_to_delete = ();	# the list of files to be deleted when the process is stopped

	$pw_label = $params{-pw_label};
	$pw_progress_bar = $params{-pw_progress_bar};
	$pw_info = $params{-pw_info};
	$pw = $params{-pw};
	$pw_stop = $params{-pw_stop};


	if ($print_tokens) {
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*TOKENS, ">$encoding", "$output_dir/$output_file.tokens.txt") or die $!;
		} else {
			open TOKENS, ">$encoding", "$output_dir/$output_file.tokens.txt" or die $!;
		}
	}
	if ($print_original_texts) {
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*ORIG, ">$encoding", "$output_dir/$output_file.original.txt") or die $!;
		} else {
			open ORIG, ">$encoding", "$output_dir/$output_file.original.txt" or die $!;
		}
	}

	# if the content of a directory should be read
	if ($read_directory) {
		local $/ = undef;
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*TMP_INPUT, ">", "$output_dir/data.input.txt");
		} else {
			open TMP_INPUT, ">", "$output_dir/data.input.txt";
		}
		for my $name (glob "$read_directory/*") {
			if (-d $name) {
				# it is a directory
				$name =~ /([^\\\/]+)$/;
				my $class = $1;
				for my $file (glob "$name/*") {
					if ($^O) {
						next if Win32::LongPath::testL ('d', $file);	# process only files
						Win32::LongPath::openL(\*F, "<", $file);
					} else {
						next if -d $file;		# process only files
						open F, "<", $file;
					}
					my $data = <F>;
					close F;
					$data =~ s/\s+/ /g;
					print TMP_INPUT "$class\t$data\n";
				}
			}
		}
		close TMP_INPUT;
		$input_file = "data.input.txt";
		push @files_to_delete, "data.input.txt";
	}

	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*F, "<$encoding", $input_file) or die "$!";
  } else {
		open F, "<$encoding", $input_file or die "$!";
	}

	# counting the lines on the input
	1 for <F>;
	my $number_of_lines = $.;
	close F;

	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*F, "<$encoding", $input_file) or die "$!";
	} else {
		open F, "<$encoding", $input_file or die $!;
	}

	# deleting the content of variables (for multiple using of the function)
	my %classes = ();
	%dictionary = ();
	%dictionary_classes = ();
	@classes = ();
	my @texts = ();
	my @original_texts = ();
	%global_weights = ();
	%document_frequency = ();
	%document_frequency_classes = ();
	my $number_of_documents = undef;
	my @all_skipped_tokens = ();

	if ($replacement_rules_file) {
		# apply replacement rules
		read_replacement_rules();
		$pw_label->configure(-text => 'Reading replacement rules') if defined $pw_label;
	}
	if ($dictionary_file) {
		# use only words from given dictionary
		read_dictionary();
		$pw_label->configure(-text => 'Reading provided dictionary') if defined $pw_label;
	}
	if ($stopwords_file) {
		# remove stopwords
		read_stopwords();
		$pw_label->configure(-text => 'Reading provided stopwords') if defined $pw_label;
	}
	if ($allowed_symbols_file) {
		# keep selected allowed symbols
		read_allowed_symbols();
		$pw_label->configure(-text => 'Reading provided abbseviations') if defined $pw_label;
	}
	if ($preserve_emoticons) {
		# preserve emoticons
		read_emoticons();
		$pw_label->configure(-text => 'Reading emoticons') if defined $pw_label;
	}

	debug("input\n");

	my @processed_lines = ();	# for storing numbers of lines to be processed
	if ($subset_size) {
		# process only desired number of randomly selected lines

		# when subset size is less than number of lines in a file, no selection is needed
		if ($number_of_lines <= $subset_size) {
			undef $subset_size;
		} else {
			# randomly shuffle line numbers
			my @lines = (1..$number_of_lines);
			for (reverse $#lines-$subset_size .. $#lines) {
				my $index = int rand $_+1;		# randomly select index of line number
				my $temp = $lines[$index];
				$lines[$index] = $lines[$_];
				$lines[$_] = $temp;				# swapping the line numbers
			}
			@processed_lines = sort {$a <=> $b} @lines[-$subset_size..-1];		# store the numbers of lines to be processed
		}
	}

	$pw_label->configure(-text => 'Reading the input') if defined $pw_label;

	my $line_number = 0;

	DOCUMENT: while (<F>) {
		# each line contains some text

		# TODO: removing BOM
		s/\x{feff}//;

		if ($subset_size) {
			last DOCUMENT unless @processed_lines;	# all desired lines have been processed

			if ($. == $processed_lines[0]) {
				# process the line
				shift @processed_lines;
			} else {
				# skip lines that were not randomly selected
				next DOCUMENT;
			}
		}
		$line_number++;

		chomp;
		s/^\s+//;

		# extracting first few tokens to be later excluded
		my @_data = split /\s+|[,;]/, $_, ($class_position>$skip_tokens ? $class_position+1 : $skip_tokens+1);

		# extracting a class label
		my $class = $class_position?$_data[$class_position-1]:undef;

		# when a class label was not found
		next if $class_position and not defined $class;

		# skipping a desired number of tokens and a class label, when applicable
		splice @_data, $class_position-1, 1 if $class_position > $skip_tokens;# or not $skip_tokens;

		my @skipped_tokens = @_data[0..$skip_tokens-1] if ($print_original_texts or $print_tokens) and $skip_tokens;

		my $text = join ' ', @_data[$skip_tokens..$#_data];


		# after skipping some tokens no text needs to remain
		next unless $text;

		$text = case($text);

		debug("\r line $.") unless $line_number % 10;

		unless ($number_of_lines <= 100 or $line_number % (int ($number_of_lines/100))) {
			# checking whether Stop button was pressed
			if (defined $pw) {
				# graphical mode
				unless ($$pw_stop) {
					$pw_progress_bar->value($./$number_of_lines*100);
					$pw_progress_bar->update();
				} else {
					# ask
					my $answer_dialog = $pw->DialogBox(-title => 'Processing',
												-default_button => 'No',
												-buttons => [ 'Yes', 'No'],);
					$answer_dialog->add("Label", -text => "Really stop?")->pack();
					if ($answer_dialog->Show() eq 'Yes') {
						$pw->destroy;
						# cleaning memory - TODO

						# stopping the subroutine
						return;
					} else {
						# continue
						$$pw_stop = 0;
					}
				}
			}
		}


		next if $class_position and @processed_classes and not grep {$_ eq $class} @processed_classes;		# TODO: maybe use hash and exists $processed_classes{$class} for higher efficiency

		# pieces of text, e.g., for splitting documents into smaller pieces, e.g., sentences
		my @pieces = ($text);

		if (@tags) {
			# only the contents of selected tags should be processes
			# TODO: enable more complex tags specification, e.g., <div class="data"> instead of just <x>

			my @tags_content = ();
			my $orig_text = $text;

			for my $tag (@tags) {
				push @tags_content, $1 while $orig_text =~ s/<\s*$tag\b[^>]*>(.*?)<\/\s*$tag\s*>/ /;
			}
			if ($split_into_elements) {
				@pieces = @tags_content;
			} else {
				$text = join ' ', @tags_content; 	# replace the processed row with the contents of selected tags
													#(the tags are extracted in the order given by the user)
			}
		}

		if ($sentences) {
			# splitting into sentences
			# TODO: deeper analysis of possible sentence boundaries
			@pieces = grep /\S/, split/[$sentences]/, $text;

		}

		# n-grams - 2-, 3-, ... grams or combinations are needed
		my @n_grams = ();
		if ($n_grams and $n_grams ne '1') {
			@n_grams = split ',',$n_grams;
		}

		my $URI_finder;
		if ($remove_URIs) {
			require URI::Find;
			$URI_finder = URI::Find->new(sub {return ' '});
		}

		for my $text (@pieces) {

			my $orig = $text if $print_original_texts;

			$text =~ s/(.)\1{2,}/$1$1/g if $remove_multiple_characters;

			$URI_finder->find(\$text) if $remove_URIs;

			if (@replacement_rules_L) {
				# application of replacement rules
				for (0..$#replacement_rules_L) {
					$text =~ s/$replacement_rules_L[$_]/$replacement_rules_R[$_]/g;
				}
			}

			# if a list of allowed symbols is provided, these symbols are found in the documents, removed and after
			# other not allowed characters, long or short words are removed, they are added back
			if ($allowed_symbols_re) {
				@allowed_symbols = $text =~ /(?:\s|^)\K($allowed_symbols_re)(?=\s|$)/g;		# finding all allowed symbols, they will be later returned to the text
				$text =~ s/(?:\s|^)\K($allowed_symbols_re)(?=\s|$)/ /g;						# removing all allowed symbols
																							# TODO: wouldn't a loop be more efficient: while ($text =~ s/..../ /) {push @allowed_symbols, $&;}
				#debug("preserved allowed_symbols: @allowed_symbols | $allowed_symbols_re\n");
			}

			if ($preserve_numbers) {
				@numbers = $text =~ /$numbers_re/g;		# finding all numbers, they will be later returned to the text
				$text =~ s/$numbers_re/ /g;				# removing all numbers
														# TODO: wouldn't a loop be more efficient: while ($text =~ s/..../ /) {push @numbers, $&;}
				#debug("preserved numbers: @numbers\n");
			}

			if ($preserve_emoticons) {
				@emoticons = $text =~ /$emoticons_re/g;		# finding all emoticons, they will be later returned to the text
				$text =~ s/$emoticons_re/ /g;				# removing all emoticons
															# TODO: wouldn't a loop be more efficient: while ($text =~ s/..../ /) {push @emoticons, $&;}
				#debug("preserved emoticons: @emoticons\n");
			}


			if ($preserve_symbols) {
				@symbols = $text =~ /$symbols_re/g;		# finding all symbols, they will be later returned to the text
				$text =~ s/$symbols_re/ /g;				# removing all symbols
														# TODO: wouldn't a loop be more efficient: while ($text =~ s/..../ /) {push @symbols, $&;}
				#debug("$text, preserved symbols: @symbols\n");
			}

			remove_tags_and_entities($text);

			remove_characters($text);
			# TODO - efficiency of this vs. remove_long_or_short_words
			#$text =~ s/\b\S{0,$min}\b/ /g;		# removing short words
			#$text =~ s/\b\S{$max,}\b/ /g;		# removing long words

			# removing leading, trailing and multiple spaces
			$text =~ s/^\s+//; $text =~ s/\s+$//; $text =~ s/\s+/ /g;

			my @words = split / /, $text;

			# removing words shorter or longer than given number of characters
			remove_long_or_short_words(\@words, $min_word_length, $max_word_length) if $min_word_length or $max_word_length;

			# removing word with low or high local frequency (within one document)
			remove_locally_frequent_words(\@words, $min_local_frequency, $max_local_frequency) if $min_local_frequency or $max_local_frequency;

# TODO
# specify the structure of a dictionary and modify reading and writing the dictionary

			my %unique_words = (); # for calculating document frequency of words

			if ($dictionary_file) {
				# a dictionary is provided
				# remove words that are not in the dictionary
				@words = grep { exists $dictionary{$_} } @words;
			}

			if ($stopwords_file) {
				# a list of stopwords is provided, remove them
				@words = grep { not exists $stopwords{$_} } @words;
			}

			if ($stemming) {
				# stemming
				@words = Lingua::Stem::Snowball::stem( $lang_codes{$stemming}, \@words);
				$_ = case($_) for @words;
			}

			if ($allowed_symbols_file) {
				push @words, @allowed_symbols;
			}

			if ($preserve_numbers) {
				push @words, @numbers;
			}

			if ($preserve_emoticons) {
				push @words, map $emoticons{$_}, @emoticons;
			}

			if ($preserve_symbols) {
				push @words, @symbols;
			}

			# skipping texts with no (allowed) words
			next unless @words;

			# n-grams or n_grams combinations are needed
			if (@n_grams) {

				my @_words = (); # the list of n_grams

				for my $n (@n_grams) {
					# skip to the following row if there are not enough words for the n_gram available
					next if @words < $n;

					# replacing single words (@words) by list of n-grams
					for my $i (0..$#words-$n+1) {
						push @_words, join '_', @words[$i..$i+$n-1];
					}

				}
				@words = @_words; # replacing the words by the generated n_grams

				# skipping texts with no (allowed) words
				next unless @words;
			}

			# create the dictionary and calculate global word frequencies
			$dictionary{$_}++ for @words;

			# creating the dictionary for individual classes when desired
			if ($write_dictionary_freq_classes or $print_statistics) {
				$dictionary_classes{$class}->{$_}++ for @words;
			}

			# counting unique words for calculating document frequency or for removing words according to their global frequency
			if (($min_document_frequency and $min_document_frequency > 1 or $max_document_frequency or $df_percentage
				or $min_rel_document_frequency or $max_rel_document_frequency or $write_dictionary_df_classes or $write_dictionary_df )
					or
				($global_weights eq 'INVERSE DOCUMENT FREQUENCY (IDF)'
				or $global_weights eq 'SQUARED IDF'
				or $global_weights eq 'PROBABILISTIC IDF'
				or $global_weights eq 'GLOBAL FREQUENCY IDF'
				or $global_weights eq 'INCREMENTED GLOBAL FREQ. IDF'
				or $global_weights eq 'LOG-GLOBAL FREQUENCY IDF'
				or $global_weights eq 'SQUARE ROOT GLOBAL FREQENCY IDF'
				or $sort_attributes eq 'DOCUMENT FREQUENCY (DESCENDING)'
				or $sort_attributes eq 'DOCUMENT FREQUENCY (ASCENDING)')
				) {

				$unique_words{$_} = 1 for @words;

				# increasing the value of document frequency for each word in the document
				for (keys %unique_words) {
					$document_frequency{$_}++;
					$document_frequency_classes{$class}->{$_}++ if $write_dictionary_df_classes;

				}
			}


			# storing the text and the associated class
			push @texts, [@words];
			push @classes, $class;
			push @original_texts, $orig if $print_original_texts;
			push @all_skipped_tokens, join(' ', @skipped_tokens).' ' if ($print_original_texts or $print_tokens) and $skip_tokens and $print_skipped_tokens;

			# storing information about an existing class
			$classes{$class}++;
		}
	}

	debug("\n last line: $line_number\n");
	close F;

	unlink "data.input.txt" if $read_directory and -e "data.input.txt";

	debug("data file is read\n");

=pod
@texts =                    @classes =
(                           (
 [w11, w12, w13, ...],       class1,
 [w21, w22, w32, ...],       class2,
 ...                         ...
)                           )

%dictionary =
(
 word1 => global_frequency_of_word1,
 word2 => global_frequency_of_word2,
 ...
)

%document_frequency =
(
 word1 => document_frequency_of_word1,
 word2 => document_frequency_of_word2,
 ...
)


=cut

	# remove words with low global/document frequency from the dictionary

	if (not $dictionary_file and
		(($min_global_frequency and $min_global_frequency > 1 or $max_global_frequency)
		or
		($min_document_frequency and $min_document_frequency > 1 or $max_document_frequency)
		or
		($min_rel_document_frequency or $max_rel_document_frequency)
		or $df_percentage or $terms_to_keep
		)
		) {
		# deleting words with low or high global/document frequency
		for (keys %dictionary) {
			if ($min_global_frequency) {
				# deleting rare words
				delete $dictionary{$_} if $dictionary{$_} < $min_global_frequency;
			}
			if ($max_global_frequency) {
				# deleting common words
				delete $dictionary{$_} if $dictionary{$_} > $max_global_frequency;
			}
			if ($min_document_frequency) {
				# deleting words with low document frequency
				delete $dictionary{$_} if $document_frequency{$_} < $min_document_frequency;
			}
			if ($max_document_frequency) {
				# deleting words with high document frequency
				delete $dictionary{$_} if $document_frequency{$_} > $max_document_frequency;
			}
		}

		# keeping just the specified percentage of most frequent words
		if ($df_percentage) {
			my @least_frequent_words = (sort {$document_frequency{$b} <=> $document_frequency{$a}} keys %dictionary)[(keys %dictionary)*$df_percentage .. keys %dictionary];

			delete $dictionary{$_} for @least_frequent_words;
		}

		# keeping just the specified number of most frequent words
		if ($terms_to_keep) {
			my @least_frequent_words = (sort {$dictionary{$b} <=> $dictionary{$a}} keys %dictionary)[$terms_to_keep .. keys %dictionary];

			delete $dictionary{$_} for @least_frequent_words;
		}

		# keeping just the words appearing in at least MIN_REL_DF*100 percent of documents and at most in MAX_REL_DF*100 percent of documents
		if ($min_rel_document_frequency or $max_rel_document_frequency) {
			for (keys %dictionary) {
				delete $dictionary{$_} if $min_rel_document_frequency and $document_frequency{$_} < $min_rel_document_frequency * @texts;
				delete $dictionary{$_} if $max_rel_document_frequency and $document_frequency{$_} > $max_rel_document_frequency * @texts;
			}
		}


		# deleting words with low and high frequency/document frequency from texts
		# TODO: the following only if some words have been removed
		for my $text (@texts) {
			for my $i (reverse 0..$#$text) {
				splice @$text, $i, 1 unless exists $dictionary{$text->[$i]};
			}
		}

		# deleting texts (and their associated classes) with no words
		# TODO: the following only if some words have been removed
		for my $i (reverse 0..$#texts) {
			unless (@{$texts[$i]}) {
				splice @texts, $i, 1;       # removing the text
				$classes{$classes[$i]}--;   # decreasing the number of texts in the class of the removed text
				splice @classes, $i, 1;     # removing associated class
				splice @original_texts, $i, 1 if $print_original_texts; # removing the original text
				splice @all_skipped_tokens, $i, 1 if ($print_original_texts or $print_tokens) and $skip_tokens and $print_skipped_tokens; # removing skipped tokens
			}
		}
		# deleting classes with no documents
		for (keys %classes) {
			delete $classes{$_} unless $classes{$_};
		}

		debug("words with low ang high frequency/document frequency deleted\n");
		$pw_label->configure(-text => "Words with low ang high frequency/document frequency deleted") if defined $pw_label;
	}


	# write the dictionary if desired
	if ($write_dictionary) {
		write_dictionary();
		debug("dictionary written\n");
	}
	# write the dictionary with frequencies if desired
	if ($write_dictionary_freq or $write_dictionary_freq_classes) {
		write_dictionary_with_frequencies();
		debug("dictionary with frequencies written\n");
	}
	# write the dictionary with document frequencies if desired
	if ($write_dictionary_df or $write_dictionary_df_classes) {
		write_dictionary_with_document_frequencies();
		debug("dictionary with document frequencies written\n");
	}

	# printing the statistics
	if ($print_statistics) {

		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL( \*S, ">", "$output_dir/$output_file.stat.txt") or die $!;
		} else {
			open S, ">", "$output_dir/$output_file.stat.txt" or die $!;
		}

		print S "Preprocessing parameters\n========================\n";
		if ($read_directory) {
			print S "input directory: $read_directory\n";
		} else {
			print S "input file: $input_file\n";
		}
		print S "minimal word length: $min_word_length\n";
		print S "maximal word length: $max_word_length\n" if $max_word_length;
		print S "minimal global word frequency: $min_global_frequency\n";
		print S "maximal global word frequency: $max_global_frequency \n" if $max_global_frequency;
		print S "minimal local word frequency: $min_local_frequency\n";
		print S "maximal local word frequency: $max_local_frequency\n" if $max_local_frequency;
		print S "minimal document frequency: $min_document_frequency\n";
		print S "maximal document frequency: $max_document_frequency\n" if $max_document_frequency;
		print S "normalization: ", $normalization?$normalization:'none', $/;
		print S "n_grams: $n_grams\n";
		print S "local_weights: $local_weights\n";
		print S "real k value: $real_k_value \n"  if $real_k_value;
		print S "global_weights: ", $global_weights?$global_weights:'none',  "\n";
		print S "remove_multiple_characters: ", $remove_multiple_characters?'yes':'no', "\n";
		print S "case folding: ", ('no', 'lower case', 'upper case')[$case], "\n";
		print S "preserve_numbers: $preserve_numbers \n" if $preserve_numbers;
		print S "preserve_emoticons: $preserve_emoticons \n" if $preserve_emoticons;
		print S "preserve_symbols: $preserve_symbols \n" if $preserve_symbols;
		print S "dictionary file: $dictionary_file \n" if $dictionary_file;
		print S "stopwords file: $stopwords_file \n" if $stopwords_file;
		print S "allowed symbols file: $allowed_symbols_file \n" if $allowed_symbols_file;
		print S "replacement rules file: $replacement_rules_file \n" if $replacement_rules_file;
		print S "stemming: ", $stemming?$stemming:'none', "\n";
		print S "logarithm type: ", $natural_logarithm?'natural':'common', $/;
		print S "processed tags: ", join (', ', @tags), $/ if @tags;
		print S "split into elements: ", $split_into_elements?$split_into_elements:'no', $/;
		print S "split into sentences: ", $sentences?$sentences:'no', $/;

		print S "\nData set characteristics\n========================\n";
		print S scalar @texts, " documents\n";
		print S scalar keys %dictionary, " unique attributes\n\n";

		my %lengths = ();
		for my $i (0..$#texts) {
			push @{$lengths{$classes[$i]}}, scalar @{$texts[$i]};
		}

		for my $c (keys %lengths) {

			print S "class: ",(defined $c and $c?($c, "\n", '-' x (7+length $c)):("UNDEFINED\n", '-' x (16+length $c))), "\n$classes{$c} documents\n";

			my $n = 0;
			for (keys %{$dictionary_classes{$c}}) {
				$n++ if exists $dictionary{$_};
			}
			print S "$n unique attributes\n";

			my ($min, $max, $avg, $sum, $var, $dev) = (undef) x 6;
			for (@{$lengths{$c}}) {
				$min = $_ if not defined $min or $_ < $min;
				$max = $_ if not defined $max or $_ > $max;
				$sum += $_;
			}
			$avg = $sum/@{$lengths{$c}};
			$sum = 0;
			for (@{$lengths{$c}}) {
				$sum += ($_ - $avg)**2;
			}
			print S "terms number: min $min, max $max, avg $avg, var ", ($sum/@{$lengths{$c}}), $/ x 2;
		}
		print S "\n";



		close S;
	}

	# the modified text data (e.g., with removed stopwords, infrequent words, selected classes etc.) should be written
	if ($print_tokens) {
		if ($class_position) {
			for my $i (0..$#texts) {
				if ($print_skipped_tokens) {
					print TOKENS "$classes[$i]\t$all_skipped_tokens[$i] @{$texts[$i]}\n" or die $!;
				} else {
					print TOKENS "$classes[$i]\t@{$texts[$i]}\n" or die $!;
				}
			}
		} else {
			for my $i (0..$#texts) {
				if ($print_skipped_tokens) {
					print TOKENS "$all_skipped_tokens[$i] @{$texts[$i]}\n" or die $!;
				} else {
					print TOKENS "@{$texts[$i]}\n" or die $!;
				}
			}
		}
		close TOKENS;
		debug("tokens written\n");
	}

	# the original text data (e.g., with removed stopwords, infrequent words, selected classes etc.) should be written
	if ($print_original_texts) {
		for my $i (0..$#original_texts) {
			if ($print_skipped_tokens) {
				print ORIG "$all_skipped_tokens[$i] $original_texts[$i]\n" or die $!;
			} else {
				print ORIG "$original_texts[$i]\n" or die $!;
			}

		}
		close ORIG;
		debug("original texts written\n");
	}

	if ($preprocess_data) {
		debug("preprocessing finished\n");
		return;
		# TODO: deleting unnecessary data
	}

	# transforming the dictionary into alphabetically ordered list
	my @dictionary = ();
	@dictionary = keys %dictionary; #if $sort_attributes eq 'NONE';
	@dictionary = sort keys %dictionary if $sort_attributes eq 'ALPHABETICALLY';
	@dictionary = reverse sort keys %dictionary if $sort_attributes eq 'ALPHABETICALLY INVERSELY';
	@dictionary = sort {$document_frequency{$b} <=> $document_frequency{$a}} keys %dictionary if $sort_attributes eq 'DOCUMENT FREQUENCY (DESCENDING)';
	@dictionary = sort {$document_frequency{$a} <=> $document_frequency{$b}} keys %dictionary if $sort_attributes eq 'DOCUMENT FREQUENCY (ASCENDING)';

	my $number_of_words = scalar @dictionary;
	debug("number words of in the dictionary: $number_of_words\n");

	$number_of_documents = @texts;

	$pw_info->configure(-text => "Number of documents: $number_of_documents, number of attributes: $number_of_words") if defined $pw_info;

	# order of words in the vector
	my %word_order;
	for my $i (0..$#dictionary) {
		$word_order{$dictionary[$i]} = $i;
	}
	#debug("output format: $output_format");


	# creating headers of the output files
	# TODO: adding attributes representing skipped tokens if desired
	if ($output_format eq 'ARFF' or $output_format eq 'SPARSE ARFF') {
		# @RELATION name
		# @ATTRIBUTE name TYPE
		# @DATA
		# v1,v2,v3...,vn

		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.arff") or die $!;
		} else {
			open O, ">$encoding", "$output_dir/$output_file.arff" or die $!;
		}

		print O "\@RELATION data\n\n";
		print O "\@ATTRIBUTE	$_	NUMERIC\n" for @dictionary;
		print O "\@ATTRIBUTE	_CLASS_	{", join(',', sort keys %classes), "}" if $class_position;
		print O "\n\@DATA\n";
		push @files_to_delete, "$output_dir/$output_file.arff";

	} 	if ($output_format eq 'XRFF' or $output_format eq 'SPARSE XRFF') {

		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.xrff") or die $!;
		} else {
			open O, ">$encoding", "$output_dir/$output_file.xrff" or die $!;
		}
		print O qq!<dataset name="data">\n\t<header>\n\t\t<attributes>\n!;
		print O qq!\t\t\t<attribute name="$_" type="numeric"/>\n! for @dictionary;
		if ($class_position) {
			print O qq!\t\t\t<attribute class="yes" name="class" type="nominal">\n!;
			print O qq!\t\t\t\t<labels>\n!;
			print O qq!\t\t\t\t\t<label>$_</label>\n! for sort keys %classes;
			print O qq!\t\t\t\t</labels>\n!;
			print O qq!\t\t\t</attribute>\n!;
		}
		print O qq!\t\t</attributes>\n!;
		print O qq!\t</header>\n!;
		print O qq!\t<body>\n\t\t<instances>\n!;

		push @files_to_delete, "$output_dir/$output_file.arff";

	} elsif ($output_format eq 'C5') {
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.names");
		} else {
			open O, ">$encoding", "$output_dir/$output_file.names";
		}
		print O "\|classes\n", join(',', sort keys %classes), "\n\n" if $class_position;
		print O "$_:	continuous.\n" for @dictionary;
		close O;
		push @files_to_delete, "$output_dir/$output_file.names";
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">", "$output_dir/$output_file.data");
		} else {
			open O, ">", "$output_dir/$output_file.data";
		}
		push @files_to_delete, "$output_dir/$output_file.data";

	} elsif ($output_format eq 'SPARSE') {
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.sparse");
		} else {
			open O, ">$encoding", "$output_dir/$output_file.sparse";
		}
		push @files_to_delete, "$output_dir/$output_file.sparse";
   	} elsif ($output_format eq 'SVMLIGHT') {
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.SVMlight.dat");
		} else {
			open O, ">$encoding", "$output_dir/$output_file.SVMlight.dat";
		}
		push @files_to_delete, "$output_dir/$output_file.SVMlight.dat";
   	} elsif ($output_format eq 'CSV') {
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.csv");
		} else {
			open O, ">$encoding", "$output_dir/$output_file.csv";
		}
		if ($class_position) {
			print O join ',', @dictionary, 'CLASS'; print O $/;
		} else {
			print O join ',', @dictionary; print O $/;
		}
		push @files_to_delete, "$output_dir/$output_file.csv";
	} elsif ($output_format eq 'CLUTO (DENSE)' or $output_format eq 'CLUTO (SPARSE)') {
		my $ext = 'sparse';
		$ext = 'dense' if $output_format eq 'CLUTO (DENSE)';
		# extract and print meta data
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.$ext") or die $!;
		} else {
			open O, ">$encoding", "$output_dir/$output_file.$ext" or die $!;
		}

		if ($output_format eq 'CLUTO (SPARSE)') {
			# count only unique instaces of words in each text/document
			my $values_count = 0;
			for my $i (0..$#texts) {
				my %unique_words;
				map { $unique_words{$_}=1 } @{ $texts[$i] };
				$values_count += keys %unique_words;
			}
			print O "$number_of_documents $number_of_words $values_count\n";
		} else {
			print O "$number_of_documents $number_of_words\n";
		}

		push @files_to_delete, "$output_dir/$output_file.$ext";

		# TODO: RLabel file - optional
		if ($class_position) {
			if ($^O =~ /MSWin/) {
				Win32::LongPath::openL(\*RL, ">$encoding", "$output_dir/$output_file.$ext.rlabel") or die $!;
			} else {
				open RL, ">$encoding", "$output_dir/$output_file.$ext.rlabel" or die $!;
			}
			print RL join "\n", @classes;
			close RL;
		}

	}  elsif ($output_format eq 'YALE') {
		if ($^O =~ /MSWin/) {
			Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.yale.sparse.tmp") or die $!;
		} else {
			open O, ">$encoding", "$output_dir/$output_file.yale.sparse.tmp" or die $!;
		}
		push @files_to_delete, "$output_dir/$output_file.yale.sparse.tmp";
	}


	debug("output:\n");

	# output in more files - TODO: doesn't make a sense
	my $file_number = 1;

	# for global weighting by Entropy
	my %word_entropy = ();
	if ($global_weights eq 'ENTROPY') {

		# storing word frequencies in all documents where term frequency <> 0
		my %word_frequencies = ();

		for my $i (0..$#texts) {
			# transforming words into a hash (word/term frequency)
			my %words = ();
			$words{$_}++ for @{$texts[$i]};

			# storing term frequency in the document
			push @{$word_frequencies{$_}}, $words{$_} for keys %words;
		}

		for my $word (keys %word_frequencies) {
			# calculating the sum of TFi/GF * log (TFi/GF) for i = 1 .. number of documents
			# for all terms

			for my $tf (@{$word_frequencies{$word}}) {
				$word_entropy{$word} += $tf / $dictionary{$word} * my_log ( $tf / $dictionary{$word} )
			}
		}
	}

	my $nnz = 0;

	$pw_label->configure(-text => 'Generating the output') if defined $pw_label;

	my $number_of_all_words = 0;
	if ($global_weights eq 'INVERSE TOTAL TERM FREQUENCY') {
		$number_of_all_words += $dictionary{$_} for keys %dictionary;
	}

	# global weighting
	for my $w (keys %dictionary) {
		if  ($global_weights eq 'INVERSE DOCUMENT FREQUENCY (IDF)') {
				if ($document_frequency{$w}) {
					$global_weights{$w} = my_log($number_of_documents / $document_frequency{$w});
				} else {
					$global_weights{$w} = 1; # TODO: proverit - pokud je DF pro slovo 0 (pracuje se s nejakym slovnikem, nektere slovo ale v datech neni)
				}
		} elsif ($global_weights eq 'SQUARED IDF') {
			$global_weights{$w} = my_log($number_of_documents / $document_frequency{$w})**2;
		} elsif  ($global_weights eq 'PROBABILISTIC IDF') {
			if ($number_of_documents - $document_frequency{$w}) {
				$global_weights{$w} = my_log(($number_of_documents - $document_frequency{$w}+1e-323)/ $document_frequency{$w});
			} else {
				$global_weights{$w} = 0;		# TODO: should be -INF
			}
		} elsif ($global_weights eq 'GLOBAL FREQUENCY IDF') {
			$global_weights{$w} = $dictionary{$w} / $document_frequency{$w};
		} elsif ($global_weights eq 'ENTROPY') {
			$global_weights{$w} = 1 + 1 / my_log ($number_of_documents) * $word_entropy{$w};
			#print "word $word, entropy ", 1 + 1 / my_log ($number_of_documents) * $word_entropy{$word}, $/;
		} elsif ($global_weights eq 'INCREMENTED GLOBAL FREQUENCY IDF') {
			$global_weights{$w} = $dictionary{$w} / $document_frequency{$w} + 1;
 		} elsif ($global_weights eq 'LOG-GLOBAL FREQUENCY IDF') {
			$global_weights{$w} = my_log( $dictionary{$w} / $document_frequency{$w} + 1);
 		} elsif ($global_weights eq 'SQUARE ROOT GLOBAL FREQUENCY IDF') {
			$global_weights{$w} = sqrt( $dictionary{$w} / $document_frequency{$w} - 0.9 );
 		} elsif ($global_weights eq 'INVERSE TOTAL TERM FREQUENCY') {
			$global_weights{$w} = my_log( $number_of_all_words / $dictionary{$w});
		} else {
			# global weighting is not set
			$global_weights{$w} = 1;
		}
	}



	my $average_document_length = 0;
	if ($local_weights eq 'DFR-LIKE NORMALIZATION') {
		# calculating average document length
		my $sum = 0;
		$sum += @$_ for @texts;
		$average_document_length = $sum / @texts;
	}

	my @indexes = (0..$#texts);
	if ($randomize) {
		use List::Util 'shuffle';
		@indexes = shuffle @indexes;
	}

	my %words; my @_out;

	my $document_number = 0;
	for my $i (  @indexes  ) {

		$document_number++;

		# displaying the progess and checking the request for stopping
		unless ($#texts <= 100 or $document_number % (int ($#texts/100))) {
			if (defined $pw) {
				# graphical mode
				unless ($$pw_stop) {
					$pw_progress_bar->value($document_number/$#texts*100);
					$pw_progress_bar->update();
				} else {
					# asking, whether really stop
					my $answer_dialog = $pw->DialogBox(-title => 'Processing',
												-default_button => 'No',
												-buttons => [ 'Yes', 'No'],);
					$answer_dialog->add("Label", -text => "Really stop?")->pack();
					if ($answer_dialog->Show() eq 'Yes') {
						# cleaning memory - TODO

						# deleting unnecessary files
						close O;
						unlink $_ for @files_to_delete;

						# destroying the progress window
						$pw->destroy;

						# stopping the subroutine
						return;
					} else {
						# continue
						$$pw_stop = 0;
					}
				}
			}
		}

		# transforming words into a hash (word/term frequency)
		%words = ();
		$words{$_}++ for @{$texts[$i]};

		# the vector representing the text contains only zeroes at the beginning
		@_out = (0) x $number_of_words;

		# finding maximal TF for calculating Augmented Normalized Term Frequency
		my $maxtf=0;

		if ($local_weights eq 'AUGMENTED NORMALIZED TF') {
			for my $word (keys %words) {
				$maxtf = $words{$word} if $words{$word} > $maxtf;
			}
		}


		# calculating the sum and number of TFs for calculating the average TF

		my ($sum_tf, $avg_tf) = (0, 0);
		if ($local_weights eq 'NORMALIZED LOGARITHM' or $local_weights eq 'AUGMENTED AVERAGE TF'
			or $local_weights eq 'CHANGED-COEFFICIENT AVERAGE TF' or $local_weights eq 'DFR-LIKE NORMALIZATION') {
			for my $word (keys %words) {
				$sum_tf += $words{$word};
			}
			$avg_tf = $sum_tf / $number_of_words;
		}

		# each existing word changes zero to non zero value

		for my $word (keys %words) {
			# local weighting
			my $local_weight;

			if ($local_weights eq 'BINARY (TERM PRESENCE)') {
				$local_weight = 1;
			} elsif ($local_weights eq 'TERM FREQUENCY (TF)') {
				$local_weight = $words{$word};
			} elsif ($local_weights eq 'SQUARED TF') {
				$local_weight = $words{$word}**2;
			} elsif ($local_weights eq 'THRESHOLDED TF') {
				$local_weight = $words{$word}; $local_weight = 2 if $local_weight > 2;
			} elsif ($local_weights eq 'LOGARITHM') {
				$local_weight = my_log($words{$word}+1);
			} elsif ($local_weights eq 'ALTERNATE LOGARITHM') {
				$local_weight = my_log($words{$word}) + 1;
			} elsif ($local_weights eq 'AUGMENTED NORMALIZED TF') {
				$local_weight = $real_k_value + (1-$real_k_value)*$words{$word}/$maxtf;
			} elsif ($local_weights eq 'CHANGED-COEFFICIENT AVERAGE TF') {
				$local_weight = $real_k_value + (1-$real_k_value)*$words{$word}/$avg_tf;
			} elsif ($local_weights eq 'NORMALIZED LOGARITHM') {
				$local_weight = my_log($words{$word}+1) / my_log($avg_tf+1);
			} elsif ($local_weights eq "OKAPI'S TF FACTOR") {
				# based on approximations to the 2-Poisson model
				$local_weight = $words{$word} / (2 + $words{$word});
			} elsif ($local_weights eq 'SQUARE ROOT') {
				$local_weight = $words{$word} ? (sqrt($words{$word}-0.5) + 1) : 0;
			} elsif ($local_weights eq 'AUGMENTED LOGARITHM') {
				$local_weight = $words{$word} ? ( $real_k_value + (1 - $real_k_value)*my_log($words{$word}+1) ) : 0;
			} elsif ($local_weights eq 'AUGMENTED AVERAGE TF') {
				$local_weight = $words{$word} ? ( $real_k_value + (1 - $real_k_value)*my_log($words{$word}/$avg_tf) ) : 0;
			} elsif ($local_weights eq 'DFR-LIKE NORMALIZATION') {
				$local_weight = $words{$word} * $average_document_length / $sum_tf;
			}

			$_out[$word_order{$word}] = $local_weight * $global_weights{$word};

		}

		# normalization

		if ($normalization) {
			if ($normalization eq 'COSINE') {
				# each value Xi in a vector (matrix row) is divided by
				# N = sqrt( sum (Xi**2) )
				my $N = sqrt eval join '+', map {$_**2} @_out;
				map {$_ = $_/$N} @_out;
			} elsif ($normalization eq 'SUM OF WEIGHTS') {
				# each value Xi in a vector (matrix row) is divided by
				# N = sum(Xi**2)
				my $N = eval join '+', @_out;
				map {$_ = $_/$N} @_out;
			} elsif ($normalization eq 'MAX WEIGHT') {
				# each value Xi in a vector (matrix row) is divided by Max(X)
				my $max=0;
				map {($_ > $max) && ($max = $_)} @_out;	# QQQ or $max = $max < $_ ? $_ : $max for @_out;
				map {$_ = $_/$max} @_out;
			} elsif ($normalization eq 'MAX TF') {
				# each value Xi in a vector (matrix row) is scaled so that its value is between 0.5 and 1.0
				my $max=0;
				map {($_ > $max) && ($max = $_)} @_out;	# QQQ or $max = $max < $_ ? $_ : $max for @_out;
				map {$_ = 0.5 + 0.5*$_/$max} @_out;
			} elsif ($normalization eq 'SQUARE ROOT') {
				# each value Xi in a vector (matrix row) is scaled to be equal to the square-root of its actual value
				map {$_ = ($_<0?-1:1) * sqrt abs $_} @_out;
			} elsif ($normalization eq 'LOGARITHM') {
				# each value Xi in a vector (matrix row) is scaled to be equal to the log of its actual value
				map {$_ = $_ && (($_<0?-1:1) * my_log( abs $_))} @_out;
			} elsif ($normalization eq 'FOURTH NORMALIZATION') {
				# each value Xi in a vector (matrix row) is divided by
				# N =  sum (Xi**4)
				my $N = sqrt eval join '+', map {$_**4} @_out;
				map {$_ = $_/$N} @_out;
			}
		}

		# output to desired number of decimal places
		# not needed for some local weights and when normalization is not used
		if ($output_decimal_places) {
			for (@_out) {
				$_ = sprintf "%.${output_decimal_places}f",$_ if $_;
			}
		}

		# TODO: unshift skipped tokens to @_out if desired


		if ($output_format eq 'ARFF' or $output_format eq 'C5' or $output_format eq 'CSV') {
			if ($class_position) {
				print O join(",", @_out, $classes[$i]);
			} else {
				print O join(",", @_out);
			}
			print O "\n";
		} elsif ($output_format eq 'XRFF') {
			if ($class_position) {
				print O qq!\t\t\t<instance>\n!, join("\n", map "\t\t\t\t<value>$_</value>", @_out, $classes[$i]), qq!\n\t\t\t</instance>\n!;
			} else {
				print O qq!\t\t\t<instance>\n!, join("\n", map "\t\t\t\t<value>$_</value>", @_out), qq!\n\t\t\t</instance>\n!;
			}
		} elsif ($output_format eq 'SPARSE XRFF') {
			my @_temp = ();
			for my $j (0..$#_out) {
				push @_temp, qq!\t\t\t\t<value index="!.($j+1).qq!">$_out[$j]</value>! if $_out[$j];
			}
			if ($class_position) {
				print O qq!\t\t\t<instance type="sparse">\n!,
						join("\n", @_temp),
						qq!\n\t\t\t\t<value index="!.($#_out+2).qq!">$classes[$i]</value>\n!;
			} else {
				print O qq!\t\t\t<instance type="sparse">\n!,
						join("\n", @_temp);
			}
			print O "\t\t\t</instance>\n";

		}
		elsif ($output_format eq 'SPARSE ARFF') {
			my @_temp = ();
			for my $j (0..$#_out) {
				push @_temp, "$j $_out[$j]" if $_out[$j];
			}
			if ($class_position) {
				print O '{'.join(",", @_temp, ($#_out+1)." $classes[$i]").'}';
			} else {
				print O '{'.join(",", @_temp).'}';
			}
			print O "\n";
		}
		elsif ($output_format eq 'SPARSE') {
			my @_temp = ();
			for my $j (0..$#_out) {
				push @_temp, "$j:$_out[$j]" if $_out[$j];
			}
			if ($class_position) {
				print O join(",", @_temp, $classes[$i]);
			} else {
				print O join(",", @_temp);
			}
			print O "\n";
		}
		elsif ($output_format eq 'SVMLIGHT') {
			my @_temp = ();
			for my $j (0..$#_out) {
				push @_temp, ($j+1).":$_out[$j]" if $_out[$j];
			}
			print O join(" ", $classes[$i], @_temp);
			print O "\n";
		}

        elsif ($output_format eq 'CLUTO (SPARSE)') {
            my @_temp = ();
            for my $j (0..$#_out) {
                push @_temp, $j + 1 . " $_out[$j]" if $_out[$j];
                #push @_temp, "1" if $_out[$j];
            }
            print O join(" ", @_temp), "\n";
        }
		elsif ($output_format eq 'CLUTO (DENSE)') {
            print O join(" ", @_out);
			print O "\n";
        }
		elsif ($output_format eq 'YALE') {
			my @_A = (); my @_IA = (); my @_JA = ();

			for my $j (0..$#_out) {
				if ($_out[$j]) {
					push @_A, $_out[$j];
					push @_JA, $j;
				}
			}

			if ($i > 0) {
				my %seen;
				map { $seen{$_}++ } @{ $texts[$i-1] };
				$nnz += keys %seen;
			}

			push @_IA, $nnz;
			push @_IA, $nnz + @_A if $i == $#texts;

			print O join ";", (join(" ", @_A), join(" ", @_IA), join(" ", @_JA));
			print O "\n";

			if ($i eq $#texts) {
				close O;

				@_A  = ();
				@_IA = ();
				@_JA = ();

				if ($^O =~ /MSWin/) {
					Win32::LongPath::openL(\*O, ">$encoding", "$output_dir/$output_file.yale.sparse") or die $!;
					Win32::LongPath::openL(\*T, "<$encoding", "$output_dir/$output_file.yale.sparse.tmp") or die "$!: $output_dir/$output_file.yale.sparse.tmp";
				} else {
					open O, ">$encoding", "$output_dir/$output_file.yale.sparse" or die $!;
					open T, "<$encoding", "$output_dir/$output_file.yale.sparse.tmp" or die "$!: $output_dir/$output_file.yale.sparse.tmp";
				}

				while (<T>) {
					chomp;
					my ($_A, $_IA, $_JA) = split /;/;
					push @_A, split / /, $_A;
					push @_IA, split / /, $_IA;
					push @_JA, split / /, $_JA;
				}
				close T;
				unlink "$output_dir/$output_file.yale.sparse.tmp" or die $!;

				print O join(" ", @_A),  "\n";
				print O join(" ", @_IA), "\n";
				print O join(" ", @_JA), "\n";
			}
	        }

		#if ($max_records_in_output_file and not (($i+1) % $max_records_in_output_file)) {
		#	# maximal number of lines in output file was reached, new file is opened
		#	open O, ">", "vector$file_number.data";		# TODO
		#	$file_number++;
		#}

		debug("\r line $i") unless $i % 100;

	}
	debug("\n");
	if ($output_format eq 'XRFF' or $output_format eq 'SPARSE XRFF') {
		print O "\n\t\t</instances>\n\t</body>\n</dataset>";
	}

	close O;
	#close NZ;

}


sub remove_tags_and_entities {
	# removes tags
 	$_[0] =~ s/<[^>]*>/ /gs;

	# removes entities
	$_[0] =~ s/\&[^;]*;/ /gs;
}

sub remove_characters {
	# removes given characters
	$_[0] =~ s/[\P{L}0-9_]/ /g;		# removes all non-letters
	#$_[0] =~ s/[^a-zA-Z]+/ /g;		# removes all non-letters
}

sub remove_long_or_short_words {
	# removes words with low or high number of characters
	my (undef, $min, $max) = @_;

    for (reverse 0..$#{$_[0]}) {
        if ($min) {
			splice @{$_[0]}, $_, 1 if length $_[0]->[$_] < $min
        };
        if ($max) {
			splice @{$_[0]}, $_, 1 if length $_[0]->[$_] > $max
        };
    }

}

sub remove_locally_frequent_words {
    my (undef, $min, $max) = @_;

    my %frequencies;
    $frequencies{$_}++ for @{$_[0]};

    for (reverse 0..$#{$_[0]}) {
        if ($min) {
            splice @{$_[0]}, $_, 1 if $frequencies{$_[0]->[$_]} < $min
        };
        if ($max) {
            splice @{$_[0]}, $_, 1 if $frequencies{$_[0]->[$_]} > $max
        };
    }
}


sub write_dictionary {
	# creating a file containg all words from the dictionary
	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*D, ">$encoding", "$output_dir/$output_file.dict") or die $!;
	} else {
		open D, ">$encoding", "$output_dir/$output_file.dict" or die $!;
	}
	debug("dictionary size: ". scalar(keys %dictionary)."\n");
	print D join "\n", sort keys %dictionary;
	close D;
}

sub write_dictionary_with_frequencies {
	# creating a file containig all words and their frequencies, sorted by frequencies
	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*D, ">$encoding", "$output_dir/$output_file.freq.dict") or die $!;
	} else {
		open D, ">$encoding", "$output_dir/$output_file.freq.dict" or die $!;
	}

	if ($write_dictionary_freq_classes) {
		# printing global frequencies and frequencies for individual classes

		# creating sorted list of existing classes
		my @_classes = sort keys %{ { map {$_ => 1} @classes } };

		print D "#WORD\tTOTAL\t", join ("\t", @_classes), "\n";

		for my $word (sort {$dictionary{$b} <=> $dictionary{$a}} keys %dictionary) {
			print D "$word\t$dictionary{$word}\t";
			print D join "\t", map { $dictionary_classes{$_}->{$word} || 0 } @_classes;
			print D "\n";
		}
	} else {
		# printing just the global frequencies
		print D join "\n", map {"$_\t$dictionary{$_}"} sort {$dictionary{$b} <=> $dictionary{$a}} keys %dictionary;
	}
	close D;
}

sub write_dictionary_with_document_frequencies {
	# creating a file containig all words and their document frequencies, sorted by document frequencies
	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*D, ">$encoding", "$output_dir/$output_file.df.dict") or die $!;
	} else {
		open D, ">$encoding", "$output_dir/$output_file.df.dict" or die $!;
	}

	if ($write_dictionary_df_classes) {
		# printing global document frequencies and document frequencies for individual classes

		# creating sorted list of existing classes
		my @_classes = sort keys %{ { map {$_ => 1} @classes } };

		print D "#WORD\tTOTAL\t", join ("\t", @_classes), "\n";

		for my $word (sort {$document_frequency{$b} <=> $document_frequency{$a}} keys %dictionary) {
			print D "$word\t$document_frequency{$word}\t";
			print D join "\t", map { $document_frequency_classes{$_}->{$word} || 0 } @_classes;
			print D "\n";
		}
	} else {
		# printing just the global document frequencies
		print D join "\n", map {"$_\t$document_frequency{$_}"} sort {$document_frequency{$b} <=> $document_frequency{$a}} keys %dictionary;
	}
	close D;
}


sub read_dictionary {
	# reads the file with a dictionary and stores the allowed words
	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*D, "<$encoding", $dictionary_file) or die "Can't open dictionary file $dictionary_file\n";
	} else {
		open D, "<$encoding", $dictionary_file or die "Can't open dictionary file $dictionary_file\n";
	}

	# creates a the dictionary, the frequency of dictionary words
	# is initially set to 0 which means that no such words have been
	# found in the texts so far
	while (<D>) {
			s/\x{feff}//;
         	chomp;
			s/^\s+//; s/\s+$//;
			next unless $_;
         	$dictionary{case($_)} = 0;
	}
	close D;
}

sub read_stopwords {
	# reads the file with stopwords and stores them
	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*D, "<$encoding", $stopwords_file) or die "Can't open file with stopwords $stopwords_file\n";
	} else {
		open D, "<$encoding", $stopwords_file or die "Can't open file with stopwords $stopwords_file\n";
	}

	while (<D>) {
			s/\x{feff}//;
         	chomp;
			s/^\s+//; s/\s+$//;
			next unless $_;
			$_ = case($_);
         	$stopwords{$_} = 1;
	}
	close D;
}

sub read_allowed_symbols {
	# reads the file with allowed symbols and stores them
	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*D, "<$encoding", $allowed_symbols_file) or die "Can't open file with allowed symbols $allowed_symbols_file\n";
	} else {
		open D, "<$encoding", $allowed_symbols_file or die "Can't open file with allowed symbols $allowed_symbols_file\n";
	}

	my @allowed_symbols = ();
	while (<D>) {
			s/\x{feff}//;
         	chomp;
			s/^\s+//; s/\s+$//;
			next unless $_;
			$_ = case($_);
         	push @allowed_symbols, $_;
	}
	my @_allowed_symbols = @allowed_symbols;
	map{ s/[\^\$\\\[\]\.\|+*?{}()\$]/\\$&/g } @_allowed_symbols;		# escaping RE metacharacters
	$allowed_symbols_re = join '|', @_allowed_symbols;					# preparing a RE to capture allowed symbols
	close D;
}

sub read_replacement_rules {
	# reads the file with replacement rules
	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*D, "<$encoding", $replacement_rules_file) or die "Can't open file with replacmeent rules $replacement_rules_file\n";
	} else {
		open D, "<$encoding", $replacement_rules_file or die "Can't open file with replacmeent rules $replacement_rules_file\n";
	}

	while (<D>) {
			s/\x{feff}//;
         	chomp;
			s/^\s+//; s/\s+$//;
			next unless $_;
			$_ = case($_);
			my ($L, $R) = split /=>/;	# finding left and right part of a rule
			$L =~ s/^\s+//; $L =~ s/\s+$//; $R =~ s/^\s+//; $R =~ s/\s+$//;	# stripping whitespaces
			$L =~ s/[\^\$\\\[\]\.\|+*?{}()\$]/\\$&/g; 		# escaping RE metacharacters
			$R =~ s/[\^\$\\\[\]\.\|+*?{}()\$]/\\$&/g; 		# escaping RE metacharacters
			# TODO: check completeness of each rule
			push @replacement_rules_L, $L;
			push @replacement_rules_R, $R;
	}
	close D;
}


sub read_emoticons {
	# reads the file with emoticons and stores them
	use Cwd 'abs_path';
	$emoticons_file = abs_path($0);
	$emoticons_file =~ s|[^\/]+$|emoticons.txt|;
	if ($^O =~ /MSWin/) {
		Win32::LongPath::openL(\*D, "<$encoding", $emoticons_file) or die "Can't open file with emoticons $emoticons_file\n";
	} else {
		open D, "<$encoding", $emoticons_file or die "Can't open file with emoticons $emoticons_file\n";
	}

	while (<D>) {
			s/\x{feff}//;
         	chomp;
			s/^\s+//; s/\s+$//;
			next unless $_;
			my ($em, $desc) = split /\s+/, $_, 2;  # the file contains one emoticon + a description on each line
			$desc =~ s/\s+/_/g;  # the description might contain spaces, they are replaced by _

         	$emoticons{$em} = "emoticon__$desc";
	}
	$emoticons_re = join '|', map { quotemeta } keys %emoticons;

	close D;
}


sub my_log {
	# returns natural or common logarithm
	return $natural_logarithm ? log shift : log(shift)/log(10);
}

sub case {
	if ($case == 0) {
		# no modification
		return shift;
	} elsif ($case == 1) {
		# lower case
		return lc shift;
	} else {
		# upper case
		return uc shift;
	}
}

sub debug {
	print STDERR $_[0] if $_DEBUG;
}
1;
