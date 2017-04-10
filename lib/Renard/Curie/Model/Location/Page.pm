use Renard::Curie::Setup;
package Renard::Curie::Model::Location::Page;
# ABSTRACT: Represents a location in page coordinates

use Moo;
use Renard::Curie::Types qw(PageNumber PageSpaceCoordinates);

=attr page

The page number that the coordinates represent.

=cut
has page => ( is => 'ro', isa => PageNumber );

=attr coordinates

The coordinates in C<PageSpaceCoordinates>.

=cut
has coordinates => ( is => 'ro', isa => PageSpaceCoordinates );

1;
