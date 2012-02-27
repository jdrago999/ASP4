
package ASP4::HeadersOut;

use strict;
use warnings 'all';

sub new { bless { headers => [ ] }, shift }
sub headers { @{shift->{headers}} }
sub psgi_headers {
  my $s = shift;
  
  [ map { @$_ } $s->headers ];
}
sub header {
  my ($s, $name) = @_;
  
  grep { lc($_) eq lc($name) } $s->headers;
}
sub add_header {
  my ($s, $header, $value) = @_;
  
  push @{ $s->{headers} }, [ $header => $value ];
}
sub set_header {
  my ($s, $header, $value) = @_;
  my @new = grep { lc($_->[0]) ne lc($header) } @{ $s->{headers} };
  push @new, [ $header => $value ];
  $s->{headers} = \@new;
}

1;# return true:

