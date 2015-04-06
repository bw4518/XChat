#Author : nightfrog
#Purpose: Show realnames instead of nicks to mimic 4x4 Evolution
#Version: 1 - Complete rewrite

# Shit that needs accomplished
# 1: If XChat is already and the script gets load,
#    it needs to search the connected networks and
#    if any are one of the networks then handle it ( see code at bottom )
# 2: Handle misc events that I forgot or overlooked
# 3: Fix any mistakes I have made
# 4: USRIP to generate NICK-PORT
# 5: This is a big one... Connect in the sequence the game connects.
#    Usually this requires a source code edit

use strict;
use warnings;
use Xchat qw(:all);

#Add the network(s) this script should work with
my @networkNames = qw( fuzzy personal );

#Don't touch
my %nnr = ();

# |BEGIN| Channel Messages
for my $event ( 'Channel Message', 'Channel Msg Hilight' ) {
	hook_print( $event, \&eventChannelMessage, { 'data' => $event } );
}

sub eventChannelMessage {
	my ( $data, $event )       = @_;
	my ( $nick, $what, $mode ) = @$data;

	#undef $mode if not $mode;
	
	my $network = get_info('network');
	my $channel = get_info('channel');

	if ( grep { lc($_) eq lc($network) } @networkNames ) {
		
		#That dirty little message the client sends when it joins a channel
		#emit a join message here since there is a realname to send in it
		if ( $what =~ m/^\^STATUS\s(.+)/g ) {
			my $realname = ( split( /\^0|\^1/, $1 ) )[0];
			emit_print( 'Join', $realname, $channel, user_info($nick)->{host} );
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
# |END| Channel Message


# |BEGIN| Private Messages
for my $event ( 'Private Message', 'Private Message to Dialog' ) {
	hook_print( $event, \&eventPrivateMessage, { 'data' => $event } );
}

sub eventPrivateMessage {
	my ( $data, $event ) = @_;
	my ( $nick, $what )  = @$data;

	my $network = get_info('network');
	my $channel = get_info('channel');

	if ( grep { lc($_) eq lc($network) } @networkNames ) {

		#If the NICK has not been pushed into the list then
		#it needs to be done and hopefully before the emit.
		if ( not exists $nnr{$network}->{$nick} ) {
			whoGet( $network, $nick );
		}
		elsif ( exists $nnr{$network}->{$nick} ) {
			my $realname = ( split( /\^0|\^1/, $nnr{$network}->{$nick} ) )[0];
			emit_print( $event, $realname, $what );
			return EAT_XCHAT;
		}
	}
	return EAT_NONE;
}
# |END| Private Message


# |BEGIN| Notice
# Opers can use this to communicate without others seeing
# So you can do channel notices and noone will see in game.
for my $event ( 'Notice', 'Notice Send' ) {
	hook_print( $event, \&eventNotice, { 'data' => $event } );
}

sub eventNotice {
	my ( $data, $event ) = @_;
	my ( $nick, $what )  = @$data;
	my $network = get_info('network');

	if ( grep { lc($_) eq lc($network) } @networkNames ) {

		if ( not exists $nnr{$network}->{$nick} and $nick !~ /^#/) {
			whoGet( $network, $nick );
		}
		elsif ( exists $nnr{$network}->{$nick} ) {
			my $realname = ( split( /\^0|\^1/, $nnr{$network}->{$nick} ) )[0];
			emit_print( $event, $realname, $what );
			return EAT_XCHAT;
		}
	}
}
# |END| Notice


# |BEGIN| Channel Modes(h,o,v)
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

sub eventChannelMode {
	my ( $data, $event ) = @_;
	my ( $by, $to )      = @$data;
	my $network = get_info('network');

	if ( grep { lc($_) eq lc($network) } @networkNames ) {
		#Don't need to who both if only one needs to be who'ed
		if ( not exists $nnr{$network}->{$by} ){
			whoGet( $network, $by );
		}
		if ( not exists $nnr{$network}->{$to} ){
			whoGet( $network, $to );
		}
		elsif (exists $nnr{$network}->{$by} and exists $nnr{$network}->{$to} ){
			my $realname0 = ( split( /\^0|\^1/, $nnr{$network}->{$by} ) )[0];
			my $realname1 = ( split( /\^0|\^1/, $nnr{$network}->{$to} ) )[0];
			emit_print( $event, $realname0, $realname1 );
			return EAT_XCHAT;
		}
	}
	return EAT_NONE;
}
# |END| Channel Modes(h,o,v)


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
			#Us
			elsif ( $nameNew ne $nameOld and user_info()->{nick} eq $nick ) {
				$nnr{$network}->{$nick} = $nameNew;
				emit_print( 'Your Nick Changing', $nameOld, $nameNew );
			}
		}
	}
	return EAT_ALL;
});


