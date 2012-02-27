#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $api = ASP4::API->new();

subtest 'master.asp' => sub {
  ok(my $res = $api->ua->get('/010/master.asp'), 'GET /010/master.asp' );
  
  like $res->content => qr(<title>default\s+title</title>)s, 'meta_title.default';
  like $res->content => qr(<meta\s+name\="keywords"\s+content\="default\s+keywords")s, 'meta_keywords.default';
  like $res->content => qr(<meta\s+name\="description"\s+content\="default\s+description")s, 'meta_description.default';
  
  like $res->content => qr(<h1\s+id\="headline">default\s+title</h1>)s, 'h1#headline matches meta_title.default';
  like $res->content => qr(<div\s+id\="breadcrumbs">.+?</div>)s, 'breadcrumbs.default';
  like $res->content => qr(<div\s+id\="main_content">\s*default\s+content\s*</div>)s, 'main_content.default';
};


subtest 'child.asp' => sub {
  ok(my $res = $api->ua->get('/010/child.asp'), 'GET /010/child.asp' );
  
  like $res->content => qr(<title>child\s+title</title>)s, 'meta_title.child';
  like $res->content => qr(<meta\s+name\="keywords"\s+content\="child\s+keywords")s, 'meta_keywords.child';
  like $res->content => qr(<meta\s+name\="description"\s+content\="child\s+description")s, 'meta_description.child';
  
  like $res->content => qr(<h1\s+id\="headline">child\s+headline</h1>)s, 'h1#headline matches meta_title.child';
  unlike $res->content => qr(<div\s+id\="breadcrumbs">.+?</div>)s, 'breadcrumbs is removed by child';
  like $res->content => qr(<div\s+id\="main_content">\s*child\s+content\s*</div>)s, 'main_content.child';
};


subtest 'inner-child.asp' => sub {
  ok(my $res = $api->ua->get('/010/inner-child.asp'), 'GET /010/inner-child.asp' );
  
  like $res->content => qr(<title>child\s+title</title>)s, 'meta_title.child';
  like $res->content => qr(<meta\s+name\="keywords"\s+content\="child\s+keywords")s, 'meta_keywords.child';
  like $res->content => qr(<meta\s+name\="description"\s+content\="child\s+description")s, 'meta_description.child';
  
  like $res->content => qr(<h1\s+id\="headline">child\s+headline</h1>)s, 'h1#headline matches meta_title.child';
  unlike $res->content => qr(<div\s+id\="breadcrumbs">.+?</div>)s, 'breadcrumbs is removed by child';
  like $res->content => qr(<div\s+id\="main_content">\s*inner\s+content\s*</div>)s, 'main_content.inner-child';
};


