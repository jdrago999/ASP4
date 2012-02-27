
package
ASP4::FilterResolver;
use strict;
use warnings 'all';

my %FilterCache = ( );

sub new { bless { }, shift }

sub context { ASP4::HTTPContext->current }

sub resolve_request_filters
{
  my ($s, $uri) = @_;
  
  my $doc_root = $s->context->config->web->www_root;
  my $key = "$doc_root:$uri";
  return @{$FilterCache{$key}} if $FilterCache{$key};
  $FilterCache{$key} = [
    grep {
      if( my $pattern = $_->{uri_match} )
      {
        $uri =~ m{^$pattern}
      }
      else
      {
        $uri eq $_->{uri_equals};
      }# end if()
    } @{ $s->context->config->web->request_filters }
  ];
  return @{$FilterCache{$key}};
}# end resolve_request_filters()

1;# return true:

