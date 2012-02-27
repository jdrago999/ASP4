
package
ASP4::StaticHandler;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  my $env = $context->cgi->{psgi_env};
  my $file = $env->{SCRIPT_FILENAME} ?
               $env->{SCRIPT_FILENAME} :
                 $Server->MapPath( (split /\?/, $env->{REQUEST_URI})[0] );
  
  unless( $file && -f $file )
  {
    $Response->Status( 404 );
    $Response->End;
    return 404;
  }# end unless()
  open my $ifh, '<', $file
    or die "Cannot open '$file' for reading: $!";
  local $/;
  $Response->SetHeader('content-length' => (stat($file))[7] );
  
  my ($ext) = $file =~ m{\.([^\.]+)$};
  my %types = (
    swf   => 'application/x-shockwave-flash',
    xml   => 'text/xml',
    jpg   => 'image/jpeg',
    jpeg  => 'image/jpeg',
    png   => 'image/png',
    bmp   => 'image/bmp',
    gif   => 'image/gif',
    json  => 'application/x-json',
    css   => 'text/css',
    pdf   => 'application/x-pdf',
    js    => 'text/javascript',
    svg   => 'image/svg+xml',
    html  => 'text/html',
    txt   => 'text/plain',
  );
  my $type = $types{lc($ext)} || 'application/octet-stream';
  $Response->ContentType( $type );
  
  my ($filename) = $file =~ m{([^/]+)$};
  my $disp = lc($type) eq 'pdf' ? 'attachment' : 'inline';
  $Response->SetHeader('content-disposition' => qq($disp; filename="$filename"; yay=yay;));
  $Response->Write( scalar(<$ifh>) );
  close($ifh);
}# end run()

1;# return true:

