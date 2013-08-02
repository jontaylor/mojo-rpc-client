package MojoRPC::Client::Request;
use Mojo::Base -base;
use HTTP::Request;
use MIME::Base64;
use JSON::XS;
use LWP;
use URI;
use Carp;
use Encode qw(encode);

has [qw( api_key request_path_builder debug)];

sub cache_key {
  my $self = shift;

  my ($path, $post_params) = $self->request_path_builder->build();
  return undef if $post_params;
  return $path;
}

sub send_request {
  my $self = shift;

  my ($path, $post_params) = $self->request_path_builder->build();
  my $http_request = HTTP::Request->new();
  $http_request->uri($path);

  if($post_params) {
    $http_request->method('POST');
    #Below should be converted to a string of bytes
    $http_request->content("params=$post_params");
    $http_request->header("Content-Type" => 'application/x-www-form-urlencoded; charset="utf8"');
  }
  else {
    $http_request->header("Content-Type" => 'application/json; charset="utf8"');
    $http_request->method('GET');
  }



  if($self->debug) {
    use Data::Dumper;
    print STDERR Dumper $path;
  }

  $http_request->header(Authorization => "Basic " . encode_base64($self->api_key()));

  my $response = $self->user_agent->request($http_request);

  unless($response->is_success()) {
    croak "MojoRPC Request failed with " . $response->status_line . "\n" . $response->content;
  }

  return $response;
}

sub parse_response {
  my $self = shift;
  my $response = shift;

  my $json = JSON::XS->new->allow_nonref->utf8(1);
  my $data;
  eval {
    $data = $json->decode($response->content) ;
  };

  if($@) {
    if($@ =~ /malformed JSON string/) {
      croak "Received a message from the server instead of JSON: " . $response->content;
    }
    croak $@;
  }

  return $data;
}

sub user_agent {
  my $self = shift;
  return $self->{user_agent} if defined $self->{user_agent};
  $self->{user_agent} = LWP::UserAgent->new;
  $self->{user_agent}->agent("MojoRPC::Client $MojoRPC::Client::VERSION");
  return $self->{user_agent};
}

1;