#!/usr/bin/env perl
# ABSTRACT: A model/view-based GooCanvas

use Gtk3 qw(-init);
use Glib qw(TRUE FALSE);
use Modern::Perl;
use feature 'current_sub';

use lib '/home/zaki/sw_projects/project-renard/p5-Renard-Incunabula-Format-PDF/p5-Renard-Incunabula-Format-PDF/lib';
use lib '/home/zaki/sw_projects/project-renard/p5-Renard-Incunabula-Frontend-Gtk3-GooCanvas2/p5-Renard-Incunabula-Frontend-Gtk3-GooCanvas2/lib';

use Renard::Incunabula::Format::PDF::Document;
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Frontend::Gtk3::Helper;
use Renard::Incunabula::Frontend::Gtk3::GooCanvas2;
#use GooCanvas2;

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
	my $layers = [];

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

	$canvas->signal_connect(
		'button-press-event' => sub {
			my ($canvas, $button) = @_;
			use DDP; p $button;
			say $button->x;
			say $button->y;
			my $r_tree = sub {
				my ($item) = @_;
				my $new_bounds = GooCanvas2::CanvasBounds->new;
				$item->update(TRUE, $canvas->create_cairo_context, $new_bounds);
				my $data = {
					item => $item,
					item_model => $item->get_model,
					bounds => [
						$item->get_bounds->x1,
						$item->get_bounds->y1,
						$item->get_bounds->x2,
						$item->get_bounds->y2,
					],
					position => [
						$item->get('x'),
						$item->get('y'),
						$item->get('width'),
						$item->get('height'),
					],
				};
				if( $item->can('get_n_children') ) {
					for my $cn (0..$item->get_n_children-1) {
						my $child = $item->get_child($cn);
						my $bounds = $child->get_bounds;
						my $contains
							=  $bounds->x1 <= $button->x
							&& $button->x <= $bounds->x2
							&& $bounds->y1 <= $button->y
							&& $button->y <= $bounds->y2;
						if($contains){
							push @{ $data->{children_in_bounds} },
								__SUB__->($item->get_child($cn))
						} else {
							push @{ $data->{children_out_bounds} },
								__SUB__->($item->get_child($cn))
						}
					}
				}

				$data;
			};
			my @area_items_children = map {
				$r_tree->($_);
			} $canvas->get_root_item;
			use DDP; p $area_items_children[-1];

			my @at_items = map { $_->get_model // $_ } $canvas->get_items_at(
				$button->x, $button->y,
				FALSE,
			);
			my @area_items = map { $_->get_model // $_ } $canvas->get_items_in_area(
				GooCanvas2::CanvasBounds->new(
					x1 => $button->x,
					x2 => $button->x,
					y1 => $button->y,
					y2 => $button->y,
				),
				TRUE,
				TRUE,
				TRUE,
			);
			use DDP; p @at_items;
			use DDP; p @area_items;

			say 'on the canvas';
		},
	);

	#Glib::Timeout->add(2000, sub {
		#my $event = Gtk3::Gdk::Event->new('button-press');
		#$event->x(188);
		#$event->y(76),
		#$canvas->signal_emit( 'button-press-event',
			#$event
		#);
		#exit 0;
	#});

	my $root = GooCanvas2::CanvasGroup->new;

	my $doc = Renard::Incunabula::Format::PDF::Document->new(
		filename => Renard::Incunabula::Devel::TestHelper
			->test_data_directory
			->child(qw(PDF Adobe pdf_reference_1-7.pdf)),
	);


	my $table = GooCanvas2::CanvasTable->new(
		'column-spacing' => 10,
		'row-spacing' => 10,
	);

	my $add_child_to_row_column = sub {
		my ($table, $child_item, $row, $column) = @_;
		$table->add_child($child_item, -1 );
		$table->set_child_property($child_item, 'row', $row );
		$table->set_child_property($child_item, 'column', $column);
	};

	for my $page_number (1..4) {
		my $group = GooCanvas2::CanvasTable->new;
		my $pir = PageImageRender->new( doc => $doc, page => $page_number );
		#my $ptr = PageTextRender->new( doc => $doc, page => $page_number );

		$group->add_child( $pir->item, -1 );
		#$group->add_child( $ptr->item, -1 );

		$layers->[$page_number]{image} = $pir;
		#$layers->[$page_number]{text} = $ptr;

		$table->$add_child_to_row_column($group,
			int(($page_number-1) / 2), ($page_number-1) % 2);
	}

	$root->add_child($table, -1);
	$canvas->set_root_item($root);
	$canvas->set_property( 'has-tooltip' => TRUE );

	#my $bounds_update = sub {
		#my ($item) = @_;

		#my $new_bounds = GooCanvas2::CanvasBounds->new;
		#$item->update(TRUE, $canvas->create_cairo_context, $new_bounds);

		#if( $item->can('get_n_children') ) {
			#for my $cn (0..$item->get_n_children-1) {
				#my $child = $item->get_child($cn);
				#__SUB__->($child);
			#}
		#}
	#};

	#$bounds_update->($canvas->get_root_item);

	my $bs = sub {
		my ($bounds) = @_;
		"[ @{[ $bounds->x1 ]}, @{[ $bounds->y1 ]}, @{[ $bounds->x2 ]}, @{[ $bounds->y2 ]} ]";
	};
	for my $layer (@$layers) {
		next unless $layer;

		#my $tml = $layer->{text}->item_model;
		#say "Page number: ",  $layer->{text}->page;

		#my $til = $layer->{text}->item;
		#my $til = $canvas->get_item($tml);

		#say "Before: ", $til->get_bounds->$bs();
		#my $new_bounds = GooCanvas2::CanvasBounds->new;
		#$til->update(TRUE, $canvas->create_cairo_context, $new_bounds);
		#say "After ", $til->get_bounds->$bs();
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

package AsGooCanvasItem {
	use Moo::Role;

	requires 'item';
}

package RenderRole {
	use Moo::Role;

	has [qw(doc page)] => (
		is => 'ro',
		required => 1,
	);
}

package PageImageRender {
	use Moo;
	use MooX::Lsub;
	use Function::Parameters;

	lsub _image_for_page => method() {
		my $doc = $self->doc;
		my $page_number = $self->page;

		say "Creating image model for $page_number";
		my $page = $doc->get_rendered_page( page_number => $page_number );
		my $surface = $page->cairo_image_surface;
		my $pixbuf = Gtk3::Gdk::pixbuf_get_from_surface(
			$surface,
			0, 0,
			$surface->get_width, $surface->get_height,
		);

		my $image = GooCanvas2::CanvasImage->new(
			width => $page->width,
			height => $page->height,
			pixbuf => $pixbuf,
		);

		$image;
	};

	lsub item => method() {
		my $page_layer =  GooCanvas2::CanvasTable->new;

		my $doc = $self->doc;
		my $page_number = $self->page;

		$page_layer->set('width', $self->_image_for_page->get('width'));
		$page_layer->set('height', $self->_image_for_page->get('height'));

		$page_layer->add_child( $self->_image_for_page, 0 );
		say $page_layer->get('height');
		say $page_layer->get('width');

		$page_layer;
	};

	with qw(RenderRole AsGooCanvasItem);
}

package PageTextRender {
	use Moo;
	use MooX::Lsub;
	use Function::Parameters;
	use Data::DPath qw(dpathi);

	lsub item => method() {
		my $page = $self->doc->get_rendered_page( page_number => $self->page );

		my $text_layer = GooCanvas2::CanvasGroup->new;
		$text_layer->set('width', $page->width);
		$text_layer->set('height', $page->height);

		say "Retrieving text for @{[ $self->page ]}";
		my $stext = Renard::Incunabula::MuPDF::mutool::get_mutool_text_stext_xml(
			$self->doc->filename,
			$self->page,
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

			#my $text_as_text = GooCanvas2::CanvasText->new(
				#text => $text,
				#font => $font,

				#x => $x1, y => $y1,
				#width => $x2 - $x1,
				#height => -1,

				#tooltip => 'Something or other',
				#'fill-color' => 'blue',
			#);

			my $text_as_rect = GooCanvas2::CanvasRect->new(
				x => $x1, y => $y1,
				width => $x2 - $x1,
				height => $y2 - $y1,

				#'line-width' => 0,
				'stroke-color' => 'red',
				'fill-color-gdk-rgba' => Gtk3::Gdk::RGBA->new(1,1,0,0.25),
			);

			my $text_item = $text_as_rect;


			$text_item->{_s} = $value;
			$text_item->{_t} = $text;

			$text_layer->add_child( $text_item, 0 );

			#$text_concat .= $value->{c};
			#$text_concat .= $value->{bbox};
			#$text_concat .= $value->{x};
			#$text_concat .= $value->{y};

		}

		$text_layer;
	};

	with qw(RenderRole AsGooCanvasItem);
}

main;
