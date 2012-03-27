
package
ASP4::HandlerResolver;

use strict;
use warnings 'all';
use ASP4::PageLoader;
my %HandlerCache = ( );


sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


sub context { ASP4::HTTPContext->current }


sub resolve_request_handler
{
  my ($s, $uri) = @_;
  
  ($uri) = split /\?/, $uri;
  
  return $HandlerCache{"$ENV{DOCUMENT_ROOT}:$uri"} if $HandlerCache{"$ENV{DOCUMENT_ROOT}:$uri"};
  
  if( $uri =~ m/^\/handlers\// )
  {
    (my $handler = $uri) =~ s/^\/handlers\///;
    $handler =~ s/[^a-z0-9_]/::/gi;
    (my $path = "$handler.pm") =~ s/::/\//g;
    my $filepath = $s->context->config->web->handler_root . "/$path";
    
    if( -f $filepath )
    {
      return $HandlerCache{"$ENV{DOCUMENT_ROOT}:$uri"} = $handler;
    }
    else
    {
      return;
    }# end if()
  }
  else
  {
    my $info = ASP4::PageLoader->discover( script_name => $uri );
    if( $info->{is_static} )
    {
      return $HandlerCache{"$ENV{DOCUMENT_ROOT}:$uri"} = 'ASP4::StaticHandler';
    }
    elsif( -f $info->{filename} )
    {
      my $page = ASP4::PageLoader->load( script_name => $uri );
      return $HandlerCache{"$ENV{DOCUMENT_ROOT}:$uri"} = $page->package;
    }
    else
    {
      return;
    }# end if()
  }# end if()
}# end resolve_request_handler()



1;# return true:

