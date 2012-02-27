
package dev::login;

use VSO asa => 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  $Session->{user_id}++;
  $Session->save;
  $Response->Redirect('/member.asp?.r=' . rand());
}

1;# return true:

