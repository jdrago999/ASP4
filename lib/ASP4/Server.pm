
package ASP4::Server;

use strict;
use warnings 'all';
use ASP4::Error;
use Mail::Sendmail;

sub new { bless { }, shift }

sub context { ASP4::HTTPContext->current }


sub URLEncode
{
  ASP4::HTTPContext->current->cgi->escape( $_[1] );
}# end URLEncode()


sub URLDecode
{
  ASP4::HTTPContext->current->cgi->unescape( $_[1] );
}# end URLDecode()


sub HTMLEncode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&/&amp;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/"/&quot;/g;
  $str =~ s/'/&#39;/g;
  return $str;
}# end HTMLEncode()


sub HTMLDecode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&lt;/</g;
  $str =~ s/&gt;/>/g;
  $str =~ s/&quot;/"/g;
  $str =~ s/&amp;/&/g;
  $str =~ s/&#39;/'/g;
  return $str;
}# end HTMLDecode()


sub MapPath
{
  my ($s, $path) = @_;
  
  return unless defined($path);
  
  $s->context->current->config->web->www_root . $path;
}# end MapPath()


sub Mail
{
  my $s = shift;
  
  Mail::Sendmail::sendmail( @_ );
}# end Mail()


sub RegisterCleanup
{
  my ($s, $sub, @args) = @_;
  
  $s->context->add_cleanup_handler( $sub, @args );
}# end RegisterCleanup()


sub Error
{
  my $s = shift;
  
  my $error = ref($_[0]) && $_[0]->isa('ASP4::Error') ? $_[0] : ASP4::Error->new( @_ );

  $s->context->stash->{error} = $error;
  $s->context->config->load_class( $s->context->config->errors->error_handler );
  my $error_handler = $s->context->config->errors->error_handler->new();
  $error_handler->init_asp_objects( $s->context );
  $error_handler->run( $s->context );
  return $error;
}# end Error()

1;# return true:

