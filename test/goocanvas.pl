#!/usr/bin/env perl
# ABSTRACT: A model/view-based GooCanvas

use Gtk3 qw(-init);
use Glib qw(TRUE FALSE);
use Modern::Perl;

use lib '/home/zaki/sw_projects/project-renard/p5-Renard-Incunabula-Format-PDF/p5-Renard-Incunabula-Format-PDF/lib';
use lib '/home/zaki/sw_projects/project-renard/p5-Renard-Incunabula-Frontend-Gtk3-GooCanvas2/p5-Renard-Incunabula-Frontend-Gtk3-GooCanvas2/lib';

use Renard::Incunabula::Format::PDF::Document;
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Frontend::Gtk3::Helper;
use Renard::Incunabula::Frontend::Gtk3::GooCanvas2;
#use GooCanvas2;
use Data::DPath qw(dpathi);

# This is our handler for the "delete-event" signal of the window, which
# is emitted when the 'x' close button is clicked. We just exit here.
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
	# Create the window and widgets.
	my $window = Gtk3::Window->new('toplevel');
	$window->set_default_size(640, 600);
	$window->show;
	$window->signal_connect( delete_event => \&on_delete_event );

	my $scrolled_win = Gtk3::ScrolledWindow->new;
	$scrolled_win->set_shadow_type( 'in' );
	$scrolled_win->show;
	$window->add($scrolled_win);

	my $canvas = GooCanvas2::Canvas->new;
	$canvas->set_size_request(600, 450);
	$canvas->set_property( 'automatic-bounds', TRUE );
	$canvas->set_property( 'bounds-padding', 10.0 );
	$canvas->set_property( 'anchor', 'north' );
	#$canvas->set_bounds(0, 0, 1000, 1000);
	$canvas->show;
	$scrolled_win->add( $canvas );

	$canvas->add_events( [ qw/pointer-motion-mask button-press-mask enter-notify-mask/ ] );

	my $root = GooCanvas2::CanvasGroupModel->new;

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

		my $image_model = GooCanvas2::CanvasImageModel->new(
			width => $page->width,
			height => $page->height,
			pixbuf => $pixbuf,
		);
	};

	my $table_model = GooCanvas2::CanvasTableModel->new(
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
	my $page_text_models;
	for my $page_number (1..2) {
		my $group_model = GooCanvas2::CanvasTableModel->new;
		my ($page_layer, $text_layer);

		{
			$page_layer =  GooCanvas2::CanvasTableModel->new;

			$page_image_models->{$page_number} = $image_model_for_page->($doc, $page_number);

			$page_layer->add_child( $page_image_models->{$page_number}, 0 );
		}

		{
			$text_layer = GooCanvas2::CanvasGroupModel->new;

			say "Retrieving text for $page_number";
			my $stext = Renard::Incunabula::MuPDF::mutool::get_mutool_text_stext_xml(
				$doc->filename,
				$page_number,
			);
			my $text_concat = "";
			my $root = dpathi($stext);
			# '/page/*/block/*/line/*/span/*/char/*'
			my $char_iterator = $root->isearch( '/page/*/block/*/line/*/span/*' );

			while( $char_iterator->isnt_exhausted ) {
				my $value = $char_iterator->value;
				my $deref = $value->deref;
				my ($x1, $y1, $x2, $y2) = split ' ', $deref->{bbox};
				my $text = join '', map { $_->{c} } @{ $deref->{char} };
				my $font = join " ", ($deref->{font}); # , $deref->{size}
				my $text_model = GooCanvas2::CanvasTextModel->new(
					text => $text,
					font => $font,

					x => $x1, y => $y1,
					width => $x2 - $x1,
					height => -1,
					#height => $y2 - $y1,

					tooltip => 'Something or other',
					#'line-width' => 0,
					#'stroke-color' => 'red',
					'fill-color' => 'blue',
				);

				$text_model->{_s} = $value;
				$text_model->{_t} = $text;

				$text_layer->add_child( $text_model, 0 );

				push @{ $page_text_models->{$page_number} }, $text_model;

				#$text_concat .= $value->{c};
				#$text_concat .= $value->{bbox};
				#$text_concat .= $value->{x};
				#$text_concat .= $value->{y};

			}
		}
		#say $text_concat;
		#use DDP; p $stext;;

		$group_model->add_child( $page_layer, -1 );
		$group_model->add_child( $text_layer, -1 );

		$table_model->$add_child_to_row_column($group_model,
			int(($page_number-1) / 2), ($page_number-1) % 2);
	}

	$canvas->set_root_item_model($root);
	$canvas->set_property( 'has-tooltip' => TRUE );

	for my $page (keys %$page_image_models) {
		my $page_model = $page_image_models->{$page};


		my $page_item = $canvas->get_item( $page_model );
		$page_item->{page} = $page;

		$page_item->signal_connect(
			'button-press-event' => \&page_click_handler
		);
			#sub {
				#say "$page was clicked";

				#return FALSE;
			#},
		#$page_item->signal_connect(
			#'motion-notify-event' => sub {
				#say "page: $page";

				#return FALSE;
			#},
		#);

		my $text_models = $page_text_models->{$page};
		for my $text_model (@$text_models) {
			my $text_item = $canvas->get_item( $text_model );
			#say $text_model->{_t};
			$text_item->signal_connect(
				'button-press-event' => \&text_click_handler
			);
				#sub {
					#say "clicked text: ". $text_model->{_t};

					#return FALSE;
				#},

			#$text_item->signal_connect(
				#'motion-notify-event' => sub {
					#say "text: ". $text_model->{_t};

					#return FALSE;
				#},
			#);
		}
	}

	my $get_items_in_canvas_area = sub {
		my @items = $canvas->get_items_in_area(
			GooCanvas2::CanvasBounds->new(
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

package RenderModelRole {
	use Moo::Role;

	has [qw(doc page)] => (
		is => 'ro',
		required => 1,
	);
}

package PageImageRenderModel {
	use Moo;

	with qw(RenderModelRole);
}

package PageTextRenderModel {
	use Moo;

	with qw(RenderModelRole);
}

main;
