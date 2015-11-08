# nightfrog
# Move whois to the server tab

use strict;
use warnings;
use Xchat qw( :all );

# No particular order
for my $event ( 'WhoIs Authenticated',
                'WhoIs Away Line',
                'WhoIs Channel/Oper Line',
                'WhoIs End',
                'WhoIs Identified',
                'WhoIs Idle Line',
                'WhoIs Idle Line with Signon',
                'WhoIs Name Line',
                'WhoIs Real Host',
                'WhoIs Server Line',
                'WhoIs Special' )
{
    hook_print( $event, \&whoisToServer, { 'data' => $event } );
}

sub whoisToServer
{
    my ( $data, $event ) = @_;
    my $id      = get_info 'id';
    my $context = get_info 'context';

    # Got to the server tab
    switchToServer( $id );
    emit_print( $event, @$data );

    set_context $context;
    return EAT_XCHAT;
}

sub switchToServer
{
    my $connectionID = shift;
    for my $tab ( get_list 'channels' )
    {
        if( $tab->{ id } == $connectionID && $tab->{ type } == 1 )
        {
            return set_context $tab->{ context };
        }
    }
    return;
}

register(
    'Whois to Server',
    0x41569F,
    'Move whois events to the server tab'
);