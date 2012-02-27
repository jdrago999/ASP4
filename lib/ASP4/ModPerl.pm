
package ASP4::ModPerl;

use strict;
use warnings 'all';
use APR::Table ();
use APR::Socket ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Connection ();
use Apache2::RequestUtil ();
use ASP4::HTTPContext ();
use ASP4::PSGI;
use base 'Plack::Handler::Apache2';

our $_r;

sub handler : method
{
  my ($class, $r) = @_;
  $_r = $r;

  $ENV{REQUEST_URI} = $r->uri . ( $r->args ? '?' . $r->args : '' );
  $::original_uri = $ENV{REQUEST_URI};
  chdir($r->document_root);
  
  my $app = ASP4::PSGI->app();
  $class->call_app($r, $app);
}# end handler()

sub fixup_path {
    my ($class, $r, $env) = @_;

    # $env->{PATH_INFO} is created from unparsed_uri so it is raw.
    my $path_info = $env->{PATH_INFO} || '';

    # Get argument of <Location> or <LocationMatch> directive
    # This may be string or regexp and we can't know either.
    my $location = $r->location;

    # Let's *guess* if we're in a LocationMatch directive
    if ($location eq '/') {
        # <Location /> could be handled as a 'root' case where we make
        # everything PATH_INFO and empty SCRIPT_NAME as in the PSGI spec
        $env->{SCRIPT_NAME} = '';
    } elsif ($path_info =~ s{^($location)/?}{/}) {
        $env->{SCRIPT_NAME} = $1 || '';
    } else {
        # Apache's <Location> is matched but here is not.
        # This is something wrong. We can only respect original.
#        $r->server->log_error(
#            "Your request path is '$path_info' and it doesn't match your Location(Match) '$location'. " .
#            "This should be due to the configuration error. See perldoc Plack::Handler::Apache2 for details."
#        );
    }

    $env->{PATH_INFO}   = $path_info;
}

1;# return true:

