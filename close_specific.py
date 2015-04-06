#Author culb ( nightfrog )

__module_name__ = 'Close Dialog'
__module_author__ = 'culb'
__module_version__ = '1'
__module_description__ = 'Close a Dialog by name'

import xchat

def closepm( word, word_eol, userdata ):
	for v in xchat.get_list( 'channels' ):
		if v.type == 3 and v.channel.lower() == word[1].lower():
			v.context.command( "CLOSE" );

	return xchat.EAT_XCHAT
 
xchat.hook_command(
	'closepm',
	closepm,
	help='closepm NICK'
)