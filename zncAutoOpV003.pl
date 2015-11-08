#Author: culb ( A.K.A nightfrog )
#
#Description:
#AUTH to ZNC autoop
#
#Version: 003
#
#Date:2014

# HOW TO USE THIS SCRIPT #
#
# Add a user
# /aoadd -n NETWORK -u USER -pw PASSWORD
#
# Remove a user
# /aodel -n NETWORK -u USER
#
# Remove a network
# /aodel -n NETWORK

#Changes:
# 002:
#  I forget
#
# 003:
#  Add and delete users/networks within XChat
#  Create the conf file if it doesn't exist
#  Forgot to EAT_XCHAT in confAdd() and confDelete() to hide the "Unknown command" error
#  Delete the network from the conf if no user exists
#  Add /aolist command to list the contents of the conf

use strict;
use warnings;
use File::Spec;
use Tie::IxHash;
use Getopt::Long;
use Xchat qw( :all );
use Digest::MD5 qw( md5_hex );
use Config::General qw( ParseConfig SaveConfig );
#use Data::Dumper;

my $fileConf = File::Spec->catfile( get_info( 'xchatdirfs' ) . '/' . 'znc_autoop' . '.conf' );
use Win32::Process;
#Create file if it doesn't exist when the script is loaded
fileCreate();

hook_print(
	'Notice',
	sub {
		my $nick    = lc( $_[0][0] );
		my $network = lc( get_info 'network' );
    
		if ( $_[0][1] =~ m/^!ZNCAO\sCHALLENGE\s([\x21\x3F\x2E\x2C\x3A\x3B\x2F\x2A\x2D\x2B\x28\x29\w]{32})$/ ){
			server_tab( get_info 'id' );# Show everything in the server tab
			prnt "ZNC Autoop AUTH requested from $nick.";
			if ( exists authGet()->{$network}->{$nick}->{key} ) {
				command(
					"QUOTE NOTICE $nick :!ZNCAO RESPONSE "
					. md5_hex( authGet()->{$network}->{$nick}->{key} . "::" . $1 )
				);
				prnt "ZNC Autoop AUTH respond to $nick."
			}
			return EAT_XCHAT;
		}
		return EAT_NONE;
	}
);

sub confAdd{
	if ( $_[1][1] ) {
		local @ARGV = split( /\s+/, lc( $_[1][1] ) );
		my $key;
		my $nick;
		my $network;
		GetOptions(
			'n:s' => \$network,
			'u:s' => \$nick,
			'k:s' => \$key
		);

		#Create the conf. User may have deleted the conf after loading this script
		fileCreate();
    
		my $h = authGet();
	    $h->{$network}{$nick}{key} = $key;
		authChange( %{$h} );
	}
	return EAT_XCHAT;
}

sub confDelete{
	if ( $_[1][1] ) {
	  	local @ARGV = split( /\s+/, lc( $_[1][1] ) );
		my $nick;
		my $network;
		GetOptions(
	    	'u:s' => \$nick,
			'n:s' => \$network
		);

		my $h = authGet();

		# Remove network
		delete $h->{$network} if $network and not $nick;

		# Remove nick from network
		delete $h->{$network}{$nick} if $nick and $network;

		# Remove the network if it is empty
		delete $h->{$network} if not keys %{$h->{$network}};

		#Write the changes to the conf
		authChange( %{$h} );
	}
	return EAT_XCHAT;
}

sub authGet{
	my %authUsers =
	ParseConfig(
		-Tie => "Tie::IxHash",
		-ConfigFile => $fileConf
	);
  return \%authUsers;
}

sub authChange{
	my %h = @_;
	SaveConfig( $fileConf, \%h );
}

sub confList{
	use List::Util qw( max );
	my $allUsers = authGet();
	
	if( keys $allUsers ){
		
		my $lengthNet = 7;
		my $lengthNetComp = max map {length} keys $allUsers;
		if( $lengthNetComp > $lengthNet ){
			$lengthNet = $lengthNetComp;
		}
	
		my $lengthUser = 4;
		my $lengthUserComp = max map {length} userLength( %{$allUsers} );
		if( $lengthUserComp > $lengthUser ){
			$lengthUser = $lengthUserComp;
		}
	
		my $lengthKey = 3;
		my $lengthKeyComp = max map {length} keyLength( %{$allUsers} );
		if( $lengthKeyComp > $lengthKey ){
			$lengthKey = $lengthKeyComp;
		}
	
		server_tab( get_info 'id' );# Show everything in the server tab
		
		prntf "+-%s-+-%s-+-%s-+", '-' x $lengthNet, '-' x $lengthUser, '-' x $lengthKey;
		prntf "| %-${lengthNet}s | %-${lengthUser}s | %-${lengthKey}s |", 'Network', 'User', 'Key';
		prntf "+-%s-+-%s-+-%s-+", '-' x $lengthNet, '-' x $lengthUser, '-' x $lengthKey;
		for my $k( sort keys $allUsers ){
			while( my ( $keys, $values ) = each( $allUsers->{$k} ) ){
				prntf "| %-${lengthNet}s | %-${lengthUser}s | %-${lengthKey}s |",
				$k, $keys, values $values;
			}
		}
		prntf "+-%s-+-%s-+-%s-+", '-' x $lengthNet, '-' x $lengthUser, '-' x $lengthKey;
	}
	else{
		prnt 'There are no users in the autoop conf file to list. "/help AOADD" for more information';
	}
	return EAT_XCHAT;
}

sub userLength{
	my %list = @_;
	my @giveBack;
	for my $keys( keys %list ){
		for my $user ( keys %{$list{$keys}} ){
			push @giveBack, $user;
		}
	}
	return @giveBack;
}

sub keyLength{
	my %list = @_;
	my @giveBack;
	for my $keys( keys %list ){
		for my $values ( values %{$list{$keys}} ){
			push @giveBack, values $values;
		}
	}
	return @giveBack;
}

sub fileCreate{
	if ( not -e $fileConf ){
		open ( my $fh, '>', $fileConf )
			or prnt "AUTOOP script couldn't create the nessesary file. $!\n";
		close $fh or prnt "Nothing to close";
	}
}

sub server_tab{
	my $connection_id = shift;
	for my $tab ( get_list 'channels' ) {
		if ( $tab->{id} == $connection_id && $tab->{type} == 1 ) {
			return set_context( $tab->{context} );
		}
	}
	return;
}

hook_command(
	'AOADD',
	'confAdd',
	{ help_text => "Usage: /AOADD [-n <NETWORK>] [-u <USER>] [-k <KEY>]" }
);

hook_command(
	'AODEL',
	'confDelete',
	{ help_text => help_format_aodel() }
);

hook_command(
	'AOLIST',
	'confList',
	{ help_text => "Usage: /AOLIST" }
);

sub help_format_aodel{
return qq(Usage:
    Remove a network ( WARNING: This deletes the network and ALL users in it. )
    /AODEL [-n <NETWORK>]

    Remove a user from a network
    /AODEL [-n <NETWORK>] [-u <USER>])
}

register(
	'ZNC autoop authenticate',
	'003',
	'Auth to a ZNC autoop notice'
);



__END__
Perl notes:
	Tie::IxHash will need to be installed.
	Config::General will need to be installed.