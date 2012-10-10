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

sub init {
  my $self = shift;

  $self->_merge($self->{data});
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

sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s{.*::}{};

  if($self->can('rpc_call')) {
    return $self->rpc_call->$method(@_);
  }
  else {
    die "Method: $method not found";
  }
}

sub DESTROY {}

1;