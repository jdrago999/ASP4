
package ASP4::HTTPContext;

use strict;
use warnings 'all';
use CGI::PSGI;
use IO::Scalar;

use Plack::Request;
use ASP4::HeadersOut;
use ASP4::Response;
use ASP4::Request;
use ASP4::Server;
use ASP4::SessionStateManager::NonPersisted;
use ASP4::StaticHandler;
use ASP4::PageLoader;
use ASP4::HandlerResolver;

our $_instance;

# This class is a contextual-singleton.
# One instance per "context".
sub current
{
  my $class = shift;
  
  $_instance ||= $class->new();
  
  return $_instance;
}# end current()

sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    buffer        => '',
    is_subrequest => $args{is_subrequest} ? 1 : 0
  }, $class;
  
  $_instance = $s unless $s->is_subrequest;
  
  return $s;
}# end new()


# Read-only Properties:
sub is_subrequest { shift->{is_subrequest} }
sub buffer { shift->{buffer} }


# Lazy Read-only Properties:
sub session
{
  my $s = shift;
  
  return $s->{session} if $s->{session};
  my $session_class = $s->do_disable_session_state
                        ? 'ASP4::SessionStateManager::NonPersisted'
                        : $s->config->data_connections->session->manager;
  $s->{session} ||= $session_class->new( );
  $s->{session};
}# end server()

sub server
{
  my $s = shift;
  $s->{server} ||= ASP4::Server->new();
  $s->{server};
}# end server()

sub request
{
  my $s = shift;
  $s->{request} ||= ASP4::Request->new();
  $s->{request};
}# end request()

sub response
{
  my $s = shift;
  $s->{response} ||= ASP4::Response->new();
  $s->{response};
}# end response()

sub config
{
  my $s = shift;
  $s->{config} ||= ASP4::ConfigLoader->load();
  $s->{config};
}# end config()

sub stash
{
  my $s = shift;
  $s->{stash} ||= { };
  $s->{stash};
}# end stash()

sub headers_out
{
  my $s = shift;
  $s->{headers_out} ||= ASP4::HeadersOut->new;
  $s->{headers_out};
}# end headers_out()

sub headers_in
{
  my $s = shift;
  $s->{headers_in} ||= Plack::Request->new( $s->cgi->{psgi_env} )->headers;
  $s->{headers_in};
}# end headers_in()

sub did_end
{
  my $s = shift;
  if( @_ )
  {
    $s->{did_end} = shift;
  }
  else
  {
    $s->{did_end} //= 0;  #//
  }# end if()
  $s->{did_end};
}# end did_end()

sub cleanup_handlers
{
  my $s = shift;
  $s->{cleanup_handlers} ||= [ ];
  $s->{cleanup_handlers};
}# end cleanup_handlers()

sub async_cleanup_handlers
{
  my $s = shift;
  $s->{async_cleanup_handlers} ||= [ ];
  $s->{async_cleanup_handlers};
}# end cleanup_handlers()


# Read-write Properties:
sub env { my $s = shift; @_ ? $s->{env} = shift : $s->{env} }
sub cgi { my $s = shift; @_ ? $s->{cgi} = shift : $s->{cgi} }


# Public methods:
sub rprint { $_[0]->{buffer} .= $_[1] if defined($_[1]) }

sub psgi_response
{
  my $s = shift;
  
  return [
    $s->response->Status,
    $s->headers_out->psgi_headers,
    [
      $s->buffer
    ]
  ];
}# end psgi_response()

sub setup_request
{
  my ($s, $env) = @_;
  
  # Fixup the env first:
  $env  = $env->{REQUEST_METHOD} =~ m{^(GET|HEAD)$}
            ? $env
            : $s->_sanitize_psgi_env_input( $env );
  my ($uri_no_args) = split /\?/, $env->{REQUEST_URI};
  if( $env->{REQUEST_URI} =~ m{^/handlers/} )
  {
    $env->{SCRIPT_NAME} = $uri_no_args;
  }
  else
  {
    my $www_root = $s->config->web->www_root;
    my $path = $www_root . $uri_no_args;
    if( -d $path )
    {
      # Expand /folder/ to /folder/index.asp
      $uri_no_args =~ s{/$}{};
      $uri_no_args .= '/index.asp';
    }# end if()
    $env->{SCRIPT_NAME} = $uri_no_args;
  }# end if()
  
  # Now assign it:
  $s->env( $env );
  $s->cgi( CGI::PSGI->new( $s->env ) );
  map { $ENV{$_} = $env->{$_} } grep { defined $env->{$_} && $_ =~ m{^[A-Z]} } keys %$env;
  
  return $s;
}# end setup_request()


sub execute
{
  my ($s, $args) = @_;
  
  unless( $s->is_subrequest )
  {
    $ENV{REQUEST_URI} = $s->env->{REQUEST_URI};
    my $filter_resolver = ASP4::FilterResolver->new();
    my @filter_classes  = $s->_resolve_request_filters($s->env->{SCRIPT_NAME}, $s->env->{REQUEST_METHOD} );
    foreach my $filter_class (  @filter_classes )
    {
      # URI might have changed:
      $s->config->load_class( $filter_class );
      $filter_class->init_asp_objects( $s );
      my $res = $filter_class->new()->run( $s );
      if( $s->did_end || ( defined($res) && $res ne '-1' ) )
      {
        return $res;
      }# end if()
    }# end foreach()
  }# end unless()
  
  my $handler_class = ASP4::HandlerResolver->new->resolve_request_handler( $s->env->{SCRIPT_NAME}, $s->env->{REQUEST_METHOD} )
    or return $s->response->Status( 404 );
  $handler_class->init_asp_objects( $s )->new->run( $s, $args );
}# end execute()


sub add_cleanup_handler
{
  my ($s, $code, @args) = @_;
  push @{ $s->cleanup_handlers }, sub { $code->( @args ) };
}# end add_cleanup_handler()

sub add_async_cleanup_handler
{
  my ($s, $code, @args) = @_;
  push @{ $s->async_cleanup_handlers }, sub { $code->( @args ) };
}# end add_async_cleanup_handler()


# Private, internal methods:
sub do_disable_session_state
{
  my $s = shift;
  $s->{do_disable_session_state} //= do { #/#keep gedit happy:
    my ($uri) = split /\?/, $s->env->{REQUEST_URI};
    
    grep {
      $_->{uri_equals}
        ? $_->{uri_equals} eq $uri
        : $_->{uri_match}
          ? $uri =~ m{^$_->{uri_match}$}
          : 0
    } @{ $s->config->web->disable_persistence };
  };
  
  $s->{do_disable_session_state};
}# end do_disable_session_state()

sub _resolve_request_filters
{
  my ($s, $uri, $method) = @_;
  
  my @out = ( );
  my ($uri_no_args) = split /\?/, $uri;
  foreach my $request_filter ( @{ $s->config->web->request_filters } )
  {
    if( my $exact = $request_filter->{uri_equals} )
    {
      push @out, $request_filter->{class}
        if $exact eq $uri_no_args;
    }
    elsif( my $pattern = $request_filter->{uri_match} )
    {
      push @out, $request_filter->{class}
        if $uri_no_args =~ m{^$pattern};
    }# end if()
  }# end foreach()
  
  @out ? return @out : return;
}# end _resolve_request_filters()


sub _sanitize_psgi_env_input
{
  my ($s, $psgi_env) = @_;
  
  if( my $ifh = $psgi_env->{'psgi.input'} )
  {
    my $data_in = '';
    local $SIG{__WARN__} = sub { };
    eval {
      while( defined(my $line = <$ifh>) )
      {
        $data_in .= $line;
      }# end while()
      close($ifh);
      $psgi_env->{'psgi.input'} = IO::Scalar->new( \$data_in );
    };# end eval{}
  }# end if()
  
  return $psgi_env;
}# end _sanitize_psgi_env_input()


# DESTROY is called explicitly by ASP4::UserAgent and ASP4::PSGI after the
# psgi_response has been collected.
sub DESTROY
{
  my $s = shift;
  
  $_->() for @{ $s->cleanup_handlers };
  $s->session->save
    if $s->{session};
  return unless @{ $s->async_cleanup_handlers };
  
  if( defined(my $pid = fork) )
  {
    if( $pid )
    {
      undef %$s;
      return;
    }
    else
    {
      $_->() for @{ $s->async_cleanup_handlers };
      exit;
    }# end if()
  }
  else
  {
    $_->() for @{ $s->async_cleanup_handlers };
  }# end if()
}# end DESTROY()


1;# return true:

