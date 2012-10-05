package MojoRPC::Client::RequestPathBuilder;
use Mojo::Base -base;
use MojoRPC::Client::MethodCall;
use JSON::XS;

#We use JSON here for convenience in generating the path

has chain => [];
has [qw( base_url class_name )];

#Should complain if you try and add to a chain thats last item wants an array
sub add_to_chain {
  my $self = shift;
  my $args = shift;

  push @{$self->chain}, MojoRPC::Client::MethodCall->new(
    method_name => $args->{method_name}, parameters => $args->{parameters},
    call_type => $args->{call_type}, wants => $args->{wants}
  );
}

#Put it all together
sub build {
  
}

sub json_params {
  my $self = shift;
  my @path = map { $_->path() } @{$self->chain};

  my $json = JSON::XS->new->allow_non_ref();

  return $json->encode(\@path);
}

1;