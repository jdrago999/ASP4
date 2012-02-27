
package ASP4::UserAgent;

use ASP4::HTTPContext;
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Message::PSGI;

sub new { bless { }, shift }

sub cookies
{
  my $s = shift;
  $s->{cookies} ||= { };
  $s->{cookies};
}# end cookies()


sub get
{
  my ($s, $url) = @_;
  
  my $req = GET $url;
  return $s->request( $req );
}# end get()


sub post
{
  my $s = shift;
  
  my $req = POST @_;
  return $s->request( $req );
}# end post()


sub upload
{
  my ($s, $uri, $args) = @_;
  
  my $req = POST $uri, Content_Type => 'form-data', Content => $args;
  return $s->request( $req );
}# end upload()


sub submit_form
{
  my ($s, $form) = @_;
  
  my $req = $form->click;
  return $s->request( $req );
}# end submit_form()


sub request
{
  my ($s, $req) = @_;
  
  my @cookies = ( );
  foreach my $cookie ( keys %{ $s->cookies } )
  {
    push @cookies, "$cookie=" . $s->cookies->{$cookie};
  }# end foreach()
  $req->header( cookie => join '; ', @cookies );
  
  my $psgi_env = req_to_psgi( $req );

  my $context = ASP4::HTTPContext->new();
  $context->setup_request( $psgi_env );
  $context->execute();

  my $res = res_from_psgi( $context->psgi_response );
  $s->_keep_cookies( $res );
  $context->DESTROY();
  return $res;
}# end request()


sub add_cookie
{
  my ($s, $name, $val) = @_;
  
  $s->cookies->{$name} = $val;
}# end add_cookie()


sub _keep_cookies
{
  my ($s, $res) = @_;
  
  my $cookies = $res->header('set-cookie')
    or return;
  foreach my $cookie ( $cookies =~ m{\b(.+?\=[^;]+);} )
  {
    my ($name, $value) = split /\=/, $cookie;
    $s->add_cookie( $name => $value );
  }# end foreach()
}# end _keep_cookies()


1;# return true:

