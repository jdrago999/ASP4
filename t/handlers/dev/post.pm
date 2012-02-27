
package dev::post;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;


sub run
{
  my ($s, $context) = @_;
  
  use Data::Dumper;
  $Response->Write( '<pre>' . Dumper($Form) . '</pre>' );
  my $upload = $Request->FileUpload('filename');
  $Response->Write( "<pre>" . Dumper( $upload ) . "</pre>" );
  $Response->Write( "<h3>Contents:</h3><pre>" . $upload->FileContents . "</pre>" );
}# end run()

1;# return true:

