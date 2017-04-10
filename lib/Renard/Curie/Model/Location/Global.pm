use Renard::Curie::Setup;
package Renard::Curie::Model::Location::Global;
# ABSTRACT: Represents a location in global coordinates

use Moo;
use Renard::Curie::Types qw(GraphicsSpaceCoordinates);

=attr coordinates

The coordinates in C<GraphicsSpaceCoordinates>.

=cut
has coordinates => ( is => 'ro', isa => GraphicsSpaceCoordinates );

1;
