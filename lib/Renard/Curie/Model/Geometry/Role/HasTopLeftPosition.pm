package Renard::Curie::Model::Geometry::Role::HasTopLeftPosition;
# ABSTRACT: Role for positioning

use Moo::Role;
use Renard::Curie::Types qw(InstanceOf);

has top_left_position => (
	is => 'ro',
	isa => InstanceOf['Renard::Curie::Model::Geometry::Position'],
);


1;
