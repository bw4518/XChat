# Hide the topic when you join a channel

use strict;
use warnings;
use Xchat qw( :all );

sub youJoin
{
    my $topic;
    $topic = hook_print( 'Topic',
        sub{ unhook( $topic ); return EAT_XCHAT; }
    );
    
    hook_print( 'Topic Creation',
        sub{ return EAT_XCHAT; }
    );
}

hook_print( 'You Join', \&youJoin );