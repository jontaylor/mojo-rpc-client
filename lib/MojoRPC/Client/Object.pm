package MojoRPC::Client::Object;
use Mojo::Base -base;
use MojoRPC::Client::RequestPathBuilder;
use Want;
use vars '$AUTOLOAD';

has [qw( _class _base_url _api_key last_request )];
has _chain => sub { MojoRPC::Client::RequestPathBuilder->new() };

# Look like what the use of this wants

use overload
  'nomethod' => '__catch_all';

# -> should go to the object as normal


# Delegate everything else to the normal return value (which might be $self?)
sub __catch_all {

}



sub _execute_chain {
  my $self = shift;

  my $request_object = $self->_new_request_object();

  $self->last_request( $request_object->send_request() );
  return $request_object->parse_response($self->last_request());
}

sub _new_request_object {
  my $self = shift;

  $self->_chain->class_name($self->_class);

  my $request_object = MojoRPC::Client::Request->new({
    api_key => $self->_api_key,
    base_url => $self->_base_url,
    request_path_builder => $self->_chain
  });
  return $request_object;
}

sub _add_to_chain {
  my $self = shift;
  my $args = shift;

  my $new_object = MojoRPC::Client::Object->new(
    _class => $self->_class, #Be warned this refers to the originator of this chain
    _api_key => $self->_api_key, 
    _base_url => $self->_base_url, 
    _chain => $self->_chain->clone() #Clone the chain
  );

  $new_object->_chain->add_to_chain($args);

  return $new_object; #So that we can keep chaining
}

sub CLASS_METHOD {
  my $self = shift;
  my $method = shift;

  my $sub = sub {
    return $self->_add_to_chain({ method => $method, parameters => \@_, wants => wantarray ? '@' : '$', call_type => '::'  });
  };

  if(want('CODE')) {
    return $sub;
  }
  else {
    return $sub->();
  }
}

sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s{.*::}{};

  my $chain = $self->_add_to_chain({ method => $method, parameters => \@_, wants => wantarray ? '@' : '$', call_type => '->'  });
  # unless (want('OBJECT')) {
  #   return $self->_execute_chain();  
  # }

  # return $self;
  return $chain;
}

sub DESTROY {}

1;