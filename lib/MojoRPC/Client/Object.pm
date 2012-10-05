package MojoRPC::Client::Object;
use Mojo::Base -base;
use MojoRPC::Client::RequestPathBuilder;
use Want;
use vars '$AUTOLOAD';

has [qw( _class _base_url _api_key )];
has _chain => sub { MojoRPC::Client::RequestPathBuilder->new() };


#Build up the path builder as we go along (even if its only one level)
#Detect if we are the end of the chain and do the request

sub _finish_chain {
  my $self = shift;

  my $request_object = $self->_new_request_object();
  return $request_object->send_request();
}

sub _new_request_object {
  my $self = shift;
  my $request_object = MojoRPC::Client::Request->new({
    api_key => $self->_api_key,
    base_url => $self->_base_url,
    request_path_builder => $self->_chain
  });
  return $request_object;
}

sub _chain {
  my $self = shift;
  my $args = shift;

  $self->_chain->add_to_chain($args);

  return $self; #So that we can keep chaining
}


sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s{.*::}{};

  my $chain = $self->_chain({ method => $method, parameters => \@_, wants => wantarray ? '@' : '$', call_type => '->'  });
  unless (want('CODE')) {
    # if(want('LIST') {
    #   return $self->_finish_chain();
    # }
    # else {

    # }
    return $self->_finish_chain();  
  }

  return $chain;
}

sub DESTROY {}

1;