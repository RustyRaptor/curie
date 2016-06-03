use Test::Most;

use lib 't/lib';
use Modern::Perl;
use Renard::Curie::App;
use Renard::Curie::Model::Document::PDF;
use CurieTestHelper;

my $cairo_doc = CurieTestHelper->create_cairo_document;

sub Key_Event{
	my ($app, $key) = @_;

	my $event = Gtk3::Gdk::Event->new('key-press');
	$event->keyval($key);
	$app->window->signal_emit( key_press_event => $event );
}

subtest 'Check that Page Down moves forward a page and Page Up moves back a page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	is($page_comp->current_page_number, 1, 'Start on page 1' );

	Key_Event($app, Gtk3::Gdk::KEY_Page_Down);
	is($page_comp->current_page_number, 2, 'On page 2 after hitting Page Down' );

	Key_Event($app, Gtk3::Gdk::KEY_Page_Up);
	is($page_comp->current_page_number, 1, 'On page 1 after hitting Page Up' );
};

subtest 'Check that up arrow scrolls up and down arrow scrolls down' => CurieTestHelper->run_app_with_document($cairo_doc, sub {
	my ( $app, $page_comp ) = @_;

	Glib::Timeout->add(200, sub {
		my $vadj = $page_comp->scrolled_window->get_vadjustment;
		my $current_value = $vadj->get_value;
		Key_Event($app, Gtk3::Gdk::KEY_Down);
		my $next_value = $vadj->get_value;
		cmp_ok( $current_value, '<', $next_value, 'Page has scrolled down');

		$current_value = $vadj->get_value;
		Key_Event($app, Gtk3::Gdk::KEY_Up);
		$next_value = $vadj->get_value;
		cmp_ok( $current_value, '>', $next_value, 'Page has scrolled up');

		$app->window->destroy;
	});
});

subtest 'Check that right arrow scrolls right and left arrow scrolls left' => CurieTestHelper->run_app_with_document($cairo_doc, sub {
	my ( $app, $page_comp ) = @_;

	Glib::Timeout->add(200, sub {
		my $hadj = $page_comp->scrolled_window->get_hadjustment;
		my $current_value = $hadj->get_value;
		Key_Event($app, Gtk3::Gdk::KEY_Right);
		my $next_value = $hadj->get_value;
		cmp_ok( $current_value, '<', $next_value, 'Page has scrolled right');

		$current_value = $hadj->get_value;
		Key_Event($app, Gtk3::Gdk::KEY_Left);
		$next_value = $hadj->get_value;
		cmp_ok( $current_value, '>', $next_value, 'Page has scrolled left');

		$app->window->destroy;
	});
});

done_testing;