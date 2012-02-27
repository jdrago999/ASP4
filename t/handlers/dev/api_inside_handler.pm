
package dev::api_inside_handler;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;
use ASP4::API;

sub run
{
  my ($s, $context) = @_;
  
  $Response->Write(
    $Response->TrapInclude(
      $Server->MapPath("/handlers/dev.speed")
    )
  );
  
}# end run()

1;# return true:

