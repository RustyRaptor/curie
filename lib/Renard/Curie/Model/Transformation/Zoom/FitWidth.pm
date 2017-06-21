package Renard::Curie::Model::Transformation::Zoom::FitWidth;
# ABSTRACT: Zoom so that the width fits the container

use Moo;
use MooX::Lsub;

lsub fit_wdith  => sub { 1 };
lsub fit_height => sub { 0 };

with qw( Renard::Curie::Model::Transformation::Zoom::Role::ContainerConstrainable );

1;
