
package ASP4::Request;

use strict;
use warnings 'all';

sub new { bless { }, shift }

sub context { ASP4::HTTPContext->current }

sub QueryString
{
  my $s = shift;
  $s->{QueryString} ||= ( split /\?/, context->cgi->request_uri )[1];
  $s->{QueryString};
}# end QueryString()


sub Form
{
  my $s = shift;
  
  $s->{Form} ||= (sub {
    my $cgi = context->cgi;
    my $f = {
      (
        map {
          # CGI->Vars joins multi-value params with a null byte.  Which sucks.
          # To avoid that behavior, we do this instead:
          my @val = map { $cgi->unescape( $_ ) } ( $cgi->param($_) );
          $cgi->unescape($_) => scalar(@val) > 1 ? \@val : shift(@val)
        } grep { defined $_ } $cgi->param
      ),
      (
        map {
          # CGI->Vars joins multi-value params with a null byte.  Which sucks.
          # To avoid that behavior, we do this instead:
          my @val = map { $cgi->unescape( $_ ) } ( $cgi->url_param($_) );
          $cgi->unescape($_) => scalar(@val) > 1 ? \@val : shift(@val)
        } grep { defined $_ } $cgi->url_param
      )
    };
    return $f;
  })->();
  
  $s->{Form};
}# end Form()


sub Cookies
{ 
  my ($s, $name) = @_;
  $name ? $s->context->cgi->cookie( $name ) : $s->context->cgi->cookie;
}# end Cookies()


sub ServerVariables { $ENV{ $_[1] } }


sub FileUpload
{
  my ($s, $field) = @_;
  
  my $ifh = $s->context->cgi->upload($field)
    or return;
  my %info = ( );
  
  if( my $upInfo = $s->context->cgi->uploadInfo( $ifh ) )
  {
    my ($filename) = $upInfo->{'Content-Disposition'} =~ m{\bfilename\="(.+?)"}is;
    no warnings 'uninitialized';
    %info = (
      ContentType         => $upInfo->{'Content-Type'},
      FileHandle          => $ifh,
      FileName            => $filename,
      ContentDisposition  => $upInfo->{'Content-Disposition'},
    );
  }# end if()
  
  require ASP4::FileUpload;
  return ASP4::FileUpload->new( %info );
}# end FileUpload()


sub Reroute
{
  my ($s, $where) = @_;
  
  my ($uri, $args) = split /\?/, $where;
  $s->context->env->{SCRIPT_NAME} = $uri;
  
  # XXX: This is too naive.  We could be losing parameters - who knows?:
  $s->context->env->{QUERY_STRING} = $args if defined $args && length $args;
  if( defined $args )
  {
    for( split /&/, $args )
    {
      my ($k,$v) = split /\=/, $_;
      $s->context->cgi->param( $k => $v );
    }# end for()
  }# end if()
  delete $s->context->{request};
  
  return $s->context->response->Declined;
}# end Reroute()


sub Header
{
  my ($s, $name) = @_;
  
  return $s->context->headers_in->header( $name );
}# end Header()


1;# return true:

