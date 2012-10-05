package MojoRPC::Client::Request;
use Mojo::Base -base;
use HTTP::Request;
use MIME::Base64;
use JSON::XS;
use LWP;
use URI;
use Carp;
use MojoRPC::Client::Object;

has [qw( base_url api_key request_path_builder )];

sub send_request {
  my $self = shift;

  $request_path_builder->base_url($self->base_url); #Start to get spaghetti ish
  my $http_request = HTTP::Request->new(GET => $self->request_path_builder->build );
  $http_request->header(Authorization => "Basic " . encode_base64($self->api_key()));

  my $response = $self->user_agent->request($http_request);

  unless($self->response->is_success()) {
    carp "Request failed with " . $self->response->status_line;
    return undef;
  }

  $response = $self->parse_response($response);

  return $response;
}

sub parse_response {
  my $self = shift;
  my $response = shift;

  my $json = JSON::XS->new->allow_nonref;
  my $data = $json->decode($self->response->content) ;

  if($data->{class}) {
    my $object = MojoRPC::Client::Object->new({  
      _class => $data->{class}, _api_key => $self->api_key, _base_url => $self->base_url, _chain => $self->request_path_builder
    });
    return $object;
  }
  return $data->{data};
}

sub user_agent {
  my $self = shift;
  return $self->{user_agent} if defined $self->{user_agent};
  $self->{user_agent} = LWP::UserAgent->new;
  $self->{user_agent}->agent("MojoRPC::Client $MojoRPC::Client::VERSION");
  return $self->{user_agent};
}

1;