#Author : nightfrog
#Purpose: Show realnames instead of nicks to mimic 4x4 Evolution
#Version: 1 - Complete rewrite

use strict;
use warnings;
use Xchat qw(:all);
use Data::Dumper;

#Add the network(s) this script should work with
my @networkNames = qw( fuzzy personal );

#Don't touch
my %nnr = ();

#|BEGIN| Channel Messages
for my $event ( 'Channel Message', 'Channel Msg Hilight' ) {
	hook_print( $event, \&eventChannelMessage, { 'data' => $event } );
}

sub eventChannelMessage {
	my ( $data, $event )       = @_;
	my ( $nick, $what, $mode ) = @$data;

	my $network = get_info('network');
	my $channel = get_info('channel');

	if ( grep { lc($_) eq lc($network) } @networkNames ) {

		#That dirty little message the client sends when it joins a channel
		if ( $what =~ m/^\^STATUS\s(.+)/g ) {
			return EAT_XCHAT;
		}

		#If the NICK has not been pushed into the list then
		#it needs to be done and hopefully before the emit.
		if ( not exists $nnr{$network}->{$nick} ) {
			whoGet( $network, $nick );
		}
		elsif ( exists $nnr{$network}->{$nick} ) {
			my $realname = ( split( /\^0|\^1/, $nnr{$network}->{$nick} ) )[0];
			emit_print( $event, $realname, $what, $mode );
			return EAT_XCHAT;
		}
	}
	return EAT_NONE;
}

#|END| Channel Message

#|BEGIN| Channel Modes(h,o,v)
#To keep things simple and short(KISS)
#Add "Text Events" that are ONLY mode changes
#This would be op, halfop, voice and so on...
for my $event (
	'Channel DeOp',
	'Channel DeHalfOp',
	'Channel DeVoice',
	'Channel Half-Operator',
	'Channel Operator',
	'Channel Voice'){
	hook_print( $event, \&eventChannelMode, { 'data' => $event } );
}

sub eventMode {
	my ( $data, $event ) = @_;
	my ( $by, $to )    = @$data;
	my $network = get_info('network');

	if ( grep { lc($_) eq lc($network) } @networkNames and
		 exists $nnr{$network}->{$by}                  and
		 exists $nnr{$network}->{$to} )
	{
		my $realname0 = ( split( /\^0|\^1/, $nnr{$network}->{$by} ) )[0];
		my $realname1 = ( split( /\^0|\^1/, $nnr{$network}->{$to} ) )[0];
		emit_print( $event, $realname0, $realname1 );
		return EAT_XCHAT;
	}
	return EAT_NONE;
}

#|END| Channel Modes(h,o,v)

#Add or change a user when the /RCHG command is executed
hook_server( 'RCHG', sub {
	my $nick     = substr $_[0][0], 1;
	my $realname = substr $_[1][2], 1;
	my $network  = get_info('network');

	if ( grep { lc($_) eq lc($network) } @networkNames ) {

		if ( not exists $nnr{$network}->{$nick} ) {
			$nnr{$network}->{$nick} = $realname;
		}
		elsif ( exists $nnr{$network}->{$nick} ) {
	
			#Only need to see when the actual realname changes
			#and not the lap count and other shit in the realnames	
			my $nameNew = ( split( /\^0|\^1/, $realname ) )[0];
			my $nameOld = ( split( /\^0|\^1/, $nnr{$network}->{$nick} ) )[0];

			#Them
			if ( $nameNew ne $nameOld and user_info()->{nick} ne $nick ) {
				$nnr{$network}->{$nick} = $nameNew;
				emit_print( 'Change Nick', $nameOld, $nameNew );
			}
				#US
				elsif ( $nameNew ne $nameOld and user_info()->{nick} eq $nick ) {
					$nnr{$network}->{$nick} = $nameNew;
					emit_print( 'Your Nick Changing', $nameOld, $nameNew );
				}
		}
	}
	return EAT_ALL;
});