#Delete a network from the hash when a Server context is closed
hook_print( 'Close_Context', sub {
	my $network  = context_info->{network};

	#Proceed if it is a server context and from out list of networks
	if ( context_info->{type} == '1' and
		 exists $nnr{ $network }     and
         grep { lc($_) eq lc($network) } @networkNames
       ){
			delete $nnr{ $network };
	}
	return EAT_NONE;
});



##########################################################################
##########################################################################
# FIX ME
# A Client sends an RCHG and ^STATUS message when it joins with its realname
# Need to wait until those are done ( since they populate the hash )
# and THEN emit the new JOIN hook
#
# Until then this is pointless...
#
# UPDATE
# So I did some thinking and came up with what you are about to see
# Here is how it works
#
# The real client sends a PRIVMSG beginning with ^STATUS
# when it joins to let the other clients know it joined the channel.
# Since we know it will send this we can use it as a point to emit the join event
#
# 1: The JOIN hook_print hooks the join events for all of XChat
# 2: Check if this happened on a server specified in @networknames (Duh)
# 3: Hook the message and then and use the real name in it to add to the emit
# 4: $1 contains the realname in the ^STATUS message
# 5: Unhook the PRIVMSG event and the JOIN event
# 
#
# While typing these comments I came up with a better solution
# $hookJoin being global doesn't sit well with me.
#
#my $hookJoin; # Global :-(
#$hookJoin =
#hook_print( 'Join', sub {
#	my ( $nick, $channel, $host ) = @{ $_[0] };
#
#	my $network = get_info('network');
#
#	if ( grep { lc($_) eq lc($network) } @networkNames ) {
#		
#		my $hookPRIVMSG;
#		$hookPRIVMSG = hook_server('PRIVMSG', sub{
#			# Host    $_[0][0];
#			# Event   $_[0][1];
#			# Channel $_[0][2];
#			# Message $_[1][3];
#			if (
#					lc($_[0][2]) eq lc($channel)    and
#					$_[1][3] =~ m/^:\^STATUS\s(.+)/ and
#					exists $nnr{$network}->{$nick}
#				)
#				{
#					my $realname = ( split( /\^0|\^1/, $1 ) )[0];
#					emit_print( 'Join', $realname, $channel, $host );
#				}
#			unhook($hookPRIVMSG);
#		});
#		unhook($hookJoin);
#		return EAT_XCHAT;
#	}
#	return EAT_NONE;
#});
##########################################################################
##########################################################################


#EAT the event since we handle it in the channel messages
hook_print( 'Join', sub {	
	my ( $nick, $channel, $host ) = @{ $_[0] };

	my $network = get_info('network');

	if ( grep { lc($_) eq lc($network) } @networkNames and
         $nick =~ /[A-P]{12}|^_/ #A user can potentially hide this event
       ) {
			return EAT_XCHAT;
	}
	return EAT_NONE;
});


