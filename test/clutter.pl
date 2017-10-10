#!/usr/bin/env perl
# ABSTRACT: Clutter


use Modern::Perl;
use Gtk3;
use Clutter;
use Glib::Object::Introspection;

use Data::DPath qw(dpathi);
use Renard::Incunabula::Format::PDF::Document;
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Frontend::Gtk3::Helper;

sub on_delete_event {
	my ($window, $event, $data) = @_;

	exit(0);
}

sub page_click_handler {
	say "page clicked";
}

sub text_click_handler {
	say "text clicked";
}

sub main {
	Glib::Object::Introspection->setup(
		basename => 'GtkClutter',
		version => '1.0',
		package => 'Gtk3::Clutter',
	);
	Gtk3::Clutter::init(undef);

	# Create the window and widgets.
	my $window = Gtk3::Window->new('toplevel');
	$window->set_default_size(640, 600);
	$window->show;
	$window->signal_connect( delete_event => \&on_delete_event );

	my $scrolled_win = Gtk3::ScrolledWindow->new;
	$scrolled_win->set_shadow_type( 'in' );
	$scrolled_win->show;
	$window->add($scrolled_win);

	my $embed = Gtk3::Clutter::Embed->new;
	$scrolled_win->add( $embed );

	my $doc = Renard::Incunabula::Format::PDF::Document->new(
		filename => Renard::Incunabula::Devel::TestHelper
			->test_data_directory
			->child(qw(PDF Adobe pdf_reference_1-7.pdf)),
	);

	my $pages_group = setup_actors($doc);

	my $stage = $embed->get_stage;
	$pages_group->set_property( 'background-color', Clutter::Color->new(0, 255, 0, 255) );
	$stage->add_child( $pages_group );
	#$stage->add_child( Clutter::Text->new_with_text("Sans 24", "A bit of text") );

	$window->show_all;

	Gtk3::main;
}

sub setup_actors {
	my ($doc) = @_;
	my $grid_layout = Clutter::GridLayout->new;

	my $pages_group = Clutter::Actor->new;
	$pages_group->set_layout_manager( $grid_layout );

	for my $page_number (1..2) {
		my $render_group = Clutter::Actor->new;

		my $page_group = Clutter::Actor->new;
		{
			my $page = $doc->get_rendered_page( page_number => $page_number );
			my $surface = $page->cairo_image_surface;
			my $pixbuf = Gtk3::Gdk::pixbuf_get_from_surface(
				$surface,
				0, 0,
				$surface->get_width, $surface->get_height,
			);

			my $clutter_image = Clutter::Image::new();
			$clutter_image->set_bytes(
				Glib::Bytes->new($pixbuf->read_pixels),
				$pixbuf->get_has_alpha
					? 'rgba_8888'
					: 'rgb_888',
				$pixbuf->get_width,
				$pixbuf->get_height,
				$pixbuf->get_rowstride,
			);

			$page_group->set_position( 0, 0 ) ;
			$page_group->set_size( $surface->get_width, $surface->get_height ) ;
			$page_group->set_property( 'background-color', Clutter::Color->new(255, 0, 0, 255) );

			$page_group->set_content( $clutter_image );
		}

		my $text_span_group = Clutter::Actor->new;
		{
			my $stext = Renard::Incunabula::MuPDF::mutool::get_mutool_text_stext_xml(
				$doc->filename,
				$page_number,
			);
			my $text_concat = "";
			my $root = dpathi($stext);
			my $char_iterator = $root->isearch( '/page/*/block/*/line/*/span/*' );

			while( $char_iterator->isnt_exhausted ) {
				my $value = $char_iterator->value;
				my $deref = $value->deref;
				my ($x1, $y1, $x2, $y2) = split ' ', $deref->{bbox};
				my $text = join '', map { $_->{c} } @{ $deref->{char} };
				my $font = join " ", ($deref->{font}); # , $deref->{size}
				my $rect_actor = Clutter::Actor->new;
				$rect_actor->set_position(   $x1,       $y1 );
				$rect_actor->set_size( $x2 - $x1, $y2 - $y1 );

				$text_span_group->add_child( $rect_actor );
			}
		}

		$render_group->add_child( $page_group );
		$render_group->add_child( $text_span_group );

		$grid_layout->attach($render_group, 
			($page_number-1) % 2, int(($page_number-1) / 2), 1, 1 );
	}

	return $pages_group;
}

main;
