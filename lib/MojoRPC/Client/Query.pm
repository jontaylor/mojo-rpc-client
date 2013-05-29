package MojoRPC::Client::Query;
use Mojo::Base -base;
use MojoRPC::Client;
use MojoRPC::Client::RequestPathBuilder;
use Want;
use vars '$AUTOLOAD';

has [qw( _client _class )];

BEGIN {
  undef &new;
}

sub _new {
  my $self = shift;
  return $self->SUPER::new(@_);
}

sub _add_to_chain {
  my $self = shift;
  my $args = shift;

  $self->_chain->add_to_chain($args);

  return $self; #So that we can keep chaining
}

sub _handle_method_call {
  my $self = shift;
  my $args = shift;
  my $wants = shift;

  $self->_add_to_chain($args);

  unless ($wants->{'OBJECT'} ) {
    #Lets end the chain
    return $self->_client->execute_chain($self->_chain());
  }

  return $self; #They wanted an object, so lets just chain (we can't make it the right type because we don't know what it is yet
}

sub no_op {
  shift
}

#Support class methods - The want object part might need to move inside the sub ref - If you get chaining bugs look there first
sub CLASS_METHOD {
  my $self = shift;
  my $method = shift;

  my $want_object = want('OBJECT');
  my $wantarray = wantarray;
  my @other_params = @_;

  my $sub = sub {
    @other_params = (@other_params, @_);

    return $self->_handle_method_call(
      { method => $method, parameters => \@other_params, wants => ($wantarray || wantarray) ? '@' : '$', call_type => '::'  },
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

sub _chain {
  my $self = shift;

  unless($self->{_chain}) {

    $self->{_chain} = MojoRPC::Client::RequestPathBuilder->new(
      class_name => $self->_class 
    );
      
  }

  return $self->{_chain};
}



#This is what lets us build up our call

sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s{.*::}{};

  return $self->_handle_method_call(
    { method => $method, parameters => \@_, wants => wantarray ? '@' : '$', call_type => '->'  },
    { 'OBJECT' => want('OBJECT'),  }
  );

}


sub DESTROY {}

1;