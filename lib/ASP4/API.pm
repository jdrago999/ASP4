
package ASP4::API;
use ASP4::ConfigLoader;
use ASP4::UserAgent;
use ASP4::HTTPContext;
BEGIN { ASP4::ConfigLoader->load }

sub new { bless { }, shift }

sub config
{
  my $s = shift;
  $s->{config} ||= ASP4::ConfigLoader->load();
  $s->{config};
}# end config()


sub context { ASP4::HTTPContext->current }


sub test_fixtures
{
  my $s = shift;
  $s->{test_fixtures} ||= $s->_load_test_fixtures();
  $s->{test_fixtures};
}# end test_fixtures()


sub properties
{
  my $s = shift;
  $s->{properties} ||= $s->_load_properties();
  $s->{properties};
}# end properties()


sub ua
{
  my $s = shift;
  $s->{ua} ||= ASP4::UserAgent->new;
  $s->{ua};
}# end ua()


sub _load_test_fixtures
{
  my $s = shift;
  
  my %options = (
    $s->config->web->application_root . '/etc/test_fixtures.json' => 'Data::Properties::JSON',
    $s->config->web->application_root . '/etc/test_fixtures.yaml' => 'Data::Properties::YAML',
    $s->config->web->application_root . '/etc/test_fixtures.yml'  => 'Data::Properties::YAML',
  );
  
  # Short-circuit on the first found test_fixtures.* file:
  my ($file) = grep { -f $_ } sort keys %options;
  my $class = $options{$file};
  $s->config->load_class( $class );
  $class->new( properties_file => $file );
}# end _load_test_fixtures()


sub _load_properties
{
  my $s = shift;
  
  my %options = (
    $s->config->web->application_root . '/etc/properties.json' => 'Data::Properties::JSON',
    $s->config->web->application_root . '/etc/properties.yaml' => 'Data::Properties::YAML',
    $s->config->web->application_root . '/etc/properties.yml'  => 'Data::Properties::YAML',
  );
  
  # Short-circuit on the first found test_fixtures.* file:
  my ($file) = grep { -f $_ } sort keys %options;
  my $class = $options{$file};
  $s->config->load_class( $class );
  $class->new( properties_file => $file );
}# end _load_test_fixtures()

1;# return true:

