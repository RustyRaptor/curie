use Renard::Curie::Setup;
package Renard::Curie::App;
# ABSTRACT: A document viewing application

use Gtk3 -init;
use Cairo;
use Glib::Object::Introspection;
use Glib 'TRUE', 'FALSE';

use Moo 2.001001;

use Renard::Curie::Helper;
use Renard::Curie::Model::Document::PDF;
use Renard::Curie::Component::PageDrawingArea;
use Renard::Curie::Component::Outline;
use Renard::Curie::Component::MenuBar;
use Renard::Curie::Component::LogWindow;
use Renard::Curie::Component::FileChooser;
use Renard::Curie::Component::AccelMap;

use Log::Any::Adapter;
use MooX::Role::Logger ();
use Getopt::Long::Descriptive;

use Renard::Curie::Types qw(InstanceOf Path Str DocumentModel);
use Function::Parameters;

=attr window

A L<Gtk3::Window> that contains the main window for the application.

=cut
has window => ( is => 'lazy' );

method _build_window() :ReturnType(InstanceOf['Gtk3::Window']) {
	my $window = $self->builder->get_object('main-window');
}

=attr page_document_component

A L<Renard::Curie::Component::PageDrawingArea> that holds the currently
displayed document.

=for :list
* Predicate: C<has_page_document_component>
* Clearer: C<clear_page_document_component>

=for Pod::Coverage has_page_document_component clear_page_document_component

=cut
has page_document_component => (
	is => 'rw',
	isa => InstanceOf['Renard::Curie::Component::PageDrawingArea'],
	predicate => 1, # has_page_document_component
	clearer => 1 # clear_page_document_component
);

=attr menu_bar

A L<Renard::Curie::Component::MenuBar> for the application's menu-bar.

=cut
has menu_bar => (
	is => 'rw',
	isa => InstanceOf['Renard::Curie::Component::MenuBar'],
);

=attr outline

A L<Renard::Curie::Component::Outline> which makes up the outline sidebar for
this window.

=cut
has outline => (
	is => 'rw',
	isa => InstanceOf['Renard::Curie::Component::Outline'],
);

=attr log_window

A L<Renard::Curie::Component::LogWindow> for the application's logging.

=cut
has log_window => (
	is => 'rw',
	isa => InstanceOf['Renard::Curie::Component::LogWindow'],
);

=attr content_box

A horizontal L<Gtk3::Box> which is used to split the main application area into
two different regions.

The left region contains L</outline> and the right region contains L</page_document_component>.

=cut
has content_box => (
	is => 'rw',
	isa => InstanceOf['Gtk3::Box'],
);

=classmethod setup_gtk

  classmethod setup_gtk()

Sets up any of the L<Glib::Object::Introspection>-based libraries needed for
the application.

Currently loads nothing, but will load the Gnome Docking Library (C<libgdl>) in
the future.

=cut
classmethod setup_gtk() {
	# stub out the GDL loading for now. Docking is not yet used.
	##Glib::Object::Introspection->setup(
		##basename => 'Gdl',
		##version => '3',
		##package => 'Gdl', );
}

=method setup_window

  method setup_window()

Sets up components that make up the window shell for the application
including:

=for :list
* L</menu_bar>
* L</content_box>
* L</log_window>

=cut
method setup_window() {
	my $menu = Renard::Curie::Component::MenuBar->new( app => $self );
	$self->menu_bar( $menu );
	$self->builder->get_object('application-vbox')
		->pack_start( $menu, FALSE, TRUE, 0 );

	$self->content_box( Gtk3::Box->new( 'horizontal', 0 ) );
	$self->builder->get_object('application-vbox')
		->pack_start( $self->content_box, TRUE, TRUE, 0 );

	$self->outline( Renard::Curie::Component::Outline->new( app => $self ) );
	$self->content_box->pack_start( $self->outline , FALSE, TRUE, 0 );

	my $log_win = Renard::Curie::Component::LogWindow->new( app => $self );
	Log::Any::Adapter->set('+Renard::Curie::Log::Any::Adapter::LogWindow',
		log_window => $log_win );
	$self->log_window( $log_win );

	Renard::Curie::Component::AccelMap->new( app => $self );
}

=method run

  method run()

Displays L</window> and starts the L<Gtk3> event loop.

=cut
method run() {
	$self->window->show_all;
	$self->_logger->info("starting the Gtk main event loop");
	Gtk3::main;
}

=method BUILD

  method BUILD

Initialises the application and sets up signals.

=cut
method BUILD(@) {
	$self->setup_gtk;

	$self->setup_window;

	$self->window->signal_connect(
		destroy => \&on_application_quit_cb, $self );
	$self->window->set_default_size( 800, 600 );
}

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

=func _get_version

  fun _get_version() :ReturnType(Str)

Returns the version of the application if there is one.
Otherwise returns the C<Str> C<'dev'> to indicate that this is a
development version.

=cut
fun _get_version() :ReturnType(Str) {
	return $Renard::Curie::App::VERSION // 'dev'
}

=func main

  fun main()

Application entry point.

=cut
method main() {
	$self = __PACKAGE__->new unless ref $self;
	$self->process_arguments;
	$self->run;
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

	# set window title
	$self->window->set_title( $pdf_filename );

	$self->open_document( $doc );
}

=method open_document

  method open_document( (DocumentModel) $doc )

Sets the document for the application's L</page_document_component>.

=cut
method open_document( (DocumentModel) $doc ) {
	if( $self->has_page_document_component ) {
		$self->content_box->remove( $self->page_document_component );
		$self->clear_page_document_component;
	}
	my $pd = Renard::Curie::Component::PageDrawingArea->new(
		document => $doc,
	);
	$self->outline->update( $doc );
	$self->page_document_component($pd);
	$self->content_box->pack_start( $pd, TRUE, TRUE, 0 );
	$pd->show_all;
}

# Callbacks {{{
=callback on_open_file_dialog_cb

  callback on_open_file_dialog_cb( $event, $self )

Callback that opens a L<Renard::Curie::Component::FileChooser> component.

=cut
callback on_open_file_dialog_cb( $event, $self ) {
	my $file_chooser = Renard::Curie::Component::FileChooser->new( app => $self );
	my $dialog = $file_chooser->get_open_file_dialog_with_filters;

	my $result = $dialog->run;

	if ( $result eq 'accept' ) {
		my $filename = $dialog->get_filename;
		$dialog->destroy;
		$self->open_pdf_document($filename);
	} else {
		$dialog->destroy;
	}
}

=callback on_application_quit_cb

  callback on_application_quit_cb( $event, $self )

Callback that stops the L<Gtk3> main loop.

=cut
callback on_application_quit_cb( $event, $self ) {
	Gtk3::main_quit;
}
# }}}

with qw(
	Renard::Curie::Component::Role::FromBuilder
	Renard::Curie::Component::Role::UIFileFromPackageName
	MooX::Role::Logger
);

1;
