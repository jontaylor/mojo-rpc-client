package MojoRPC::Client::Object;
use Mojo::Base -base;
use MojoRPC::Client;
use MojoRPC::Client::RequestPathBuilder;
use Want;
use vars '$AUTOLOAD';

has [qw( _class _base_url _api_key last_request _object_class )];
# has _chain => sub { MojoRPC::Client::RequestPathBuilder->new() };

sub _new {
  my $class = shift;
  return $class->SUPER::new(@_);
}

# We don't actually want to polute this package with the new() from mojo
sub new {
  my $self = shift;

  return $self->_handle_method_call(
    { method => 'new', parameters => \@_, wants => wantarray ? '@' : '$', call_type => '->'  },
    { 'OBJECT' => want('OBJECT'),  }
  );
}

sub no_op {
  return shift;
}

sub _client {
  my $self = shift;
  return MojoRPC::Client->new({
      base_url => $self->_base_url,
      api_key => $self->_api_key,
      object_class => $self->_object_class
  });
}

sub _merge {
  my $self = shift;
  my $attributes = shift;
  $self->{_attributes} = [];
  foreach my $attribute(keys %$attributes) {
    unless($self->can($attribute)) {
      $self->attr($attribute);
      $self->$attribute( $attributes->{$attribute} );
      push @{$self->{_attributes}}, $attribute;
    }
  }
  return $self;
}


sub _chain {
  my $self = shift;

  unless($self->{_chain}) {

    $self->{_chain} = MojoRPC::Client::RequestPathBuilder->new(
      base_url => $self->_base_url,
      class_name => $self->_class
    );
      
    if($self->can('_default_chain')) {
      my $default_chain = $self->_default_chain();
      unless(ref($default_chain) eq "MojoRPC::Client::RequestPathBuilder") {
        $default_chain = $default_chain->_chain() if $default_chain->can('_chain');
      }
      $self->{_chain} = $default_chain if $default_chain;
    }

  }

  return $self->{_chain};
}

sub _handle_method_call {
  my $self = shift;
  my $args = shift;
  my $wants = shift;

  #We always need the new object, either to return it, or to execute its chain
  my $new_object = $self->_clone();

  $new_object->_add_to_chain($args);

  unless ($wants->{'OBJECT'} ) {
    #Lets end the chain
    my $result = $new_object->_execute_chain();

    
    if($result->{class}) { 
      #We got an object back anyway, so lets give the user an object of the right kind
      bless $new_object, MojoRPC::Client::object_class_to_use($result->{class}, $self->_object_class);
      $new_object->init() if $new_object->can('init');
      #$new_object->begin_new_chain() if $new_object->can('begin_new_chain');
      return $new_object; 
    }
    #Need to be careful with this, do we need to do differently if the user expected an array?
    if($args->{wants} eq "@" && ref($result->{data}) eq "ARRAY") {
      return ( @{$result->{data}} );
    }
    else {
      return $result->{data};
    }  
  }

  return $new_object; #They wanted an object, so lets just chain (we can't make it the right type because we don't know what it is yet
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

  # $self->_chain->class_name($self->_class);

  my $request_object = MojoRPC::Client::Request->new({
    api_key => $self->_api_key,
    base_url => $self->_base_url,
    request_path_builder => $self->_chain
  });
  return $request_object;
}

sub _clone {
  my $self = shift;

  my $clone = MojoRPC::Client::Object->_new(
    _class => $self->_class, #Be warned this refers to the originator of this chain
    _api_key => $self->_api_key, 
    _base_url => $self->_base_url, 
    _chain => $self->_chain->clone(), #Clone the chain
    _object_class => $self->_object_class
  );

  return $clone;
}

sub _add_to_chain {
  my $self = shift;
  my $args = shift;

  $self->_chain->add_to_chain($args);

  return $self; #So that we can keep chaining
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

  return $self->_handle_method_call(
    { method => $method, parameters => \@_, wants => wantarray ? '@' : '$', call_type => '->'  },
    { 'OBJECT' => want('OBJECT'),  }
  );

}

sub DESTROY {}

1;