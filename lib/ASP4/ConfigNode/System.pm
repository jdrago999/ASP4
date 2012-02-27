
package
ASP4::ConfigNode::System;

use strict;
use warnings 'all';
use base 'ASP4::ConfigNode';


sub libs { $_[0]->{libs} ||= [ ]; $_[0]->{libs} }
sub load_modules { $_[0]->{load_modules} ||= [ ]; $_[0]->{load_modules} }
sub post_processors { $_[0]->{post_processors} ||= [ ]; $_[0]->{post_processors} }
sub env_vars { $_[0]->{env_vars} ||= { }; $_[0]->{env_vars} }
sub settings { $_[0]->{settings} ||= { }; $_[0]->{settings} }



1;# return true:

