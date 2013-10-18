use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Data::Dumper;
use MojoRPC::Client;
use lib 't/lib';




my $client = MojoRPC::Client->new({
  object_class => sub {
    return "TestClass::ModuleThatWontCompile";
  }
});


like(exception { $client->object_class_to_use('anything') },
 qr/TestClass::ModuleThatWontCompile cannot be found, it either doesn't exist, or does not compile/,
 "Fails as expected");

done_testing();

