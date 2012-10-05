package MojoRPC::Client;

use 5.010000;
use strict;
use warnings;
use Mojo::Base -base;
use MojoRPC::Client::Package;
use MojoRPC::Client::Request;

our $VERSION = '0.01';

has [qw(base_url api_key)];

#Factory creates an Class of the specified type, which you can call methods on
sub factory {
  my $self = shift;
  my $class = shift;

  return MojoRPC::Client::Object->new({ _class => $class, _api_key => $self->api_key, _base_url => $self->base_url });
}

sub define {
  my $self = shift;
  my $class = shift;

  #CREATE the package named by $class
  #croak if the package already exists and isn't one of ours

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
