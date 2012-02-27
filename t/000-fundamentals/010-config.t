#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

my $config;
my $loader;
subtest 'ASP4::ConfigLoader' => sub {
  use_ok('ASP4::ConfigLoader');
  ok( $loader = ASP4::ConfigLoader->new() );
  ok( $config = $loader->load(), '->load()' );
  isa_ok( $config, 'ASP4::Config' );
};

subtest 'system.libs' => sub {
  foreach my $lib ( @{ $config->system->libs } )
  {
    ok grep { $_ eq $lib } @INC;
  }# end foreach()
};

subtest 'system.load_modules' => sub {
  ok $DBI::VERSION, 'DBI.$VERSION is set';
};

subtest 'system.env_vars' => sub {
  is $ENV{myvar} => 'Some-Value', 'env.myvar is set';
};

subtest 'system.settings' => sub {
  is $config->system->settings->foo               => 'bar', 'config.system.settings.foo = bar';
  is $config->system->settings->hashref_var->foo  => 'bar', 'config.system.settings.hashref_var.foo = bar';
  is $config->system->settings->arrayref_var->[0] => 'foo', 'config.system.settings.arrayref_var[0] = foo';
};

subtest 'errors' => sub {
  is $config->errors->error_handler     => 'ASP4::ErrorHandler', 'errors.error_handler';
  is $config->errors->mail_errors_to    => 'jdrago_999@yahoo.com', 'errors.mail_errors_to';
  is $config->errors->mail_errors_from  => 'root@localhost', 'errors.mail_errors_from';
  is $config->errors->smtp_server       => 'localhost', 'errors.smtp_server';
};

subtest 'web' => sub {
  is $config->web->application_name  => 'DefaultApp', 'web.application_name';
  is $config->web->application_root  => $loader->application_root, 'web.application_root';
  is $config->web->handler_root      => $loader->application_root . '/handlers', 'web.handler_root';
  is $config->web->www_root          => $loader->application_root . '/htdocs', 'web.www_root';
  is $config->web->handler_resolver  => 'ASP4::HandlerResolver', 'web.handler_resolver';
  is $config->web->handler_runner    => 'ASP4::HandlerRunner', 'web.handler_runner';
  is $config->web->filter_resolver   => 'ASP4::FilterResolver', 'web.filter_resolver';
  
  is ref($config->web->request_filters)          => 'ARRAY', 'web.request_filters isa ArrayRef';
  is $config->web->request_filters->[0]->{class} => 'My::LoggedInFilter', 'web.request_filters[0].class';
  
  is ref($config->web->disable_persistence)              => 'ARRAY', 'web.disable_persistence isa ArrayRef';
  is $config->web->disable_persistence->[0]->{uri_match} => '^/handlers/dev\.speed', 'web.disable_persistence[0].uri_match';
  
  is ref($config->web->router) => ( eval { require Router::Generic; 1 } ? 'Router::Generic' : undef ), 'web.router is only set if we have Router::Generic';
  is ref($config->web->routes) => 'ARRAY', 'web.routes isa ArrayRef';
};

subtest 'data_connections' => sub {
  ok(my $session = $config->data_connections->session, 'config.data_connections.session' );
  is $session->manager          => 'ASP4::SessionStateManager::InMemory', 'session.manager';
  is $session->cookie_name      => 'session-id', 'session.cookie_name';
  is $session->cookie_domain    => '*', 'session.cookie_domain';
  is $session->session_timeout  => '0', 'session.session_timeout';
  is $session->dsn              => 'DBI:SQLite:dbname=/tmp/db_asp4', 'session.dsn';
  is $session->username         => '', 'session.username';
  is $session->password         => '', 'session.password';
  
  ok(my $main = $config->data_connections->main, 'config.data_connections.main' );
  is $main->dsn       => 'DBI:SQLite:dbname=/tmp/db_asp4', 'main.dsn';
  is $main->username  => '', 'main.username';
  is $main->password  => '', 'main.password';
};


