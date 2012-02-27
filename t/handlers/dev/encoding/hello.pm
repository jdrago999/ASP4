
package dev::encoding::hello;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;
use MIME::Base64;
use Encode;
use utf8;

# TODO: Encoding tests to make sure we get round-trip encoding integrity.
sub run
{
  my ($s, $context) = @_;
  
  my $hellos = {
    ascii => {
      original  => 'Hello, World!'
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
  
  my $lang = $Form->{lang}
    or return;

  $Response->ContentType("text/plain; charset=utf-8");
  $Response->Write(
    encode_utf8(
      $hellos->{$lang}->{original}
    )
  );
}# end run()

1;# return true:

