#!/usr/bin/perl -w

use utf8;
use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $hellos = {
  ascii   => {
    original  => 'Hello, World!',
  },
  arabic  => {
    original  => 'مرحبا ، العالم!',
  },
  armenian  => {
    original  => 'Բարեւ, աշխարհի.',
  },
  russian   => {
    original  => 'Здравствуй, мир!',
  },
  chinese_simplified  => {
    original  => '你好，世界！',
  },
  foo => {
    original  => 'Bjòrknù',
  }
};

my $api = ASP4::API->new;

for my $lang (qw( ascii arabic chinese_simplified armenian foo ))
{
  ok( my $res = $api->ua->get("/handlers/dev.encoding.hello?lang=$lang"), "GET /handlers/dev.encoding.hello?lang=$lang" );
  
  is $res->decoded_content, $hellos->{$lang}->{original};
}# end for()

