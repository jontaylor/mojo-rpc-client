package MojoRPC::Client::Object;
use Mojo::Base -base;
use MojoRPC::Client::Query;

use vars '$AUTOLOAD';
has [qw( remote_class_name mojo_rpc_client )];


BEGIN {
  undef &new;
}

sub _new {
  my $self = shift;
  return $self->SUPER::new(@_);
}

sub _new_array_of_objects {
  my $self = shift;
  my $data = shift;
  my $class_name = shift || $self->remote_class_name;

  my @objects;
  foreach my $single_object(@$data) { 
    push @objects, $self->mojo_rpc_client->factory($class_name, $single_object);
  }

  return @objects;
}

sub init {
  my $self = shift;
  my $attributes = shift;

  $self->_merge($attributes);
}

sub _merge {
  my $self = shift;
  my $attributes = shift;
  $self->{_attributes} = [];
  foreach my $attribute(keys %$attributes) {
    unless($self->can($attribute)) {
      $self->attr($attribute);
    }  
    $self->{$attribute} = $attributes->{$attribute};
    push @{$self->{_attributes}}, $attribute;
    
  }
  return $self;
}

sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s{.*::}{};

  if($self->can('rpc_call')) {
    return $self->_rpc_call($method, @_);
  }
  else {
    die "Method: $method not found";
  }
}

#all this just to disable chaining once we are an object
sub _rpc_call {
  my $self = shift;
  my $method = shift;
  my $wantarray = shift;

  if($wantarray) {
    my @response = $self->rpc_call->$method(@_);
    return @response;
  }
  else {
    my $response = $self->rpc_call->$method(@_);
    return $response;
  }
}

sub _rpc_call {
  my $self = shift;
  my $method = shift;
  my $wantarray = shift;

  # return $self->mojo_rpc_client->call($self->remote_class_name, $self->rpc_call->$method(@_) );
  return $self->rpc_call($self->mojo_rpc_client)

}

sub DESTROY {}

1;