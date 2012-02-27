
package 
ASP4::SessionStateManager::Memcached;

# XXX: Experimental memcached session storage.
# TODO: Configuration section is likely to change.

use strict;
use warnings 'all';
use base 'ASP4::SessionStateManager';
use Cache::Memcached;
use JSON::XS;

my $memd;

sub new
{
  my $s = bless { }, shift;
  
  my $conn = ASP4::ConfigLoader->load->data_connections->session;
  $memd = Cache::Memcached->new({
    servers => [ $conn->dsn ]
  });
  
  my $id = $s->parse_session_id();
  unless( $id && $s->verify_session_id( $id, $conn->session_timeout ) )
  {
    $s->{__ttl} = $conn->session_timeout if $conn->session_timeout;
    $s->{SessionID} = $s->new_session_id();
    $s->write_session_cookie();
    return $s->create( $s->{SessionID} );
  }# end unless()
  
  return $s->retrieve( $id );
}# end BUILD()


sub verify_session_id
{
  my ($s, $id) = @_;
  
  my $ref = $memd->get( $id )
    or return;
  $s = bless decode_json($ref), ref($s) ? ref($s) : $s;
}# end verify_session_id()
*retrieve = \&verify_session_id;


sub create
{
  my ($s, $id) = @_;
  
  $s->save();
  return $s;
}# end create()


sub save
{
  my ($s, $id) = @_;
  
  return unless $s->{SessionID};
  $s->{__lastMod} = time();
  $s->sign;
  
  my %clone = %$s;
  my $json = encode_json(\%clone);
  $memd->set( $s->{SessionID}, $json, $s->{__ttl} );
}# end save()


sub reset
{
  my $s = shift;
  
  map { delete($s->{$_}) } grep { $_ !~ m{^(SessionID|__ttl)$} } keys %$s;
  $s->save;
  return;
}# end reset()

1;# return true:

