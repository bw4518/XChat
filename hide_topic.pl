# Hide the topic when you join a channel

use strict;
use warnings;
use Xchat qw( :all );

sub youJoin
{
    my $hook;
    for my $event ( 'Topic', 'Topic Creation' )
    {
        $hook = hook_print( $event, \&topic, { 'data' => $hook } );
    }
}

sub topic
{
    my ( $data, undef ) = @_;
    unhook( $data );
    return EAT_XCHAT;
}

hook_print( 'You Join', \&youJoin );