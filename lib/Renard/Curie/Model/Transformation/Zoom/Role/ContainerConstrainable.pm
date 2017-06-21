package Renard::Curie::Model::Transformation::Zoom::Role::ContainerConstrainable;
# ABSTRACT: Role for zoom types that are constrained by their container

use Moo::Role;
use Renard::Curie::Types qw(Bool);

has fit_wdith  => ( is => 'lazy', isa => Bool );
has fit_height => ( is => 'lazy', isa => Bool );

1;
