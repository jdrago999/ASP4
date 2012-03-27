
package ASP4::Preloader;

use strict;
use warnings 'all';
use ASP4::ConfigLoader;
use ASP4::PageParser;
use ASP4::HandlerResolver;

our $imported = 0;

sub import
{
  my $class = shift;
  return 1 if $imported++;
#  chdir('/home/john/Projects/nara/www');
  my $config = ASP4::ConfigLoader->load;
  preload_all( $config )
    unless $config->{loaded_all}++;
}# end import()


sub preload_all
{
  my $config = shift;
  
  $config->_load_class( $config->errors->error_handler );
  map { warn "[$$] Filter($_->{class})\n"; $config->_load_class( $_->{class} ); } $config->web->request_filters;
  eval {
    map { warn "[$$] App Module($_)\n"; $config->_load_class( $_ ); } @{ $config->app };
  };
  map { warn "[$$] LoadModule($_)\n"; $config->_load_class( $_ ); } $config->system->load_modules;
  
  load_asp_scripts( $config );
  load_handlers( $config );
  warn "[$$] All handlers and scripts are loaded";
}# end preload_all()


sub load_asp_scripts
{
  my $config = shift;
  my $root = $config->web->www_root;
  chdir( $root );

  map {
    chomp;
    chdir( $root );
    $_ =~ s{^\Q$root\E}{};
    my $info = ASP4::PageParser->new(script_name => $_)->parse();
#    warn "ASP($info->{script_name})\n";
  } split /\n/, `find $root | grep \\.asp\$`;
}# end load_asp()


sub load_handlers
{
  my $config = shift;
  my $root = $config->web->application_root;
  chdir( $root );
  local $ENV{DOCUMENT_ROOT} = $config->web->www_root;

  map {
    chomp;
    $_ =~ s{\.pm$}{};
    $_ =~ s{^\Q$root/handlers/\E}{};
#    (my $class = $_) =~ s{/}{::}g;
    ASP4::HandlerResolver->new()->resolve_request_handler( $_ );
#    $config->load_class( $class );
  } split /\n/, `find $root/handlers | grep pm\$`;
}# end load_asp()

1;# return true:

