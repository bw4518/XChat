# Author: culb ( A.K.A nightfrog )

use strict;
use warnings;
use Xchat qw( :all );

hook_print( 'Channel Message',
	sub{
		my ( $nick, $what, $mode ) = @{$_[0]};
		my $prefixes = context_info->{nickprefixes};

		if ( $mode and $mode ne '+' and index( $prefixes, $mode ) <= index( $prefixes, '@' )) {
			emit_print( 'Channel Msg Hilight', $nick, $what, $mode );
			return EAT_XCHAT;
		}
	}
);

register ( 'Highlight OPS', '1', 'Highlight OPS' );