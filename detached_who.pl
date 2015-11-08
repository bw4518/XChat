# Author: culb ( A.K.A nightfrog )
#Show the output of /WHO in a separate window

use strict;
use warnings;
use Gtk2 -init;
use Gtk2::SimpleList;
use Xchat qw( :all );

my $window;
my @record;


register(
    'Detached who',
    0x1,
    'Create a detached window with the output of /WHO',
    sub{ $_->destroy for @record; }
);


use constant TRUE  => 1;
use constant FALSE => 0;


hook_command( 'DEWHO',
    sub
    {

        #Channels or dialogs
        if( context_info->{type} == 2 or context_info->{type} == 3 )
        {
            $window = Gtk2::Window->new;
            $window->set_title ( 'Detached WHO' );
            $window->set_default_size ( 500, 250 );

            my $hbox = Gtk2::HBox->new;
            $window->add ( $hbox );

            my $slist = Gtk2::SimpleList->new ( 'Network'   => 'text',
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

                my $hooked_who;
                $hooked_who = hook_server( '352',
                    sub
                    {
                        push @{ $slist->{data} }, [ $network, $_[0][3], $_[0][4], $_[0][5],
                                                  $_[0][6], $_[0][7], $_[0][8], $_[0][9], $_[1][10] ];
                        return EAT_XCHAT;
                    });

                my $who_end;
                $who_end = hook_server( '315',
                    sub
                    {
                        unhook( $hooked_who );
                        unhook( $who_end );
                        return EAT_XCHAT;
                    });
            }





            #Editable fields for copying information
            $slist->set_column_editable ( $_, TRUE ) for 0..8;

            #Reorder rows
            $slist->set_reorderable ( TRUE );

            #Resize columns
            map { $_->set_resizable ( TRUE ) } $slist->get_columns;

            #Scrollable window
            my $scrolled = Gtk2::ScrolledWindow->new;
            $scrolled->set_policy ( 'automatic', 'automatic' );
            $scrolled->add ( $slist );
            $hbox->add ( $scrolled );

            #Show the window
            $window->show_all;

            #Keep track of windows to destroy
            push @record, $window if $window;
        }

        return EAT_XCHAT;

    },
    {
        help_text => 'Create a detached window with the output of /WHO'
    }
);
