
package ASP4::ConfigNode;

use strict;
use warnings 'all';
use Carp 'confess';

sub new
{
  my ($class, %args) = @_;
  
  local $SIG{__DIE__} = \&confess;

  my $s = bless \%args, $class;
  foreach my $key ( grep { ref($s->{$_}) eq 'HASH' } keys %$s )
  {
    $s->{$key} = __PACKAGE__->new( %{ $s->{$key} } );
  }# end foreach()
  
  $s->init();
  return $s;
}# end BUILD()

sub init { }


sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  
  confess "Unknown method or property '$name'" unless exists($s->{$name});
  
  # Read-only:
  $s->{$name};
}# end AUTOLOAD()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

