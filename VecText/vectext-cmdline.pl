use lib 'c:/VecText';
use strict;
use VecText;
use Getopt::Long;


my $input_file = undef;
my $read_directory = undef;
my $encoding = undef;
my $subset_size = undef;
my $skip_tokens = undef;
my $randomize = undef;
my $class_position = undef;
my $processed_classes = undef;
my $output_dir = undef;
my $output_file = undef;
my $local_weights = undef;
my $global_weights = undef;
my $min_w_length = undef;
my $max_w_length = undef;
my $min_global_freq = undef;
my $max_global_freq = undef;
my $min_local_freq = undef;
my $max_local_freq = undef;
my $min_document_freq = undef;
my $max_document_freq = undef;
my $min_rel_document_freq = undef;
my $max_rel_document_freq = undef;
my $df_percentage = undef;
my $terms_to_keep = undef;
my $normalization = undef;
my $output_format = undef;
my $output_lines = undef;
my $less_memory = undef;
my $dictionary_only = undef;
my $create_dictionary = undef;
my $print_statistics = undef;
my $dictionary_file = undef;
my $stopwords_file = undef;
my $replacement_rules_file = undef;
my $abbrev_file = undef;
my $logarithm_type = undef;
my $tags = undef;
my $split_into_elements = undef;
my $sentences = undef;
my $print_original_texts = undef;
my $print_tokens = undef;
my $print_skipped_tokens = undef;
my $preprocess_data = undef;
my $remove_URIs = undef;
my $remove_multiple_characters = undef;
my $preserve_numbers = undef;
my $case = undef;
my $preserve_symbols = undef;
my $preserve_emoticons = undef;
my $output_decimal_places = undef;
my $sort_attributes = undef;
my $n_grams = undef;
my $stemming = undef;

my $error = GetOptions(
	'input|input_file=s' => \$input_file,
	'read_directory=s' => \$read_directory,
	'encoding=s' => \$encoding,
	'subset|subset_size=i' => \$subset_size,
	'skip_tokens=n' => \$skip_tokens,
	'class_position=n' => \$class_position,
	'randomize' => \$randomize,
	'processed_classes=s' => \$processed_classes,
	'output_dir=s' => \$output_dir,
	'output_file=s' => \$output_file,
	'local_weights=s' => \$local_weights,
	'global_weights=s' => \$global_weights,
	'min_word_length=i' => \$min_w_length,
	'max_word_length=i' => \$max_w_length,
	'min_global_frequency=i' => \$min_global_freq,
	'max_global_frequency=i' => \$max_global_freq,
	'min_local_frequency=i' => \$min_local_freq,
	'max_local_frequency=i' => \$max_local_freq,
	'min_document_frequency=i' => \$min_document_freq,
	'max_document_frequency=i' => \$max_document_freq,
	'min_rel_document_frequency=f' => \$min_rel_document_freq,
	'max_rel_document_frequency=f' => \$max_rel_document_freq,
	'df_percentage=f' => \$df_percentage,
	'terms_to_keep=i' => \$terms_to_keep,
	'normalization=s' => \$normalization,
	'output_format=s' => \$output_format,
	'n_grams=s' => \$n_grams,
	#'max_records_in_output_file' => \$output_lines,
	#'less_memory' => \$less_memory,
	'create_dictionary=s' => \$create_dictionary,
	'print_statistics' => \$print_statistics,
	'dictionary_file=s' => \$dictionary_file,
	'stopwords_file=s' => \$stopwords_file,
	'replacement_rules_file=s' => \$replacement_rules_file,
	'abbrev_file=s' => \$abbrev_file,
	'logarithm_type=s' => \$logarithm_type,
	'tags=s' => \$tags,
	'split_into_elements' => \$split_into_elements,
	'sentences=s' => \$sentences,
	'print_original_texts' => \$print_original_texts,
	'print_tokens' => \$print_tokens,
	'print_skipped_tokens' => \$print_skipped_tokens,
	'preprocess_data' => \$preprocess_data,
	'remove_multiple_characters' => \$remove_multiple_characters,
	'remove_URIs' => \$remove_URIs,
	'preserve_numbers' => \$preserve_numbers,
	'case=s' => \$case,
	'preserve_symbols' => \$preserve_symbols,
	'preserve_emoticons' => \$preserve_emoticons,
	'output_decimal_places=i' => \$output_decimal_places,
	'sort_attributes=s' => \$sort_attributes,
	'stemming=s' => \$stemming,


);
exit  unless $error;

my @errors = ();
push @errors, 'input file name or input directory' unless defined $input_file or defined $read_directory;
push @errors, 'output file name' unless defined $output_file;
push @errors, 'output directory' unless defined $output_dir;
push @errors, 'output format' unless defined $output_format;
push @errors, 'local weighting' unless defined $local_weights;

if (@errors) {
	print "The following mandatory parameters were not specified:\n";
	print map " - $_\n", @errors;
	exit;
}

my @messages = VecText::configure(
	-input_file => $input_file,
	-read_directory => $read_directory,
	-encoding => $encoding,
	-subset_size => $subset_size,
	-skip_tokens => $skip_tokens,
	-class_position => $class_position,
	-randomize => $randomize,
	-processed_classes => $processed_classes,
	-output_dir => $output_dir,
	-output_file => $output_file,
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
	-max_records_in_output_file => $output_lines,
	-less_memory => $less_memory,
	-dictionary_only => 0,
	-create_dictionary => $create_dictionary,
	-print_statistics => $print_statistics,
	-dictionary_file => $dictionary_file,
	-stopwords_file => $stopwords_file,
	-replacement_rules_file => $replacement_rules_file,
	-abbrev_file => $abbrev_file,
	-logarithm_type => $logarithm_type,
	-tags => $tags,
	-split_into_elements => $split_into_elements,
	-sentences => $sentences,
	-print_original_texts => $print_original_texts,
	-print_tokens => $print_tokens,
	-print_skipped_tokens => $print_skipped_tokens,
	-preprocess_data => $preprocess_data,
	-remove_multiple_characters => $remove_multiple_characters,
	-remove_URIs => $remove_URIs,
	-preserve_numbers => $preserve_numbers,
	-case => $case,
	-preserve_symbols => $preserve_symbols,
	-preserve_emoticons => $preserve_emoticons,
	-output_decimal_places => $output_decimal_places,
	-sort_attributes => $sort_attributes,
	-n_grams => $n_grams,
	-stemming => $stemming,
	);

warn map "$_\n", @messages if @messages;
warn "\n";

VecText::process_data_file;


