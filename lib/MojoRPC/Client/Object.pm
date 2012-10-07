package MojoRPC::Client::Object;
use Mojo::Base -base;
use MojoRPC::Client::RequestPathBuilder;
use Want;
use vars '$AUTOLOAD';

has [qw( _class _base_url _api_key last_request )];
has _chain => sub { MojoRPC::Client::RequestPathBuilder->new() };

sub _handle_method_call {
  my $self = shift;
  my $args = shift;
  my $wants = shift;

  #We always need the new object, either to return it, or to execute its chain
  my $new_object = $self->_add_to_chain($args);

  unless ($wants->{'OBJECT'} ) {
    my $result = $new_object->_execute_chain();
    #They might want an object anyway if the data that comes back was an object
    if($result->{class}) { 
      #We should really do some kind of merging the params in here
      return $new_object; 
    }
    return $result->{data};
  }

  return $new_object;
}

sub _execute_chain {
  my $self = shift;

  my $request_object = $self->_new_request_object();

  $self->last_request( $request_object->send_request() );

  #Should probably raise an exception here instead... people might be expecting undef as a valid response type
  return undef unless $self->last_request->is_success();

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

  my $want_object = want('OBJECT');
  my $wantarray = wantarray;
  my @other_params = @_;

  my $sub = sub {
    return $self->_handle_method_call(
      { method => $method, parameters => \@other_params, wants => $wantarray ? '@' : '$', call_type => '::'  },
      { 'OBJECT' => $want_object,  }

    );
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

  my $chain = $self->_handle_method_call(
    { method => $method, parameters => \@_, wants => wantarray ? '@' : '$', call_type => '->'  },
    { 'OBJECT' => want('OBJECT'),  }
  );

  return $chain;
}

sub DESTROY {}

1;