hook_print( 'Part', sub {
	my ( $nick, $host, $channel ) = @{ $_[0] };

	my $network = get_info('network');

	if ( exists $nnr{$network}->{$nick} ) {
		my $realname = ( split( /\^0|\^1/, $nnr{$network}->{$nick} ) )[0];
		emit_print( 'Part', $realname, $host, $channel );
		delete $nnr{$network}->{$nick};
		return EAT_XCHAT;
	}
	return EAT_NONE;
});


hook_print( 'Quit', sub {
	my ( $nick, $reason, $host ) = @{ $_[0] };

	my $network = get_info('network');

	if ( exists $nnr{$network}->{$nick} ) {
		my $realname = ( split( /\^0|\^1/, $nnr{$network}->{$nick} ) )[0];
		emit_print( 'Quit', $realname, $reason, $host );
		delete $nnr{$network}->{$nick};
		return EAT_XCHAT;
	}
	return EAT_NONE;
});


hook_print( 'You Join', sub {
	my ( $me, $channel, $host ) = @{ $_[0] };
	my $network = get_info('network');

	#This is the order of the commands the client sends when it joins a channel
	#Taken directly from the irc.log file
	#
	# IN  | :aServer.com 366 NICK #EvoR :End of /NAMES list.
	# OUT | RCHG :nightfrog^0
	# OUT | PRIVMSG #EvoR :^STATUS nightfrog^0
	# OUT | TOPIC #EvoR
	# OUT | WHO #EvoR
	#
	#We need to detect the end of /names and then what we need to do.
	#Let's do this....

	if ( grep { lc($_) eq lc($network) } @networkNames ) {
		my $namesEnd;
		$namesEnd = hook_server('366', sub {
						if ( lc($_[0][3]) eq lc($channel) ){

							# We will who the channel in a little bit and add our realname
							# to the hash then so for now use get_prefs() for our realname
							command( 'QUOTE RCHG :' . get_prefs( 'irc_real_name' ) );
							command( 'QUOTE PRIVMSG ' . $channel . ' :^STATUS ' . get_prefs( 'irc_real_name' ) );

							# Just an example if we were follow the order but XChat does this already
							# and we don't give a shit when we get the topic.
							# command( 'TOPIC ' . $channel ); 

							whoGet( $network, $channel );
	                    }
	                    unhook($namesEnd);
	                });
	}
	return EAT_NONE;
});


hook_print( 'Your Message', sub {
	my ( $nick, $what, $mode ) = @{ $_[0] };
	my $network = get_info('network');

	#Do nothing unless there is a network is in the network list
	return EAT_NONE unless $network;

	#Only continue if the channel message is from one of the wanted networks
	if ( grep { lc($_) eq lc($network) } @networkNames ) {

		#If the NICK has not been pushed into the list then
		#it needs to be done and hopefully before the emit.
		if ( not exists $nnr{$network}->{$nick} ) {
			whoGet( $network, $nick );
		}
		elsif ( exists $nnr{$network}->{$nick} ) {
			my $realname = ( split( /\^0|\^1/, $nnr{$network}->{$nick} ) )[0];
			emit_print( 'Your Message', $realname, $what, $mode );
			#user_info( $nick )->{realname} <-- Not reliable
			return EAT_XCHAT;
		}
	}
	return EAT_NONE;
});


sub whoGet {

	#Handle channel and nick who's here
	#$channel can be either a channel or nick
	my ( $network, $channel ) = @_;

	if ( $network and $channel ) {    #Make sure...

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
                          return EAT_ALL;
					  });

		#At the end of the /who unhook each numeric event
		my $who_end;
		$who_end = hook_server( '315', sub {
					   unhook($hooked_who);
				       unhook($who_end);
				       return EAT_ALL;
			       });
	}
}


register(
	'Realnames',
	0x3DFB3F,
	'Replace NICKS in the Text Events with realnames to mimic 4x4 Evolution'
);


__END__

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