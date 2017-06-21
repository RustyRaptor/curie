use Renard::Curie::Setup;
package Renard::Curie::Model::Geometry::Position::Page;
# ABSTRACT: Represents a position in page coordinates

use Moo;
use Renard::Curie::Types qw(PageNumber PageSpaceCoordinates);

extends q(Renard::Curie::Model::Geometry::Position);

=attr page

The page number that the coordinates represent.

=cut
has page => ( is => 'ro', isa => PageNumber );

=attr coordinates

The coordinates in C<PageSpaceCoordinates>.

=cut
has coordinates => ( is => 'ro', isa => PageSpaceCoordinates );

1;
