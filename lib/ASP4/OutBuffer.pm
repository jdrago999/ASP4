
package
ASP4::OutBuffer;

use strict;
use warnings 'all';
use overload '""' => sub { shift->data }, fallback => 1;
sub new   { bless { data => '' }, shift }
sub data  { $_[0]->{data} }
sub add   { $_[0]->{data} .= $_[1] if defined $_[1]; }
sub empty { shift->{data} = '' }

1;# return true:

