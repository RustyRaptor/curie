#!/usr/bin/env perl

use Test::Most tests => 4;

use lib 't/lib';
use Renard::Curie::Setup;
use Renard::Curie::App;
use CurieTestHelper;
use Renard::Curie::Types qw(InstanceOf Enum);

my $cairo_doc = CurieTestHelper->create_cairo_document;

fun Scroll_Event( (InstanceOf['Renard::Curie::App']) $app,
		(Enum[qw(up down smooth)]) $direction,
		$delta = 0) {
	my $event = Gtk3::Gdk::Event->new('scroll');
	$event->state( 'control-mask' );
	$event->direction( $direction );
	if ( $direction eq 'smooth' ) {
		$event->delta_y( $delta );
	}
	$app->page_document_component->scrolled_window->signal_emit(
		'scroll-event' => $event );
}

subtest 'Check that ctrl+scroll-down zooms out of the page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->view->zoom_level - 1.0 < .001, 'Start at Zoom Level 1.0' );

	Scroll_Event( $app, 'down' );

	ok($page_comp->view->zoom_level - .95 < .001, 'Reduce Zoom Level to .95');

	$app->window->destroy;
};

subtest 'Check that ctrl+scroll-up zooms into the page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->view->zoom_level - 1.0 < .001, 'Start at Zoom Level 1.0' );

	Scroll_Event( $app, 'up' );

	ok($page_comp->view->zoom_level - 1.05 < .001, 'Reduce Zoom Level to .95');

	$app->window->destroy;
};

subtest 'Check that ctrl+smooth-scroll-down zooms out of the page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->view->zoom_level - 1.0 < .001, 'Start at Zoom Level 1.0' );

	Scroll_Event( $app, 'smooth', -0.05 );

	ok($page_comp->view->zoom_level - .95 < .001, 'Reduce Zoom Level to .95');

	$app->window->destroy;
};

subtest 'Check that ctrl+smooth-scroll-up zooms into the page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->view->zoom_level - 1.0 < .001, 'Start at Zoom Level 1.0' );

	Scroll_Event( $app, 'smooth', 0.05 );

	ok($page_comp->view->zoom_level - 1.05 < .001, 'Reduce Zoom Level to .95');

	$app->window->destroy;
};

done_testing;
