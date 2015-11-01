# Author: culb ( A.K.A nightfrog )
# Hide the topic, channel url, and ChanServ notice when you join a channel

use strict;
use warnings;
use Xchat qw( :all );


hook_print( 'Notice', \&notice );
hook_print( 'You Join', \&you_join );


sub notice
{
    my ( $who, $message ) = @{$_[0]};

    if ( $who eq 'ChanServ' and $message =~ m/^\[#\w+\] Welcome to/ )
    {
        return EAT_XCHAT;
    }
}

sub you_join
{
    for my $event ( 'Channel Url', 'Topic', 'Topic Creation' )
    {
        hook_print( $event, sub{ return EAT_XCHAT; } );
    }
}


register(
    'Hide the topic',
    0x2,
    'Hide the topic when you join a channel'
);
