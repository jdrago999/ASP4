
package
ASP4::ConfigLoader;

use strict;
use warnings 'all';
use Cwd 'fastcwd';
use JSON::XS;
use ASP4::Config;
use ASP4::ConfigNode;
use ASP4::ConfigNode::Web;
use ASP4::ConfigNode::System;

my $cache = { };

sub new { bless { }, shift }

sub application_root { $_[0]->{application_root} }
sub project_root { $_[0]->{project_root} }
sub config_filename
{
  my $s = shift;
  $s->{config_filename} ||= $s->_find_config_path();
  $s->{config_filename};
}# end config_filename()

sub load
{
  my ($class) = @_;
  
  my $s = ref($class) ? $class : $class->new();
  my $path = $s->config_filename();

  my $file_time = (stat($path))[7];
  if( exists($cache->{$path}) && ( $file_time <= $cache->{$path}->{timestamp} ) )
  {
    return $cache->{$path}->{data};
  }# end if()
  
  my $json = do {
    open my $ifh, '<', $path
      or die "Cannot open '$path' for reading: $!";
    local $/;
    my %replace = (
      '@ServerRoot@'  => $s->application_root,
      '@ProjectRoot@' => $s->project_root,
    );
    map { $replace{$_} =~ s{\\}{\\\\}sg } keys %replace;
    (my $str = <$ifh>) =~ s{(\@(?:ServerRoot|ProjectRoot)\@)}{$replace{$1}}egs;
    my $data = eval { decode_json( $str ) }
      or die "Cannot parse json file '$path': $@";
    $data;
  };
  
  my $config_types = {
    system  => 'ASP4::ConfigNode::System',
    web     => 'ASP4::ConfigNode::Web',
  };
  my %args = (
    (
      map {
        my $type = $config_types->{$_} || 'ASP4::ConfigNode';
       ( $_ => $type->new( %{ $json->{$_} } ) )
      } grep { ref($json->{$_}) eq 'HASH' } keys %$json
    ),
    (
      map {
        ( $_ => $json->{$_} )
      } grep { ref($json->{$_}) ne 'HASH' } keys %$json
    )
  );
  
  (my $where = $path) =~ s/\/conf\/[^\/]+$//;
  my $config = ASP4::Config->new( %args );
  $cache->{$path} = {
    data      => $config,
    timestamp => $file_time,
  };
  
  $config->init();
  $cache->{$path}->{data};
}# end load()


sub _find_config_path
{
  my ($s) = @_;
  
  my $CONFIGFILE = 'asp4-config.json';
  
  my $root = do { ($ENV{REMOTE_ADDR} || '') eq '' ? fastcwd() : $ENV{DOCUMENT_ROOT} || fastcwd() };
  
  # Try test dir:
  if( -f "$root/t/conf/$CONFIGFILE" )
  {
    $s->_set_root_paths( "$root/t" );
    return "$root/t/conf/$CONFIGFILE";
  }# end if()
  
  # Start moving up:
  for( 1...10 )
  {
    my $path = "$root/conf/$CONFIGFILE";
    if( -f $path )
    {
      $s->_set_root_paths( $root );
      return $path;
    }# end if()
    $root =~ s/\/[^\/]+$//
      or last;
  }# end for()
  
  die "CANNOT FIND '$CONFIGFILE' anywhere under '$root'";
}# end _find_config_path()


sub _set_root_paths
{
  my ($s, $root) = @_;
  
  my $project_root = (sub{
    my @parts = split /\//, $root;
    pop(@parts);
    join '/', @parts;
  })->();
  $s->{project_root} = $project_root;
  $s->{application_root} = $root;
}# end _set_root_paths()

1;# return true:

