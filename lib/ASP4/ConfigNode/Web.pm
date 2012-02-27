
package
ASP4::ConfigNode::Web;
use strict;
use warnings 'all';
use base 'ASP4::ConfigNode';
use JSON::XS;
use Carp 'confess';
use Class::Load 'load_class';


sub init
{
  my ($s) = @_;
  
  my @required = qw(
    application_name
    application_root
    www_root
    handler_root
    handler_resolver
    handler_runner
    filter_resolver
  );
  foreach ( @required )
  {
    confess "Required param '$_' was not provided"
      unless $s->{$_};
  }# end foreach()
  
  $s->{page_cache_root} = $s->_init_page_cache_root;
  
  load_class( $s->filter_resolver );
  load_class( $s->handler_resolver );
  load_class( $s->handler_runner );
  $s->_init_page_cache_root;
  
  push @INC, $s->handler_root unless grep { $_ eq $s->handler_root } @INC;
  
}# end init()

sub application_name { $_[0]->{application_name} }
sub application_root { $_[0]->{application_root} }
sub www_root { $_[0]->{www_root} }
sub handler_root { $_[0]->{handler_root} }
sub handler_resolver { $_[0]->{handler_resolver} }
sub handler_runner { $_[0]->{handler_runner} }
sub filter_resolver { $_[0]->{filter_resolver} }
sub page_cache_root { $_[0]->{page_cache_root} }

sub request_filters { $_[0]->{request_filters} ||= [ ]; $_[0]->{request_filters} }
sub disable_persistence { $_[0]->{disable_persistence} ||= [ ]; $_[0]->{disable_persistence} }

sub router
{
  my $s = shift;
  return $s->{router} if $s->{router};
  return unless $s->_has_router;
  
  $s->{router} = Router::Generic->new();
  $s->_parse_routes;
  return $s->{router};
}# end router()

sub routes { $_[0]->{routes} ||= $_[0]->_parse_routes; $_[0]->{routes} }
sub _has_router { $_[0]->{_has_router} ||= eval { require Router::Generic; 1 }; $_[0]->{_has_router} }


sub _init_page_cache_root
{
  my $s = shift;
  
  # Make the folder unless it already exists:
  my $temp_root = '/tmp';
  if( $^O =~ m{win32}i )
  {
    $temp_root = $ENV{TEMP} || $ENV{TMP};
  }# end if()
  $temp_root .= '/PAGE_CACHE';
  mkdir($temp_root, 0777) unless -d $temp_root;
  push @INC, $temp_root unless grep { $_ eq $temp_root } @INC;
  
  (my $app_name_clean = $s->application_name) =~ s{::}{_}g;
  my $app_cache_root = $temp_root . '/' . $app_name_clean;
  mkdir($app_cache_root, 0777) unless -d $app_cache_root;
  return $temp_root;
}# end _init_page_cache_root()


sub _parse_routes
{
  my $s = shift;
  
  return [ ] unless $s->_has_router;
  
  my @original = @{ $s->{routes} || [ ] };
  my $app_root = $s->application_root;
  @{ $s->{routes} } = map {
    $_->{include_routes} ? do {
      my $item = $_;
      open my $ifh, '<', $item->{include_routes}
        or die "Cannot open '$item->{include_routes}' for reading: $!";
      local $/;
      my $json = eval { decode_json( scalar(<$ifh>) ) }
        or confess "Error parsing '$item->{include_routes}': $@";
      ref($json) eq 'ARRAY'
        or confess "File '$item->{include_routes}' should be an arrayref but it's a '@{[ ref($json) ]}' instead.";
      @$json;
    } : $_
  } @original;

  [ map { $s->router->add_route( %$_ ) } @{ $s->{routes} } ];
}# end _parse_routes()

1;# return true:

