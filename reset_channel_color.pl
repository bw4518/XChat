# Author: culb ( A.K.A nightfrog )
#
# Keep the channel color in the channel tree the same as if no activity happened
# when a normal message or action (/me) is received ny users that match the
# network, channel, and hostmask that you specify. Wildcards are valid.
#
# Note: I don't use this and was designed as someone wanted.
# TODO: Create a user friendly config so users don't have
# TODO: to manually edit the array in a hash in a hash

use strict;
use warnings;
use Xchat qw( :all );


register(
    'Channel Tab Color',
    0x2,
    'Remove channel color activity when certain users speak'
);


#hash of networks->channels->hostmasks that wont change the color of the channel
#ONLY USE LOWERCASE NETWORK AND CHANNEL NAMES
my %list =
(
    'efnet' => #Network as listed in the network list
    {
        '#channel0' => [ 'user1!user1@*', 'user2!?????@user2.com' ],
        '#channel1' => [ '*!*@user?.com', 'user2!user2@user2.com' ]
    },
    'freenode' => #Network as listed in the network list
    {
        '#channel0' => [ 'user1!user1@*', 'user2!?????@user2.com' ],
        '#channel1' => [ '*!*@user?.com', 'user2!user2@user2.com' ]
    }
);


for my $event ( 'Channel Message', 'Channel Action' )
{
    hook_print( $event, \&color_tab );
}


sub color_tab
{
    my $network = lc get_info 'network';
    my $channel = lc get_info 'channel';

    my $nick = $_[0][0];

    #Check if XChat has the users information
    if(not defined user_info( $nick ) or not user_info( $nick )->{host})
    {
        #Get the information for next time
        command 'QUOTE WHO ' . $channel;
        return EAT_NONE;
    }

    #Create a hostmask to compare with
    my $userMask = $nick . '!' . user_info( $nick )->{host};

    for my $value ( 0 .. $#{ $list{$network}->{$channel} } )
    {
        if( compare_hostmask( $list{$network}->{$channel}[$value], $userMask ) )
        {
            command 'gui color 0';
        }
    }

    return EAT_NONE;
}

#Taken from IRC::Utils
sub uc_irc
{
    my ( $value, $type ) = @_;
    return if not defined $value;
    $type = 'rfc1459' if not defined $type;
    $type = lc $type;

    if( $type eq 'ascii' )
    {
        $value =~ tr/a-z/A-Z/;
    }
    elsif( $type eq 'strict-rfc1459' )
    {
        $value =~ tr/a-z{}|/A-Z[]\\/;
    }
    else
    {
        $value =~ tr/a-z{}|^/A-Z[]\\~/;
    }

    return $value;
}

#Taken from IRC::Utils
sub compare_hostmask
{
    my ( $mask, $match, $mapping ) = @_;
    return if not defined $mask || not length $mask;
    return if not defined $match || not length $match;

    my $umask = quotemeta uc_irc( $mask, $mapping );
    $umask =~ s/\\\*/[\x01-\xFF]{0,}/g;
    $umask =~ s/\\\?/[\x01-\xFF]{1,1}/g;
    $match = uc_irc( $match, $mapping );

    return 1 if $match =~ /^$umask$/;
    return;
}
