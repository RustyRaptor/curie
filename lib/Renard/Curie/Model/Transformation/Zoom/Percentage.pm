package Renard::Curie::Model::Transformation::Zoom::Percentage;
# ABSTRACT: Zoom by a fixed percentage

use Moo;
use Renard::Curie::Types qw(ZoomLevel);

has percentage => ( is => 'ro', isa => ZoomLevel );

1;
