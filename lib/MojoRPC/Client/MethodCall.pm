package MojoRPC::Client::MethodCall;
use Mojo::Base -base;

has [qw( method_name parameters call_type wants )];

sub path {
  my $self = shift;

  my $method_call  = $self->wants;
     $method_call .= $self->call_type;
     $method_call .= $self->method_name();
  
  return ($method_call, @{$self->parameters});
}

1;