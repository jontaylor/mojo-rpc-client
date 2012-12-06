package MojoRPC::Client::Response;

require HTTP::Response;
@ISA = qw(HTTP::Response);
use Carp;


sub code_in {
  my $self = shift;
  my @codes_to_test = $self->_pre_process_codes(@_);

  my $actual_code = $self->code;

  foreach my $code ( @codes_to_test ) {
    return 1 if $code == $actual_code;
  }

  return 0;
}

sub code_not_in {
  my $self = shift;

  return not $self->code_in(@_);
}

sub _pre_process_codes {
  my $self = shift;
  my @codes = @_;
  my @processed_codes;

  foreach my $code(@codes) {
    if($code =~ /\d\d\d/) { 
      push @processed_codes, $code;
      next;
    }

    if($code =~ /(\d)XX/) {
      my $start_range = $1*100;
      my $end_range = $start_range + 99;
      push @processed_codes, ( $start_range..$end_range );
    }

    croak "Invalid code to test against, must be a list of 3 digit numbers, or with wildcards eg 5XX";
  }

  return @processed_codes;

}

1;