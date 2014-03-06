package MojoRPC::Client::Request;
use Mojo::Base -base;
use HTTP::Request;
use MIME::Base64;
use JSON::XS;
use LWP;
use URI;
use Carp;
use Encode qw(encode);
use HTTP::Message;
use Data::Dumper;

has [qw( api_key request_path_builder debug timeout gzip accept_raw)];

sub cache_key {
  my $self = shift;

  my ($path, $post_params) = $self->request_path_builder->build();
  return undef if $post_params;
  return $path;
}

sub should_request_gzip_response {
  my $self = shift;

  return 0 unless $self->gzip;
  return 1 if HTTP::Message::decodable() =~ /gzip/;

}

sub supports_raw {
  my $self = shift;
  return 0 unless $self->accept_raw;
  return 1;
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

  if($self->should_request_gzip_response) {
    $http_request->header('Accept-Encoding' => 'gzip');
  }

  if($self->supports_raw) {
    $http_request->header('Accept' => 'application/octet-stream');
  }

  $http_request->header("RPC-Timeout" => $self->timeout);


  if($self->debug) {
    print STDERR Dumper $path;
  }

  $http_request->header(Authorization => "Basic " . encode_base64($self->api_key()));

  my $response = $self->user_agent->request($http_request);

  unless($response->is_success()) {
    croak "MojoRPC Request failed with " . $response->status_line . "\n" . $response->decoded_content(charset => 'none') . "\nPath: $path" ;
  }

  return $response;
}

sub parse_response {
  my $self = shift;
  my $response = shift;

  return $response->decoded_content(charset => 'none') if $response->header('Content-Type') eq "application/octet-stream"; #Raw data doesn't need parsing

  my $json = JSON::XS->new->allow_nonref->utf8(1);
  my $data;
  eval {
    $data = $json->decode($response->decoded_content(charset => 'none')) ;
  };

  if($@) {
    if($@ =~ /malformed JSON string/) {
      croak "Received a message from the server instead of JSON: " . $response->decoded_content(charset => 'none');
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