hook_print( 'You Join', sub {
	my ( $me, $channel, $host ) = @{ $_[0] };
	whoGet( get_info('network'), $channel );
	return EAT_NONE;
});

hook_print( 'Your Message', sub {
	my ( $nick, $what, $mode ) = @{ $_[0] };
	my $network = get_info('network');

	#Do nothing unless there is a network is in the network list
	return EAT_NONE unless $network;

	#Only continue if the channel message is from one of the wanted networks
	if ( grep { lc($_) eq lc($network) } @networkNames and
		 exists $nnr{$network}->{$nick} )
	{
		my $realname = ( split( /\^0|\^1/, $nnr{$network}->{$nick} ) )[0];
		emit_print( 'Your Message', $realname, $what, $mode );
		#user_info( $nick )->{realname} <-- Not reliable
		return EAT_XCHAT;
	}
	return EAT_NONE;
});

sub whoGet {

	#Handle channel and nick who's here
	#$channel can be either a channel or nick
	my ( $network, $channel ) = @_;

	if ( $network and $channel ){     #Make sure...

		command( 'WHO ' . $channel ); #Wasn't needed before

		my $hooked_who;
		$hooked_who = hook_server('352', sub {
                          #$_[0][3]  -- CHANNEL
                          #$_[0][7]  -- NICK
                          #$_[1][10] -- REALNAME
                          if ( lc( $_[0][3] ) eq lc($channel) or
                               lc( $_[0][7] ) eq lc($channel)
                             ){
                                  $nnr{$network}->{ $_[0][7] } = $_[1][10];
                             }
                          return EAT_XCHAT;
					  });

		#At the end of the /who unhook each numeric event
		my $who_end;
		$who_end = hook_server( '315', sub {
					   unhook($hooked_who);
				       unhook($who_end);
				       return EAT_XCHAT;
			       });
	}
}

=pod

#FIX ME!!
#Might not be broke but I forget what needed fixed.
#I think it just needs a timer
#Populates the hash if the script is loaded while xchat is already running and connected to the network(s)

init_0();
sub init_0{
	my $context = get_info 'context';
	for my $tab ( get_list 'channels' ) {
		if( $tab->{ type } == 2 and grep { lc( $_ ) eq lc( $tab->{ network } ) } @networkNames ){
			for my $users ( get_list 'users' ) {
				# Need to set each window to get the users from
				set_context( $tab->{ context } );
				my $realname = strip_code( $users->{ realname } );
				if( not $nnr{ $tab->{ network } }->{ $users->{ nick } } ){
					$nnr{ $tab->{ network } }->{ $users->{ nick } } = $realname;
				}
			}
		}
	}
	# Go back to the original window
	set_context $context;
}


init_1();
sub init_1{
	my $context = get_context;
	my %tabs = ();
	for my $tab ( get_list "channels" ) {
		my $network = $tab->{ network };
		push @{ $tabs{ $network } }, $tab if $tab->{ type } == 2 and grep { lc( $_ ) eq lc( $tab->{ network } ) } @networkNames;
	}
	
	for my $values ( values %tabs ) {
		for my $tab ( @$values ) {
			#Add each NICK and REAL NAME from the /who list to the %nnr hash
			my $hooked_who;
			$hooked_who = hook_server( '352',
				sub{
					my $target_channel = $_[0][3];
					set_context $tab->{ context };
					if( lc( $target_channel ) eq lc( $tab->{ channel } ) ) {
						my $nick = $_[0][7];
						my $realname = strip_code( $_[1][10] );
						$nnr{ $tab->{ network } }->{ $nick } = $realname;
					}
				}
			);
				#At the end of the /who unhook each numeric event
				my $who_end;
				$who_end = hook_server( '315',
					sub{
						unhook( $hooked_who );
						unhook( $who_end );
					}
				);
		}
	}
	set_context $context;
}
=cut

register( 'Realnames', 1,
	'Replace NICKS in the Text Events with realnames to mimic 4x4 Evolution' );
