
package My::SEOFilter;

use strict;
use warnings 'all';
use base 'ASP4::RequestFilter';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  if( my ($id) = $context->cgi->request_uri =~ m{/seo/(\d+)/} )
  {
    return $Request->Reroute("/seo-page/?id=$id");
  }
  elsif( my ($chars) = $context->cgi->request_uri =~ m{/seo2/(abc)/} )
  {
    return $Request->Reroute("/handlers/dev.seo_handler?chars=$chars");
  }# end if()
}# end run()

1;# return true:

