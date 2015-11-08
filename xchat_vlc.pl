################################################################################
# Author: culb ( A.K.A nightfrog )
#
# Description:
# Grab VLC' currently playing media information and broadcast it to the current dialog
#
# Version: 003
#
# Date:2014
################################################################################

################################################################################
# TODO
# The information stored in %store is open longer then I think is necessary.
# Find a way to fork LWP without pissing off XChat in Linux and Win32
# Seems different VLC versions use different xml formats. Handle this..
################################################################################

################################################################################
# Version 001, Initial
# Version 002, Let the user choose which order to display the information. Warn of wrong login info
# Version 003, Added -list and -add arguements. Use Perl 5.12 and above
################################################################################

################################################################################
# http://perldoc.perl.org/functions/keys.html
# First paragraph explains why 5.12 and above is needed.
################################################################################
use v5.12.0;

use strict;
use warnings;
use LWP;
use XML::Rules;
use File::Spec;
use Getopt::Long;

use Tie::File;
use Fcntl qw( O_RDWR O_CREAT );

use Xchat qw( :all );

# PORT
# Default is 8080
my $port = '8080';

# Domain or IP
my $url = '127.0.0.1';

# PASSWORD
my $pw = 'none';

#######################################################
#                                                     #
### You as a user are not needed beyond this point. ###
#                                                     #
#######################################################

# Create a file when the script is loaded if it doesn't exist
file_onload_create();

# Time
sub t
{
    +{
        conv => sub
        {
            my $t = shift;

            # Minutes
            if ( $t < 3600 )
            {
                return sprintf( "%02d:%02d", $t / 60, $t % 60 );
            }

            # Hours
            if ( $t and $t >= 3600 and $t < 86400 )
            {
                return sprintf( "%02d:%02d:%02d",
                                $t / 3600,
                                $t % 3600 / 60,
                                $t % 3600 % 60
                              );
            }
        }

        # There was a purpose for this at one point.
        # feedback => sub {}
    };
}

sub file_get
{
    my $file = File::Spec->catfile(
        get_info('xchatdirfs') . '/' . 'vlc_options' . '.conf' );

    # Create the file with defaults if the user deleted it
    if ( not -e $file )
    {
        file_create_add();
    }
    tie my @options, 'Tie::File', $file, mode => O_RDWR;
    return @options;
}

sub file_onload_create
{
    my $file = File::Spec->catfile(
        get_info('xchatdirfs') . '/' . 'vlc_options' . '.conf' );

    if ( not -e $file )
    {
        tie my @options, 'Tie::File', $file, mode => O_CREAT | O_RDWR;

        push @options, 'artist title album genre date bitrate position';

        untie @options;
        prnt 'Created a conf with default values. Please check out /HELP VLC.';
        return 1;
    }
    return;
}

sub file_create_add
{
    my $list = shift;

    my $file = File::Spec->catfile(
        get_info('xchatdirfs') . '/' . 'vlc_options' . '.conf' );

    if ( not -e $file )
    {
        tie my @options, 'Tie::File', $file, mode => O_CREAT | O_RDWR;

        if ( $list )
        {
            push @options, $list;
        }
        if ( not $list )
        {
            push @options, 'artist title album genre date bitrate position';
        }

        untie @options;
        return "CREATE";
    }

    if ( -e $file )
    {
        tie my @options, 'Tie::File', $file, mode => O_RDWR;

        @options = ();
        if ( $list )
        {
            push @options, $list;
        }

        untie @options;
        return "UPDATE";
    }
    return "NULL";
}

# Connect to VLC
sub http_request
{
    my $request = shift;
    my $browser = LWP::UserAgent->new;
    $browser->timeout (0 );
    $browser->credentials( "$url:$port", 'VLC stream', '' => $pw );

    return $browser->get( $request );
}

sub vlc {

    # Arguements
    if ( $_[1][1] )
    {

        my $file = File::Spec->catfile(
            get_info('xchatdirfs') . '/' . 'vlc_options' . '.conf' );

        local @ARGV = split( /\s+/, lc( $_[1][1] ) );
        my @add;
        my $list;

        # Control VLC
        my $stop;
        my $play;
        my $next;
        my $loop;
        my $pause;
        my $empty;
        my $random;
        my $previous;
        my $fullscreen;
        GetOptions(
            'add:s@{1,}' => \@add,
            'list'       => \$list,
            'play'       => sub { $play = 'play' },
            'stop'       => sub { $stop = 'stop' },
            'next'       => sub { $next = 'next' },
            'loop'       => sub { $loop = 'loop' },
            'pause'      => sub { $pause = 'pause' },
            'empty'      => sub { $empty = 'empty' },
            'random'     => sub { $random = 'random' },
            'previous'   => sub { $previous = 'previous' },
            'fullscreen' => sub { $fullscreen = 'fullscreen' }
        );

        if ( $play )
        {
            http_request(
                "http://$url:$port/requests/status.xml?command=pl_$play" );
        }

        if ( $stop )
        {
            http_request(
                "http://$url:$port/requests/status.xml?command=pl_$stop" );
        }

        if ( $loop )
        {
            http_request(
                "http://$url:$port/requests/status.xml?command=pl_$loop" );
        }

        if ( $pause )
        {
            http_request(
                "http://$url:$port/requests/status.xml?command=pl_$pause" );
        }

        if ( $next )
        {
            http_request(
                "http://$url:$port/requests/status.xml?command=pl_$next" );
        }

        if ( $random )
        {
            http_request(
                "http://$url:$port/requests/status.xml?command=pl_$random" );
        }

        if ( $previous )
        {
            http_request(
                "http://$url:$port/requests/status.xml?command=pl_$previous" );
        }

        if ( $empty )
        {
            http_request(
                "http://$url:$port/requests/status.xml?command=pl_$empty" );
        }

        if ( $fullscreen ) {
            prnt http_request(
                "http://$url:$port/requests/status.xml?command=$fullscreen" )
              ->status_line;
        }

        if ( @add )
        {
            @add = split( ',', join( ' ', @add ) );

            my $file_option = file_create_add( @add );

            # Had to create the file
            # User deleted it after the script was loaded
            if ( $file_option eq 'CREATE' )
            {
                prnt "Updated the conf file. Had to create the conf file.";
            }

            # Updated an existing file
            if ( $file_option eq 'UPDATE' )
            {
                prnt "Updated the conf file";
            }

            # Updated an existing file
            if ( $file_option eq 'NULL' )
            {
                prnt "Something went wrong updating the conf file.";
            }
        }

        # List
        if ($list)
        {
            prnt file_get();
        }
    }

    # No arguements.
    if ( not $_[1][1] )
    {

        my $got = http_request( "http://$url:$port/requests/status.xml" );

        #LWP errors
        if ( $got->status_line =~ /^(500 Can't connect to|Error)/ )
        {
            prnt 'Error 500 returned. Web interface is probably not running.';
            return EAT_XCHAT;
        }

        if ( $got->status_line =~ /^401 Unauthorized/ )
        {
            prnt 'Error 401 returned. Wrong login information.';
            return EAT_XCHAT;
        }

        if (     $got->is_success
             and $got->content =~
                     /Password for Web interface has not been set./
           )
        {
            prnt 'Password for Web interface has not been set.';
            return EAT_XCHAT;
        }

        if ( $got->is_success )
        {

            # Reverse how the file was populated
            my @wanted = split( ' ', join( ',', file_get() ) );

            #Need a better way then declaring hashes here.
            my %store;

            my @rules = (

                info => sub {
                    for my $v ( lc( $_[1]->{name} ) )
                    {
                        # Incase there is whitespace for values
                        if ( $_[1]->{_content} =~ /\S/ )
                        {

                            # Date is wrong format. Don't care to see it.
                            if ( lc($v) eq 'date'
                                and $_[1]->{_content} !~ /^(19|20)\d{2}$/ )
                            {
                                next;
                            }

                            # CD. Nothing will show up
                            # show the filename "Audio CD - Track #"
                            if ( $_[1]->{_content} =~ /^Audio CD/ )
                            {
                                push @wanted, 'filename';
                            }

                            my %unhash;
                            $unhash{ lc($_) }++ for @wanted;

                            if ( $unhash{ $v } )
                            {
                                $store{info}->{ $v } =
                                  wspaceTrim( $_[1]->{_content} );
                            }
                        }
                    }
                },
                state => sub
                {
                    $store{extra}->{state} = lc( $_[1]->{_content} );
                },

                length => sub
                {
                    $store{extra}->{length} = $_[1]->{_content};
                },

                time => sub
                {
                    $store{extra}->{time} = $_[1]->{_content};
                }
            );

            my $parser = XML::Rules->new( rules => \@rules );
            $parser->parse( $got->content );

            # VLC is stopped
            if ( lc( $store{extra}->{state} ) eq lc('stopped') )
            {
                prnt 'VLC is stopped.';
                return EAT_XCHAT;
            }

            # VLC is paused
            if ( lc( $store{extra}->{state} ) eq lc('paused') )
            {
                prnt 'VLC is paused';
                return EAT_XCHAT;
            }

            # VLC is playing
            if ( $store{extra}->{state} eq 'playing' )
            {
                if ( grep { $_ eq 'position' } @wanted )
                {
                    # Join isn't needed for the position but I don't want to change it.
                    $store{info}->{position} =
                        join( '-',
                              t->{conv}( $store{extra}->{time} ),
                              t->{conv}( $store{extra}->{length} )
                            );
                }

                #command(   'SAY Current VLC media: '
                #         . join( ', ',
                #                 map { $_ ne 'sample rate' ? "$_: $store{info}{$_}" : () } keys %{$store{info}})
                #               );

                #command(  'SAY VLC media- '
                #         . join( ', ',
                #                 map { "$_: $store{info}{$_}" } values @wanted)
                #               );

                command(   'SAY '
                         . join( ', ',
                                 map { exists $store{info}{$_}
                                       ? "$_: $store{info}{$_}"
                                       : ()
                                     } values @wanted
                               )
                );
                return EAT_XCHAT;
            }
        }
    }
    return EAT_XCHAT;
}

# Handle unwanted whitespace
sub wspaceTrim
{
    my $trim = shift;
    $trim =~ s!^\s+|\s+$!!g;
    $trim =~ s! +! !g;
    return $trim;
}

hook_command(
    'VLC',
    'vlc',
    {
        help_text =>
            'MSG the current channel what you are playing in VLC'
          . "\n\n"
          . "HOW TO USE:\n"
          . "    /VLC       , Display the current song that is playing in VLC.\n"
          . "    /VLC -list , List the current output of the /VLC command.\n"
          . "    /VLC -add  , Add the output you want the /VLC command to use in the conf\n"
          . "        EXAMPLE: To display the artist and position, /VLC -add artist position"
    }
);

register( 'VLC', '003', 'Annoyance' );
