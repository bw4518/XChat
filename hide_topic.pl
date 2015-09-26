use strict;
use warnings;
use Xchat qw( :all );

register(
    'Hide the topic',
    0x1,
    'Hide the topic when you join a channel'
);

hook_print( 'You Join', \&youJoin );

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
#    my ( $data, undef ) = @_;
    my $data = $_[0];
    unhook( $data );
    return EAT_XCHAT;
}
