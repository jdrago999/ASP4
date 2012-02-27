#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use ASP4::API;

ok( my $api = ASP4::API->new );

ok( my $context = $api->context );

my $env = {
  REQUEST_URI     => '/seo/',
  REQUEST_METHOD  => 'GET'
};

$context->setup_request( $env );
$context->execute( );


