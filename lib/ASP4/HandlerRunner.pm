
package
ASP4::HandlerRunner;

use strict;
use warnings 'all';

sub new { bless { }, shift }


sub context { ASP4::HTTPContext->current }


sub run_handler
{
  my ($s, $handler_class, $args) = @_;
  
#warn "$s -> run_handler($handler_class)";
  context->config->load_class( $handler_class );
#warn "LOADED '$handler_class'";
  my $handler = $handler_class->new();
#warn "$handler_class.new = $handler";
  $handler_class->init_asp_objects( $s->context );
#warn "$handler.init_asp_objects(...)";
  my $res = $handler_class->run( $s->context, $args );
#warn "RESULT($res)";
#use Data::Dumper;
#warn "RESPONSE(" . Dumper( $s->context->psgi_response ) . ")";
  return $res;
}# end run_handler()

1;# return true:

