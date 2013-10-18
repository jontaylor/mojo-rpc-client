package TestClass::ModuleThatWontCompile;
use Mojo::Base 'MojoRPC::Client::Object';

use ModuleThatDoesNotExist;

sub init {
  my $self = shift;
  $self->SUPER::init(@_);


  return $self;
}

sub test_method {
  return "Method Exists";
}

0;