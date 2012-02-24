#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $api = ASP4::API->new();

ok( my $res = $api->ua->get('/handlers/dev.api_inside_handler'), 'got res' );

# TODO: This returns the buffer twice.
#warn $res->as_string;


