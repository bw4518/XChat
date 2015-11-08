# Author: culb ( A.K.A nightfrog )
#Create a command 'DEWHO' to show the output of /WHO in a separate window

use strict;
use warnings;
use Gtk2 -init;
use Gtk2::SimpleList;
use Xchat qw( :all );


#Keep a record of windows to destroy
my @record;


register(
    'Detached WHO',
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
            my $window = Gtk2::Window->new;
            $window->set_title( 'Detached WHO' );
            $window->set_default_size( 500, 250 );

            my $hbox = Gtk2::HBox->new;
            $window->add( $hbox );

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
                #$channel is a channel or nick depending the on context
                command( 'QUOTE WHO ' . $channel );

                my $hook_who;
                $hook_who = hook_server( '352',
                sub
                {
                    #Remove the leading : from the hops
                    my $string = $_[0][9];
                    $string =~ s/^://;

                    push @{ $slist->{data} }, [ $network, $_[0][3], $_[0][4], $_[0][5],
                                                $_[0][6], $_[0][7], $_[0][8], $string , $_[1][10] ];
                });

                my $hook_who_end;
                $hook_who_end = hook_server( '315',
                sub
                {
                    unhook $hook_who;
                    unhook $hook_who_end;
                });
            }





            #Editable fields for copying information
            $slist->set_column_editable( $_, TRUE ) for 0..8;

            #Reorder rows
            $slist->set_reorderable( TRUE );

            #Resize columns
            map { $_->set_resizable( TRUE ) } $slist->get_columns;

            #Scrollable window
            my $scrolled = Gtk2::ScrolledWindow->new;
            $scrolled->set_policy( 'automatic', 'automatic' );
            $scrolled->add( $slist );
            $hbox->add( $scrolled );

            #Show the window
            $window->show_all;

            #Keep a record of windows to destroy
            push @record, $window if $window;
        }

        return EAT_XCHAT;

    },
    {
        help_text => 'Create a detached window with the output of /WHO'
    }
);
