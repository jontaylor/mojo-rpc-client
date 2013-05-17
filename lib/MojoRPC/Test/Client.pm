#Experimental Test Client

package MojoRPC::Test::Client;

use 5.010000;
use strict;
use warnings;
use Mojo::Base 'MojoRPC::Client';

has [qw(base_url api_key last_request debug )];
has object_class => "MojoRPC::Client::Object";
has caching => 0;
has chi => sub { };

sub set_call_response {
  my $self = shift;
  my $code_ref = shift;

  $self->{call} = $code_ref;
}

sub call {
  my $self = shift;
  
  return $self->{call}->();
}

sub factory {
  my $self = shift;
  my $remote_class_name = shift;
  my @data = @_;

  my $local_class_name = $self->object_class_to_use($remote_class_name);

  my $object = $local_class_name->_new();
  $object->mojo_rpc_client($self);
  $object->remote_class_name( $remote_class_name );
  $object->init(@data) if $object->can('init');

  return $object;
}

sub without_cache_do {
  my $self = shift;
  my $sub = shift;

  if(wantarray) {
    my @response = $sub->(); 
    return @response;
  }
  else {
    my $response = $sub->();
    return $response;
  }
}

1;
__END__
