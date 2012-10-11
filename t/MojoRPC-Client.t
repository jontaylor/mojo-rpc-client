# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MojoRPC-Client.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Data::Dumper;
BEGIN { use_ok('MojoRPC::Client'); use_ok('MojoRPC::Client::Object') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $objects = [ { id => 1, name => "a" }, { id => 2, name => "b" } ];



my $object = MojoRPC::Client::Object->_new();
$object->_merge($objects->[1]);
is( $object->id(), 2 );
is( $object->name(), 'b' );

$object = MojoRPC::Client::Object->_new();

$object->init($objects->[0]);
is( $object->id(), 1 );
is( $object->name(), 'a' );



my $client = new_ok('MojoRPC::Client' => [ base_url => "http://localhost:8000", api_key => 'un:pw' ] );


my $remote_class = $client->factory('Remote::Class');

my @remote_class_objects = $remote_class->_new_array_of_objects($objects);



is( ref($remote_class_objects[0]), 'MojoRPC::Client::Object');


is( $remote_class_objects[0]->id(), 1 );
is( $remote_class_objects[1]->id(), 2 );
is( $remote_class_objects[0]->name(), "a" );
is( $remote_class_objects[1]->name(), "b" );

done_testing();