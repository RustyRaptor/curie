#!/usr/bin/env perl

use Modern::Perl;
use Gtk3;
use lib 'lib';
use Renard::Curie::Component::PageTextArea;

sub init {
	Glib::Object::Introspection->setup(
		basename => 'GtkClutter',
		version => '1.0',
		package => 'Gtk3::Clutter', );
	Glib::Object::Introspection->setup(
		basename => 'Clutter',
		version => '1.0',
		package => 'Clutter', );
	# call this init instead of Gtk3::init() or Clutter::init()
	Gtk3::Clutter::init(undef);
}

sub main {
	init;

	my $window = Gtk3::Window->new ('toplevel');

	$window->signal_connect(destroy => sub { Gtk3::main_quit });
	$window->set_default_size( 800, 600 );

	$window->add(
		Renard::Curie::Component::PageTextArea->new(
			filename => '../../test-data/test-data/PDF/Adobe/pdf_reference_1-7.pdf',
			page_number => 23,
		)
	);

	$window->show_all;

	Gtk3::main;
}

main;
