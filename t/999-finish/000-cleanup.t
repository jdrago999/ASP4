#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

ok( unlink('/tmp/db_asp4'), "unlink('/tmp/db_asp4')" );
map {
  ok(
    unlink($_),
    "unlink('$_')"
  );
} </tmp/PAGE_CACHE/DefaultApp/*.pm>;

