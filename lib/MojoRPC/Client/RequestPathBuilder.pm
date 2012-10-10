package MojoRPC::Client::RequestPathBuilder;
use Mojo::Base -base;
use MojoRPC::Client::MethodCall;
use JSON::XS;
use URI::Escape;

#We use JSON here for convenience in generating the path

has chain => sub { [] };
has [qw( base_url class_name )];

sub wants_list {
  my $self = shift;

  return 1 if $self->chain->[-1]->{wants} eq "@";
}

#Should complain if you try and add to a chain thats last item wants an array
sub add_to_chain {
  my $self = shift;
  my $args = shift;

  push @{$self->chain}, MojoRPC::Client::MethodCall->new(
    method => $args->{method}, parameters => $args->{parameters},
    call_type => $args->{call_type}, wants => $args->{wants}
  );
}

#Put it all together
sub build {
  my $self = shift;

  my $path = $self->base_url;
  $path =~ s/\/+$//;
  $path .= '/call/json/';
  $path .= $self->class_name;
  $path .= '/';
  $path .= uri_escape_utf8($self->json_params);
  return $path;
}

sub json_params {
  my $self = shift;
  my @path = map { $_->path() } @{$self->chain};

  my $json = JSON::XS->new->allow_nonref();

  return $json->encode(\@path);
}

1;