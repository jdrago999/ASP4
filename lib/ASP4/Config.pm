
package ASP4::Config;

use strict;
use warnings 'all';
use Carp 'confess';
use Class::Load ();

sub new
{
  my ($class, %args) = @_;
  
  # Make sure we have what we expect:
  my @required = qw(
    system
    web
    errors
    data_connections
  );
  foreach(@required)
  {
    confess "Required param '$_' was not provided"
      unless $args{$_} && $args{$_}->isa('ASP4::ConfigNode');
  }# end foreach()
  
  my $s = bless \%args, $class;
  
  push @INC, grep { my $dir = $_; $_ && ! grep { $dir eq $_ } @INC } @{ $s->system->libs };
  map { $ENV{$_} = $s->system->env_vars->$_ } keys %{ $s->system->env_vars };
  map { $s->load_class( $_ ) } grep { $_ } @{ $s->system->load_modules };
  # TODO: Load $Config->app modules too.
  
  if( my $class = $s->data_connections->session->manager )
  {
    $s->load_class( $class );
    
    $s->data_connections->session->{session_timeout} =~ s{^\*$}{0};
      
  }# end if()
  
  return $s;
}# end new()

sub system { $_[0]->{system} }
sub web { $_[0]->{web} }
sub errors { $_[0]->{errors} }
sub app { $_[0]->{app} ||= [ ]; $_[0]->{app} }
sub data_connections { $_[0]->{data_connections} }

sub load_class { return unless $_[1]; Class::Load::load_class( $_[1] ) }



1;# return true:

