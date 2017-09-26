#!/usr/bin/env perl
# ABSTRACT: A model/view-based GooCanvas

use Gtk3 qw(-init);
use Glib qw(TRUE FALSE);
use Modern::Perl;

use lib '/home/zaki/sw_projects/project-renard/p5-Renard-Incunabula-Format-PDF/p5-Renard-Incunabula-Format-PDF/lib';
use lib '/home/zaki/sw_projects/project-renard/p5-Renard-Incunabula-Frontend-Gtk3-GooCanvas/p5-Renard-Incunabula-Frontend-Gtk3-GooCanvas/lib';

use Renard::Incunabula::Format::PDF::Document;
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Frontend::Gtk3::Helper;
use Renard::Incunabula::Frontend::Gtk3::GooCanvas;

# This is our handler for the "delete-event" signal of the window, which
# is emitted when the 'x' close button is clicked. We just exit here.
sub on_delete_event {
	my ($window, $event, $data) = @_;

	exit(0);
}

sub main {
	# Create the window and widgets.
	my $window = Gtk3::Window->new('toplevel');
	$window->set_default_size(640, 600);
	$window->show;
	$window->signal_connect( delete_event => \&on_delete_event );

	my $scrolled_win = Gtk3::ScrolledWindow->new;
	$scrolled_win->set_shadow_type( 'in' );
	$scrolled_win->show;
	$window->add($scrolled_win);

	my $canvas = GooCanvas::Canvas->new;
	$canvas->set_size_request(600, 450);
	$canvas->set_property( 'automatic-bounds', TRUE );
	#$canvas->set_bounds(0, 0, 1000, 1000);
	$canvas->show;
	$scrolled_win->add( $canvas );

	my $root = GooCanvas::CanvasGroupModel->new;

	my $doc = Renard::Incunabula::Format::PDF::Document->new(
		filename => Renard::Incunabula::Devel::TestHelper
			->test_data_directory
			->child(qw(PDF Adobe pdf_reference_1-7.pdf)),
	);

	my $image_model_for_page = sub {
		my ($doc, $page_number) = @_;

		say "Creating image model for $page_number";
		my $page = $doc->get_rendered_page( page_number => $page_number );
		my $surface = $page->cairo_image_surface;
		my $pixbuf = Gtk3::Gdk::pixbuf_get_from_surface(
			$surface,
			0, 0,
			$surface->get_width, $surface->get_height,
		);

		my $image_model = GooCanvas::CanvasImageModel->new(
			width => $page->width,
			height => $page->height,
			pixbuf => $pixbuf,
		);
	};

	my $table_model = GooCanvas::CanvasTableModel->new(
		parent => $root,
		'column-spacing' => 10,
		'row-spacing' => 10,
	);

	my $add_child_to_row_column = sub {
		my ($table_model, $child_item, $row, $column) = @_;
		$table_model->add_child($child_item, -1 );
		$table_model->set_child_property($child_item, 'row', $row );
		$table_model->set_child_property($child_item, 'column', $column);
	};

	my $page_image_models;
	for my $page_number (1..10) {
		$page_image_models->{$page_number} = $image_model_for_page->($doc, $page_number);
		$table_model->$add_child_to_row_column($page_image_models->{$page_number},
			int(($page_number-1) / 2), ($page_number-1) % 2);

		#my $textual_page = $doc->get_textual_page( $page );

		say "Retrieving text for $page_number";
		my $stext = Renard::Incunabula::MuPDF::mutool::get_mutool_text_stext_xml(
			$doc->filename,
			$page_number,
		);
		#use DDP; p $stext;;
	}

	$canvas->set_root_item_model($root);

	$table_model->signal_connect(
		'child-notify' => sub {
			use DDP; p @_;
		},
	);

	for my $page (keys %$page_image_models) {
		my $page_model = $page_image_models->{$page};
		my $page_item = $canvas->get_item( $page_model );
		$page_item->{page} = $page;
		#$page_item->signal_connect(
			#'notify' => sub {
				#say "$page is visibile";
			#},
		#);
		$page_item->signal_connect(
			'button-press-event' => sub {
				say "$page was clicked";
			},
		);
	}

	my $get_items_in_canvas_area = sub {
		my @items = $canvas->get_items_in_area(
			GooCanvas::CanvasBounds->new(
				x1 => $canvas->get('hadjustment')->get_value,
				x2 => $canvas->get('hadjustment')->get_value
					+ $canvas->get('hadjustment')->get_page_size,
				y1 => $canvas->get('vadjustment')->get_value,
				y2 => $canvas->get('vadjustment')->get_value
					+ $canvas->get('vadjustment')->get_page_size,
			),
			TRUE,
			TRUE,
			FALSE,
		);
	};

	my $callback = sub {
		say 'scrolled';
		use DDP; p $get_items_in_canvas_area->();
		return FALSE;
	};

	#for my $adjustment ($canvas->get_hadjustment, $canvas->get_vadjustment) {
		#$adjustment->signal_connect( 'value-changed' => $callback );
		#$adjustment->signal_connect( 'changed' => $callback );
	#}


	# Pass control to the GTK+ main event loop.
	$window->show_all;
	Gtk3::main();

	return 0;
}

main;
