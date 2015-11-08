#Author: culb ( A.K.A nightfrog )
#Please read the end of the file for notes and more information

use strict;
use warnings;
use Xchat qw( :all );

sub gotoall
{
    my $context = get_info( 'context' );
    for my $var ( get_list( 'channels' ) )
    {
        command( "GUI COLOR 0", $var->{channel}, $var->{network} );
    }
    set_context $context;
    return EAT_XCHAT;
}

hook_command( 'GTA', \&gotoall );
register( 'Go to All', 0x1, 'Visit every window so it looks like each was visited manually' );

__END__

Syntax: /gta

Version history:
	001: Initial release (2010)

Usage:
    Go to each context so the color changes as if nothing ever happened in that channel.
    This is the same as /allchan gui color 0 but that only works for channels, this script
    works for ALL contexts and not just channels
