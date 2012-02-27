
package ASP4::PSGI;

use strict;
use warnings 'all';
use Plack::Request;
use IO::Scalar;


sub app
{
  return sub {
    my $env = shift;
    
    require ASP4::API;
    my $context = ASP4::HTTPContext->new();
    if( $::original_uri )
    {
      $env->{REQUEST_URI} = $::original_uri;
      (undef, $env->{QUERY_STRING}) = split /\?/, $::original_uri;
    }# end if()
    $context->setup_request( $env );
    $context->execute();
    
    # TODO: $context should be destroyed immediately upon scope exit so we don't
    # have to call its DESTROY method explicitly.
    my $response = $context->psgi_response;
    $context->DESTROY;
    return $response;
  };
}# end app()

1;# return true:

