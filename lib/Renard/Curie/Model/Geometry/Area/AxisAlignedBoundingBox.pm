use Renard::Curie::Setup;
package Renard::Curie::Model::Geometry::Area::AxisAlignedBoundingBox;
# ABSTRACT: Bounding box representation

use Moo;
use Renard::Curie::Types qw(Length);

has width => (
	is => 'ro',
	isa => Length,
);

has height => (
	is => 'ro',
	isa => Length,
);

1;
