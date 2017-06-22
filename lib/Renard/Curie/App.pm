use Renard::Curie::Setup;
package Renard::Curie::App;
# ABSTRACT: A document viewing application

use Moo 2.001001;

use Renard::Curie::Helper;

use File::Spec;
use File::Basename;
use Module::Util qw(:all);
use Renard::Curie::Types qw(InstanceOf Path Str DocumentModel File);
use Getopt::Long::Descriptive;

use MooX::Role::Logger ();

use Renard::Curie::Component::MainWindow;

=attr main_window

The toplevel L<Renard::Curie::Component::MainWindow> component for this application.

=cut
has main_window => (
	is => 'ro',
	isa => InstanceOf['Renard::Curie::Component::MainWindow'],
	default => method() {
		Renard::Curie::Component::MainWindow->new( context => $self );
	},
	handles => [
		qw( open_document log_window page_document_component menu_bar outline window DND_TARGET_URI_LIST content_box )
	],
);

=method process_arguments

  method process_arguments()

Processes arguments given in C<@ARGV>.

=cut
method process_arguments() {
	my ($opt, $usage) = describe_options(
		"%c %o <filename>",
		[ 'version',        "print version and exit"                             ],
		[ 'short-version',  "print just the version number (if exists) and exit" ],
		[ 'help',           "print usage message and exit"                       ],
	);

	print($usage->text), exit if $opt->help;

	if($opt->version) {
		say("Project Renard Curie @{[ _get_version() ]}");
		say("Distributed under the same terms as Perl 5.");
		exit;
	}

	if($opt->short_version) {
		say(_get_version()), exit
	}

	my $pdf_filename = shift @ARGV;

	if( $pdf_filename ) {
		$self->_logger->infof("opening the file %s", $pdf_filename);
		$self->open_pdf_document( $pdf_filename );
	}
}

=func main

  fun main()

Application entry point.

=cut
method main() {
	$self = __PACKAGE__->new unless ref $self;
	$self->process_arguments;
	$self->main_window->show_all;
	$self->run;
}

=method run

  method run()

Displays L</window> and starts the L<Gtk3> event loop.

=cut
method run() {
	$self->_logger->info("starting the Gtk main event loop");
	Gtk3::main;
}

=func _get_version

  fun _get_version() :ReturnType(Str)

Returns the version of the application if there is one.
Otherwise returns the C<Str> C<'dev'> to indicate that this is a
development version.

=cut
fun _get_version() :ReturnType(Str) {
	return $Renard::Curie::App::VERSION // 'dev'
}

=method open_pdf_document

  method open_pdf_document( (Path->coercibles) $pdf_filename )

Opens a PDF file stored on the disk.

=cut
method open_pdf_document( (Path->coercibles) $pdf_filename ) {
	$pdf_filename = Path->coerce( $pdf_filename );
	if( not -f $pdf_filename ) {
		Renard::Curie::Error::IO::FileNotFound
			->throw("PDF filename does not exist: $pdf_filename");
	}

	my $doc = Renard::Curie::Model::Document::PDF->new(
		filename => $pdf_filename,
	);

	$self->open_document( $doc );
}

with qw(
	MooX::Role::Logger
);

1;
