package Renard::Curie::Model::Transformation::Zoom::FitPage;
# ABSTRACT: Zoom so that both the height and width fit the container

use Moo;
use Renard::Curie::Types qw(Bool);
use MooX::Lsub;

lsub fit_wdith  => sub { 1 };
lsub fit_height => sub { 1 };

with qw( Renard::Curie::Model::Transformation::Zoom::Role::ContainerConstrainable );

1;
