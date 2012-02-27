
package My::LoggedInFilter;

use VSO asa => 'ASP4::RequestFilter';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  unless( $Session->{user_id} )
  {
    $Response->Expires( '-72H' );
    return $Response->Redirect( '/login.asp' );
  }# end unless()
  
  return $Response->Declined;
}# end run()

1;# return true:

