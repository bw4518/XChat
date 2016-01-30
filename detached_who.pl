# Author: culb ( A.K.A. nightfrog )
# Show the output of /WHO in a separate window
#
# Usage: Type /DEWHO in a channel or PM context
#
# TODO: Let the user supply a nick or channel

use strict;
use warnings;
use Gtk2 -init;
use Gtk2::SimpleList;
use Xchat qw( :all );

#Keep track of windows to destroy when the script is unloaded
my @record;

register(
    'Detached WHO',
    0x1,
    'Create a detached window with the output of /WHO',
    sub{ $_->destroy for @record; }
);


use constant TRUE  => 1;
use constant FALSE => 0;

hook_command 'DEWHO' => sub
{
    my $contextType = context_info->{type};

    if( $contextType == 2 or $contextType == 3 )
    {
        my $window = Gtk2::Window->new;
        $window->set_title( 'Detached WHO' );
        $window->set_default_size( 500, 300 );

        my $hBox = Gtk2::HBox->new;
        $window->add( $hBox );

        my $sList = Gtk2::SimpleList->new( 'Network'   => 'text',
                                           'Channel'   => 'text',
                                           'User name' => 'text',
                                           'Host'      => 'text',
                                           'Server'    => 'text',
                                           'Nick'      => 'text',
                                           'Modes'     => 'text',
                                           'HOPS'      => 'text',
                                           'Real name' => 'text' );

        if ( my $network = get_info 'network' and my $channel = get_info 'channel' )
        {
            command( 'QUOTE WHO ' . $channel );

            my $hookedWho;
            $hookedWho = hook_server '352' => sub
                         {
                             my $hops = $_[0][9];
                             $hops =~ s/^://;
                             push @{ $sList->{data} }, [ $network, $_[0][3], $_[0][4],
                                                         $_[0][5], $_[0][6], $_[0][7],
                                                         $_[0][8], $hops   , $_[1][10] ];
                             return EAT_XCHAT;
                         };

            my $hookedWhoEnd;
            $hookedWhoEnd = hook_server '315' => sub
                            {
                                unhook $hookedWho;
                                unhook $hookedWhoEnd;
                                return EAT_XCHAT;
                            };
        }

        #Editable fields for copying information
        $sList->set_column_editable( $_, TRUE ) for 0..8;

        #Reorder rows
        $sList->set_reorderable( TRUE );

        #Resize columns
        map { $_->set_resizable( TRUE ) } $sList->get_columns;

        #Scrollable window
        my $scrolled = Gtk2::ScrolledWindow->new;
        $scrolled->set_policy( 'automatic', 'automatic' );
        $scrolled->add( $sList );
        $hBox->add( $scrolled );

        #Show the window
        $window->show_all;

        #Keep track of windows to destroy
        push @record, $window if $window;
    }

    return EAT_XCHAT;
},
{
    help_text => '/DEWHO - Create a detached window with the output of /WHO'
};