use Renard::Curie::Setup;
package Renard::Curie::Model::Geometry::Position::Global;
# ABSTRACT: Represents a position in global coordinates

use Moo;
use Renard::Curie::Types qw(GraphicsSpaceCoordinates);

extends q(Renard::Curie::Model::Geometry::Position);

=attr coordinates

The coordinates in C<GraphicsSpaceCoordinates>.

=cut
has coordinates => ( is => 'ro', isa => GraphicsSpaceCoordinates );

1;
