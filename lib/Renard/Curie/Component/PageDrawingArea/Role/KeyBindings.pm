use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea::Role::KeyBindings;
# ABSTRACT: A role to setup the key bindings for a page drawing area

use Moo::Role;
use Gtk3;

=method setup_keybindings

  method setup_keybindings()

Sets up the signals to capture key presses on this component.

=cut
method setup_keybindings() {
	$self->signal_connect( key_press_event => \&on_key_press_event_cb, $self );
}

=callback on_key_press_event_cb

  callback on_key_press_event_cb($window, $event, $self)

Callback that responds to specific key events and dispatches to the appropriate
handlers.

=cut
callback on_key_press_event_cb($window, $event, $self) {
	if($event->keyval == Gtk3::Gdk::KEY_Page_Down){
		$self->view->set_current_page_forward;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Page_Up){
		$self->view->set_current_page_back;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Up){
		$self->decrement_scroll($self->scrolled_window->get_vadjustment);
	} elsif($event->keyval == Gtk3::Gdk::KEY_Down){
		$self->increment_scroll($self->scrolled_window->get_vadjustment);
	} elsif($event->keyval == Gtk3::Gdk::KEY_Right){
		$self->increment_scroll($self->scrolled_window->get_hadjustment);
	} elsif($event->keyval == Gtk3::Gdk::KEY_Left){
		$self->decrement_scroll($self->scrolled_window->get_hadjustment);
	}
}

requires 'increment_scroll';
requires 'decrement_scroll';

1;
