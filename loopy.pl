#Author : culb
#Purpose: Cure my boredom.
#Don't be a fucking moron. This will lock XChat up.

use strict;
use warnings;
use Xchat qw( :all );

hook_command( 'LOOPY', sub {

	EATMEMORY:
	goto EATMEMORY;

}, { help_text => '/LOOPY - Lock it up.' } );

register( 'Loopy', '1', 'Infinite loop' );