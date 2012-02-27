
package ASP4::Response;

use strict;
use warnings 'all';
use HTTP::Date qw( time2str );

sub new { my $s = bless { }, shift; $s->ContentType('text/html'); $s; }

sub Status
{
  $_[0]->{Status} ||= 200;
  @_ == 1 ? $_[0]->{Status} : do { $_[0]->{Status} = int($_[1]) or die "Invalid Status: '$_[1]'" };
}# end Status()


sub ContentType
{
  my $s = shift;
  
  $s->{ContentType} ||= 'text/html';
  return $s->{ContentType} unless @_;
  
  $s->{ContentType} = shift;
  $s->context->headers_out->set_header( 'content-type' => $s->{ContentType} );

  $s->{ContentType};
}# end Status()


sub Expires
{
  $_[0]->{Expires} ||= time();
  @_ == 1 ? $_[0]->{Expires} : do {
    my $time;
    my $value = $_[1];
    if( my ($num,$type) = $value =~ m/^(\-?\d+)([MHD])$/ )
    {
      my $expires;
      if( $type eq 'M' ) {
        # Minutes:
        $expires = time() + ( $num * 60 );
      }
      elsif( $type eq 'H' ) {
        # Hours:
        $expires = time() + ( $num * 60 * 60 );
      }
      elsif( $type eq 'D' ) {
        # Days:
        $expires = time() + ( $num * 60 * 60 * 24 );
      }# end if()
      $time = $expires;
    }
    else
    {
      $time = $value;
    }# end if()
    
    $_[0]->{Expires} = $time;
    $_[0]->ExpiresAbsolute( time2str( $time ) );
    $value;
  };
}# end Status()


sub ExpiresAbsolute
{
  $_[0]->{ContentType} ||= time2str( $_[0]->Expires );
  @_ == 1 ? $_[0]->{ExpiresAbsolute} : do {
    $_[0]->{ExpiresAbsolute} = $_[1];
    $_[0]->context->headers_out->set_header( 'expires' => $_[1] );
    $_[1];
  };
}# end Status()

sub context { ASP4::HTTPContext->current }


sub Write
{
  my $s = shift;
  
  $s->context->rprint( @_ );
  return;
}# end Write()


sub End
{
  my $s = shift;
  
  context->did_end(1);
}# end End()


sub Flush { }


sub Clear
{
  shift->context->{buffer} = '';
}# end Clear()


sub IsClientConnected { 1 }


sub AddHeader
{
  my ($s, $name, $val) = @_;
  
  $s->context->headers_out->add_header( $name => $val );
}# end AddHeader()


sub SetHeader
{
  my ($s, $name, $val) = @_;
  
  $s->context->headers_out->set_header( $name => $val );
}# end AddHeader()


sub SetCookie
{
  my ($s, %args) = @_;
  
  $args{domain} ||= eval { $s->context->config->data_connections->session->cookie_domain } || $ENV{HTTP_HOST};
  $args{path}   ||= '/';
  my @parts = ( );
  push @parts, $s->context->server->URLEncode($args{name}) . '=' . $s->context->server->URLEncode($args{value});
  unless( $args{domain} eq '*' )
  {
    push @parts, 'domain=' . $s->context->server->URLEncode($args{domain});
  }# end unless()
  push @parts, 'path=' . $args{path};
  if( $args{expires} )
  {
    if( my ($num,$type) = $args{expires} =~ m/^(\-?\d+)([MHD])$/ )
    {
      my $expires;
      if( $type eq 'M' ) {
        # Minutes:
        $expires = time() + ( $num * 60 );
      }
      elsif( $type eq 'H' ) {
        # Hours:
        $expires = time() + ( $num * 60 * 60 );
      }
      elsif( $type eq 'D' ) {
        # Days:
        $expires = time() + ( $num * 60 * 60 * 24 );
      }# end if()
      push @parts, 'expires=' . time2str( $expires );
    }
    else
    {
      push @parts, 'expires=' . time2str( $args{expires} );
    }# end if()
  }# end if()
  $s->AddHeader( 'Set-Cookie' => join('; ', @parts) . ';' );
}# end SetCookie()


sub Headers
{
  my $s = shift;
  
  @{ $s->context->headers_out->psgi_headers };
}# end Headers()


sub Redirect
{
  my ($s, $url) = @_;
  
  $s->Clear;
  $s->Status( 301 );
  $s->Expires( "-24H" )
    unless $s->Expires;
  $s->SetHeader( Location => $url );
  $s->End;
  return $s->Status;
}# end Redirect()


sub Declined { -1 }


sub Include
{
  my ($s, $file, $args) = @_;
  
  $s->Write( $s->_subrequest( $file, $args ) );
}# end Include()


sub TrapInclude
{
  my ($s, $file, $args) = @_;
  
  return $s->_subrequest( $file, $args );
}# end TrapInclude()


sub _subrequest
{
  my ($s, $file, $args) = @_;
  
  my $root = $s->context->config->web->www_root;
  (my $uri = $file) =~ s/^\Q$root\E//;

  my $buffer;
  SCOPE: {
    my %env = %{ $s->context->env };

    $env{REQUEST_URI} = $uri;
    $env{SCRIPT_NAME} = $uri;
    $env{SCRIPT_FILENAME} = $file;
    my $context = ASP4::HTTPContext->new( is_subrequest => 1 );
    local $ASP4::HTTPContext::_instance = $context;
    $context->setup_request( \%env );
    $context->execute( $args, 1 );
    $s->Flush;
    
    $buffer = $s->context->buffer;
  };
  return $buffer;
}# end _subrequest()

1;# return true:

