#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use ASP4::API;

ok( 1, 'Loaded ASP4::API');

ok( my $api = ASP4::API->new, 'api->new' );

use Carp 'confess';
$SIG{__DIE__} = \&confess;

ok $api->config, 'api.config';
ok $api->test_fixtures, 'api.test_fixtures';
ok $api->properties, 'api.properties';
ok $api->ua, 'api.ua';
ok $api->context, 'api.context';

use Time::HiRes 'gettimeofday';
my $start_time = gettimeofday();
my $max_requests = 1;
for( 1..$max_requests )
{
  my $res = $api->ua->get('/000/');
#  warn "$_/$max_requests\n" if $_ % 100 == 0;
}

my $diff = gettimeofday() - $start_time;
my $persec = sprintf( "%.2f", $max_requests / $diff);
#warn "Finished $max_requests req in $diff seconds - rate: $persec/sec\n";

