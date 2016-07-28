use Renard::Curie::Setup;
package Renard::Curie::Component::PageTextArea;

use Moo;
use Glib 'TRUE', 'FALSE';
use Glib::Object::Subclass 'Gtk3::Bin';

use Renard::Curie::Data::PDF;
use Data::DPath qw(dpathi);
use Function::Parameters;

has filename => ( is => 'rw' );
has page_number => ( is => 'rw' );
has clutter_gtk_embed => ( is => 'lazy' );

method _build_clutter_gtk_embed {
	Gtk3::Clutter::Embed->new;
}

classmethod FOREIGNBUILDARGS(@) {
	return ();
}

method BUILD {
	my $stage = $self->clutter_gtk_embed->get_stage;

	my $stext = Renard::Curie::Data::PDF::get_mutool_text_stext_xml(
		$self->filename,
		$self->page_number );

	my $root = dpathi($stext);
	my $char_iterator = $root->isearch( '/page/*/block/*/line/*/span/*/char/*' );
	my $group = Clutter::Actor->new;
	while( $char_iterator->isnt_exhausted ) {
		my $char_hash = $char_iterator->value->deref;
		my $bbox = [ split ' ', $char_hash->{bbox} ];
		#my $actor = Clutter::Actor->new;
		my $actor = Clutter::Text->new;
		$actor->set_text( $char_hash->{c} );
		$actor->set_selectable( 1 );
		$actor->set_content_gravity('resize-aspect');
		$actor->set_reactive(TRUE);
		$actor->set_position( $bbox->[0], $bbox->[1] );
		$actor->set_size( $bbox->[2] - $bbox->[0], $bbox->[3] - $bbox->[1] );
		$actor->set_background_color(Clutter::Color::get_static('sky-blue-light'));
		$group->add_child( $actor );
	}
	$stage->add_child( $group );

	# add as child for this Gtk3::Bin
	$self->add(
		$self->clutter_gtk_embed
	);
}

1;
