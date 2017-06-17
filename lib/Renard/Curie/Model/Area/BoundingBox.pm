use Renard::Curie::Setup;
package Renard::Curie::Model::Area::BoundingBox;
# ABSTRACT: Bounding box representation

use Moo;

has polygon => (
	is => 'lazy',
);

1;
