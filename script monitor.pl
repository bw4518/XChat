# Author: Khisanth
# Note  : This is not my script. I just use it a lot

use strict;
use warnings;
use Xchat qw(:all);
use File::ChangeNotify ();
use File::Spec ();
use File::Basename qw(basename);

register(
	"Script Monitor",
	"0.0002",
	"Monitor the script directories for new and changed files",
);

my $THIS_SCRIPT = basename __FILE__;

my $watcher = File::ChangeNotify->instantiate_watcher(
	directories => [
		get_info( "xchatdirfs" ),
		File::Spec->catdir( get_info( "xchatdirfs", "plugins" ) ),
		File::Spec->catdir( get_info( "xchatdirfs", "addons" ) )# Hexchat
		
	],
	filter => qr/\.(?:pl|py)$/,
);

my %action_for = (
	create => sub {
		my ($short_path, $full_path) = @_;
		prnt "Loading $full_path";
		command( "LOAD $full_path" );
	},

	modify => \&reload,

	delete => sub {
		my ($short_path, $full_path) = @_;
		prnt "Unloading $short_path";
		command( "UNLOAD $_[0]" );
	},
);

hook_timer( 500, sub {
	for my $event ( $watcher->new_events() ) {
		if( my $callback = $action_for{ $event->type } ) {
			next unless -f $event->path;
			set_context( get_info 'context');
			$callback->( basename( $event->path ), $event->path );
		}
	}

	return KEEP;
});

sub reload {
	my $short_path = shift;
	my $full_path = shift;
	$full_path =~ tr!/!\\!;
	prnt "Reloading $short_path";
	if( $short_path eq $THIS_SCRIPT ) {
		command( "TIMER 0.5 RELOAD $full_path" );
	} else {
		for( $short_path ) {
			/\.pl/i && do {
				prnt $full_path;
				command( "RELOAD $full_path" );
			};

			/\.py/i && do {
				prnt $full_path;
				command( "PY RELOAD $full_path" );
			};
		}
	}
}