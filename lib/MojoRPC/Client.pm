package MojoRPC::Client;

use 5.010000;
use strict;
use warnings;
use Mojo::Base -base;
use MojoRPC::Client::Query;
use MojoRPC::Client::Request;
use MojoRPC::Client::Response;
use Carp;

our $VERSION = '0.05';

has [qw(base_url api_key last_request debug )];
has object_class => "MojoRPC::Client::Object";
has caching => 0;
has chi => sub { CHI->new( driver => 'Memory', global=>1, expires_in => 60 ) };
has timeout => 10;

sub call {
  my $self = shift;
  my $class_name = shift;
  
  return MojoRPC::Client::Query->_new( { _class => $class_name,  _client => $self } );
}

sub factory {
  my $self = shift;
  my $remote_class_name = shift;
  my @data = @_;

  my $local_class_name = $self->object_class_to_use($remote_class_name);

  my $object = $local_class_name->_new();
  $object->mojo_rpc_client($self);
  $object->remote_class_name( $remote_class_name );
  $object->init(@data) if $object->can('init');

  return $object;
}

sub without_cache_do {
  my $self = shift;
  my $sub = shift;

  my $original_caching = $self->caching();
  $self->caching(0);
  if(wantarray) {
    my @response = $sub->(); 
    $self->caching($original_caching);
    return @response;
  }
  else {
    my $response = $sub->();
    $self->caching($original_caching);
    return $response;
  }
}

sub with_timeout_do {
  my $self = shift;
  my $timeout = shift;
  my $sub = shift;

  my $original_timeout = $self->timeout();
  $self->timeout($timeout);
  if(wantarray) {
    my @response = $sub->(); 
    $self->timeout($original_timeout);
    return @response;
  }
  else {
    my $response = $sub->();
    $self->timeout($original_timeout);
    return $response;
  }  
}


sub _send_request {
  my $self = shift;
  my $request_object = shift;

  my $cache_key = $request_object->cache_key;

  if($self->caching && $self->chi && $cache_key) {
    my $response = $self->chi->get($cache_key);
    if(! defined $response) {
      $response = $request_object->send_request();
      $self->chi->set($cache_key, $response);
    }
    return $response;
  }

  return $request_object->send_request();
}

sub execute_chain {
  my $self = shift;
  my $chain = shift;

  $chain->base_url($self->base_url);

  my $request_object = MojoRPC::Client::Request->new({
    api_key => $self->api_key,
    request_path_builder => $chain,
    debug => $self->debug,
    timeout => $self->timeout,
  });

  $self->last_request( bless($self->_send_request($request_object), 'MojoRPC::Client::Response') );

  my $result = $request_object->parse_response($self->last_request());

  if($result->{class}) { 
    #We got an object back anyway, so lets give the user an object of the right kind
    my $new_object = $self->factory( 
      $result->{class},
      $result->{data}
    );
    return $new_object; 
  }
  #Need to be careful with this, do we need to do differently if the user expected an array?
  if($chain->wants_list && ref($result->{data}) eq "ARRAY") {
    return ( @{$result->{data}} );
  }
  else {
    return $result->{data};
  }  

}

#A class method to work out which class to use for making objects
sub object_class_to_use {
  my $self = shift;
  my $remote_class_name = shift;
  my $override = $self->object_class;

  my $class_name = "MojoRPC::Client::Object";

  if(ref($override) eq "HASH") {
    $class_name = $override->{$remote_class_name} || $class_name;
  }

  if(ref($override) eq "CODE") {
    $class_name = $override->($remote_class_name) || $class_name;
  }

  unless(ref($override)) {
    $class_name = $override || $class_name;
  }

  eval "require $class_name" or croak "$class_name cannot be found, it either doesn't exist, or does not compile";
  return $class_name;
}




1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MojoRPC::Client - Perl extension for blah blah blah

=head1 SYNOPSIS

  use MojoRPC::Client;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for MojoRPC::Client, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jonathan Taylor, E<lt>jon@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jonathan Taylor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
