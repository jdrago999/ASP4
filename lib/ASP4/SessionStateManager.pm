

package ASP4::SessionStateManager;

use strict;
use warnings 'all';
use base 'Ima::DBI::Contextual';
use Digest::MD5 'md5_hex';
use Time::HiRes 'gettimeofday';
use HTTP::Date 'time2iso';
use Storable qw( freeze thaw );

sub context { ASP4::HTTPContext->current }

sub new
{
  my $class = shift;
  
  my $s = bless { }, $class;
  
  my $config = $s->context->config->data_connections->session;
  local $^W = 0;
  $s->set_db('Session', $config->dsn, $config->username, $config->password);
  
  my $id = $s->parse_session_id();
  unless( $id && $s->verify_session_id( $id, $config->session_timeout ) )
  {
    $s->{SessionID} = $s->new_session_id();
    $s->write_session_cookie();
    return $s->create( $s->{SessionID} );
  }# end unless()
  
  return $s->retrieve( $id );
}# end new()


sub parse_session_id
{
  my $s = shift;
  
  my $cookie_name = $s->context->config->data_connections->session->cookie_name;
  
  $s->context->cgi->cookie( $cookie_name );
}# end parse_session_id()


sub new_session_id
{
  my $s = shift;
  md5_hex( join ':', ( $s->context->cgi->virtual_host, gettimeofday() ) );
}# end new_session_id()


sub is_read_only
{
  my ($s, $val) = @_;
  
  if( defined($val) )
  {
    $s->{____is_read_only} = $val;
  }
  else
  {
    return $s->{____is_read_only};
  }# end if()
}# end is_readonly()


sub write_session_cookie
{
  my $s = shift;
  
  my $config = $s->context->config->data_connections->session;
  my $domain = "";
  unless( $config->cookie_domain eq '*' )
  {
    $domain = "domain=" . ( $config->cookie_domain || $ENV{HTTP_HOST} ) . ";";
  }# end unless()
  my $name = $config->cookie_name;
  
  $s->context->headers_out->add_header(
    'Set-Cookie' => "$name=$s->{SessionID}; path=/; $domain"
  );
}# end write_session_cookie()


sub verify_session_id
{
  my ($s, $id, $timeout ) = @_;
  
  my $is_active;
  if( $timeout eq '*' || ! $timeout )
  {
    local $s->db_Session->{AutoCommit} = 1;
    my $sth = $s->db_Session->prepare(<<"");
      SELECT count(*)
      FROM asp_sessions
      WHERE session_id = ?

    $sth->execute( $id );
    ($is_active) = $sth->fetchrow();
    $sth->finish();
  }
  else
  {
    my $range_start = time() - ( $timeout * 60 );
    local $s->db_Session->{AutoCommit} = 1;
    my $sth = $s->db_Session->prepare(<<"");
      SELECT count(*)
      FROM asp_sessions
      WHERE session_id = ?
      AND modified_on - created_on < ?

    $sth->execute( $id, $timeout );
    ($is_active) = $sth->fetchrow();
    $sth->finish();
  }# end if()

  return $is_active;
}# end verify_session_id()


sub create
{
  my ($s, $id) = @_;
  
  local $s->db_Session->{AutoCommit} = 1;
  my $sth = $s->db_Session->prepare_cached(<<"");
    delete from asp_sessions
    where session_id = ?

  $sth->execute( $id );

  $sth = $s->db_Session->prepare_cached(<<"");
    INSERT INTO asp_sessions (
      session_id,
      session_data,
      created_on,
      modified_on
    )
    VALUES (
      ?, ?, ?, ?
    )

  my $time = time();
  my $now = time2iso($time);
  $s->{__lastMod} = $time;
  
  $s->sign();
  
  my %clone = %$s;
  
  $sth->execute(
    $id,
    freeze( \%clone ),
    $now,
    $now,
  );
  $sth->finish();
  
  return $s->retrieve( $id );
}# end create()


sub retrieve
{
  my ($s, $id) = @_;

  local $s->db_Session->{AutoCommit} = 1;
  my $sth = $s->db_Session->prepare_cached(<<"");
    SELECT session_data, modified_on
    FROM asp_sessions
    WHERE session_id = ?

  my $now = time2iso();
  $sth->execute( $id );
  my ($data, $modified_on) = $sth->fetchrow;
  $data = thaw($data) || { SessionID => $id };
  $sth->finish();
  
  $s->{$_} = $data->{$_} for keys %$data;
  
  return $s;
}# end retrieve()


sub save
{
  my ($s) = @_;
  
  return unless $s->{SessionID};
  no warnings 'uninitialized';
  $s->sign;
  
  local $s->db_Session->{AutoCommit} = 1;
  my $sth = $s->db_Session->prepare_cached(<<"");
    UPDATE asp_sessions SET
      session_data = ?,
      modified_on = ?
    WHERE session_id = ?

  my %clone = %$s;
  delete $clone{____is_read_only};
  my $data = freeze( \%clone );
  
  $sth->execute( $data, time2iso(), $s->{SessionID} );
  $sth->finish();
  
  1;
}# end save()


sub sign
{
  my $s = shift;
  
  $s->{__signature} = $s->_hash;
}# end sign()


sub _hash
{
  my $s = shift;
  
  no warnings 'uninitialized';
  md5_hex(
    join ":", 
      map { "$_:$s->{$_}" }
        grep { $_ ne '__signature' && $_ ne '____is_read_only' } sort keys(%$s)
  );
}# end _hash()


sub is_changed
{
  my $s = shift;
  
  no warnings 'uninitialized';
  $s->_hash ne $s->{__signature};
}# end is_changed()


sub reset
{
  my $s = shift;
  
  delete($s->{$_}) for grep { $_ ne 'SessionID' } keys %$s;
  $s->save;
  return;
}# end reset()


sub DESTROY
{
  my $s = shift;
  
  return undef(%$s) unless $s->{SessionID};
  
  unless( $s->is_read_only )
  {
    $s->save;
  }# end unless()
  undef(%$s);
}# end DESTROY()

1;# return true:

