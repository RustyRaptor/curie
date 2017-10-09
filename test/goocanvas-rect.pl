#!/usr/bin/env perl
# ABSTRACT: rect

use Gtk3 qw(-init);
use Glib qw(TRUE FALSE);
use Modern::Perl;

use Renard::Incunabula::Frontend::Gtk3::GooCanvas2;

sub on_button_press_rect { say "i'm a rect"; }
sub on_button_press_text { say "i'm a text"; }

sub main {
	# Create the window and widgets.
	my $window = Gtk3::Window->new('toplevel');
	$window->set_default_size(640, 600);
	$window->show;
	#$window->signal_connect( delete_event => \&on_delete_event );

	my $scrolled_win = Gtk3::ScrolledWindow->new;
	$scrolled_win->set_shadow_type( 'in' );
	$scrolled_win->show;
	$window->add($scrolled_win);

	my $canvas = GooCanvas2::Canvas->new;
	$canvas->set_size_request(600, 450);
	$canvas->set_bounds(0, 0, 1000, 1000);
	$canvas->show;
	$scrolled_win->add( $canvas );

	my $root = GooCanvas2::CanvasGroupModel->new;

	# Add a few simple items.
	my $rect_model = GooCanvas2::CanvasRectModel->new(
		parent => $root,
		x => 100,
		y => 100,
		width => 400,
		height => 400,
		"line-width", 10.0,
		"radius-x", 20.0,
		"radius-y", 10.0,
		"stroke-color", "yellow",
		"fill-color", "red",
		);

	my $text_model = GooCanvas2::CanvasTextModel->new(
		parent => $root,
		text => "Hello World",
		x => 300, y => 300, width => -1,
		anchor => 'center',
		"font", "Sans 24");
	$text_model->rotate(45, 300, 300);

	$canvas->set_root_item_model($root);

	# Connect a signal handler for the rectangle item.
	my $rect_item = $canvas->get_item($rect_model);
	$rect_item->signal_connect( 'button_press_event' => sub { say "noooo"; }  );
	my $text_item = $canvas->get_item($text_model);
	$text_item->signal_connect( 'button_press_event' => sub { say "whhhat"; } );

	use DDP; p $text_model->get_property( 'pointer-events' )->as_arrayref;

	# Pass control to the GTK+ main event loop.
	Gtk3::main();

	return 0;
}

main;
