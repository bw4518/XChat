#Author: culb ( A.K.A nightfrog )
#
#Description:
#Sysinfo for Windows
#
#Version: 002
#
#Date:2014

#Changes:
# 002:
#  Added seconds and weeks to uptime output. Uses Win32::Uptime for compatibilty across Windows version
#  Check all values returned for definition or return a generic value.
#  Remove leading and trailing whitespaces from vales reported by windows.
#  Convert multiple whitespaces to a single whitespace in values reported by Windows.
#  Added /cnetid command to list all NIC's for the user to choose which to display.
#  Check all integers for a negative value and convert to positive. Windows returns negatives at times.

use strict;
use warnings;
use Xchat qw(:all);
#use Data::Dumper;

# Load the script and use /cnetid to get the id of the nic you would like to display
# Not the most efficient but it's easier then explaining how the user can get the ID.
my $nicID = 11;

# Need the proper priveledges
# Using Win32::TieRegistry without this will throw errors
#BEGIN{
use Win32::TieRegistry( Delimiter=>"\\", ArrayValues=>0 );
$Registry = $Registry->Open('', {Access => 0x2000000});
#}


# Portability
sub conv {
	use Win32::OLE;
	use Win32::Uptime;# Makes life easier.
	my $wmi = Win32::OLE->GetObject( "WinMgmts://./root/cimv2" );
	+{ 
		time =>
			sub{# MUST be seconds passed to this function.
				my $t = Win32::Uptime::uptime() / 1000;
	
				# negative to positive
				$t = neg2pos($t) if $t < 0;
				
				#Doubt seconds will ever be used. Just incase though
				if($t and $t < 60){
					return 'Uptime: ' . $t . 'S';
				}	
				if($t and $t >= 60 and $t < 3600){
					return 'Uptime: ' . sprintf("%1dM %1dS", $t/60, $t%60);
				}	
				if($t and $t >= 3600 and $t < 86400){
					return 'Uptime: ' . sprintf("%1dH %1dM %1dS", $t/3600, $t%3600/60, $t%3600%60 );	
				}
				if($t and $t >= 86400 and $t < 604800){
					return 'Uptime: ' . sprintf("%1dD %1dH %1dM %1dS", $t/86400, $t%86400/3600, $t%3600/60, $t%3600%60);
				}
				if($t and $t >= 604800){
					return 'Uptime: ' . sprintf("%1dW %1dD %1dH %1dM %1dS", $t/604800, $t%604800/86400, $t%86400/3600, $t%3600/60, $t%3600%60);
				}
				return 'Uptime: Unknown';
			},
			
		os =>
			sub{
				for my $v (Win32::OLE::in $wmi->InstancesOf('Win32_OperatingSystem')){
					if($v->{Caption}){
						my $return = wspaceTrim($v->{Caption});
						return "OS: $return";
					}
				}
				return 'OS: Unknown';
			},
			
		cpu =>
			sub{
				#return $Registry->{"HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0\\ProcessorNameString"};
				for my $v (Win32::OLE::in $wmi->InstancesOf('Win32_Processor')){
					if ( $v->{Name} ){
						my $return = wspaceTrim($v->{Name});
						return "CPU: $return";
					}
				}
				return "CPU: Unknown";
			},

		cpu1 =>
			sub{
				return $Registry->{"HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0\\ProcessorNameString"};
			},
			
		mem =>
			sub{
				for my $v (Win32::OLE::in $wmi->InstancesOf('Win32_OperatingSystem')){
					my $free  = $v->{FreePhysicalMemory};
					my $total = $v->{TotalVisibleMemorySize};
	
					if($total and $free){
						
						# negative to positive
						$free  = neg2pos($free) if $free < 0;
						$total = neg2pos($total) if $total < 0;
	
						return
							'Ram: '
							. sprintf("%.3gGb", $free / 1024000)
							. '-'
							. sprintf("%.3gGb", $total / 1024000)
							. ' '
							. sprintf("%.0f%%", int(100 * $free / $total))
					}
				}
				return 'Ram: Unknown';
			},
			
		vcard =>
			sub{
				# Window 8/8.1 returns negative... Why?
				for my $v (Win32::OLE::in $wmi->InstancesOf('Win32_VideoController')){
					my $name = $v->{name};
					my $vRam = $v->{AdapterRam};
	prnt $vRam;
					# negative to positive
					$vRam = neg2pos($vRam) if $vRam < 0;
		
					if($name and $vRam){
						my $return = wspaceTrim($name);
						# mb
						return "Video: $return @ " . sprintf("%.3gMb", $vRam / 1048576) if $vRam >= 1048576 and $vRam < 1073741824;
						# gb
						return "Video: $return @ " . sprintf("%.3gGb", $vRam / 1073741824) if $vRam >= 1073741824;
					}
				}
				return 'Video: Unknown';
			},
			
		hdd =>
			sub{
				my %rvalue;
				for my $v (Win32::OLE::in $wmi->InstancesOf('Win32_LogicalDisk')){
					if($v->{name} and $v->{size} and $v->{DriveType} == 3){
						my $size = $v->{size};
	
						# negative to positive
						$size = neg2pos($size) if $size < 0;
					
						$rvalue{$v->{name}} = sprintf("%.3gGB", $size / 1073741824);
					}
				}
				if(not %rvalue){
					$rvalue{'Unknown'} = 'Drive';
				}
				return 'HDD ' . join(', ', map{"$_ $rvalue{$_}"}sort keys %rvalue);
			},
			
		net =>
			sub{
				for my $v  (Win32::OLE::in $wmi->InstancesOf('Win32_NetworkAdapter')){
					my $speed = $v->{Speed};
	
					# Is the NIC being used if $v->{Speed} returns true?
					# NIC not being used???
					if ($v->{DeviceID} == $nicID and not $speed){
						my $return = wspaceTrim($v->{Name});
						return 'NIC: ' . $return;
					}
					# NIC being used???
					if ($v->{DeviceID} == $nicID and $speed){
						
						# negative to positive
						$speed = neg2pos($speed) if $speed < 0;
					
						my $return = wspaceTrim($v->{Name});
						# mb
						return 'NIC: ' . $return . " @ " . $speed / 1000000 .  'MB' if $speed >= 1000000 and $speed < 1000000000;
						# gb
						return 'NIC: ' . $return . " @ " . $speed / 1000000000 .  'GB' if $speed >= 1000000000;	
					}
				}
				return 'NIC: Unknown';
			},
			
			
		nspeed =>
			sub{
				for my $v  (Win32::OLE::in $wmi->InstancesOf('Win32_PerfRawData_Tcpip_NetworkInterface')){
						#prnt $v->{CurrentBandwidth};
						return $v->{BytesReceivedPerSec};
				}
			},
			
			
		battery =>
			sub{
				my %status = (
					1  => 'Discharging',
					2  => 'AC Outlet',
					3  => 'Fully Charged',
					4  => 'Low',
					5  => 'Critical',
					6  => 'Charging',
					7  => 'Charging and High',
					8  => 'Charging and Low',
					9  => 'Charging and Critical',
					10 => 'Undefined',
					11 => 'Partially Charged'
				);
				#my %tech = (
				#	1 => 'Other',
				#	2 => 'Unknown',
				#	3 => 'Lead acid',
				#	4 => 'Nickel Cadmium',
				#	5 => 'Nickel Metal Hydride',
				#	6 => 'Lithium-ion',
				#	7 => 'Zinc Air',
				#	8 => 'Lithium Polymer'
				#);
				for my $v (Win32::OLE::in $wmi->InstancesOf('Win32_Battery')){
					my $remaining = $v->{EstimatedChargeRemaining};
	
					# No amount remaining returned
					if($v->{BatteryStatus} and not $remaining){
						return 'Battery:: ' . $status{$v->{BatteryStatus}};
					}
					
					# Amount remaining returned
					if($v->{BatteryStatus} and $remaining){
						
						# negative to positive
						$remaining = neg2pos($remaining) if $remaining < 0;
	
						return "Battery: $status{$v->{BatteryStatus}} @ $remaining%";
					}
				}
				return 'Battery: Unknown';
			},
			
		sound =>
			sub{
				for my $v (Win32::OLE::in $wmi->InstancesOf('Win32_SoundDevice')){
					if($v->{Description}){
						my $return = wspaceTrim($v->{Description});
						return "Sound: $return";
					}
				}
				return 'Sound: Unknown';
			},

		bios =>
			sub{
				my %h;

				# Bios Vendor
				if(my $vendor = $Registry->{"HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\BIOS\\BIOSVendor"}){
					$h{1} = "Vendor: " . wspaceTrim($vendor);
				}

				# Bios Version
				if(my $version = $Registry->{"HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\BIOS\\BIOSVersion"}){
					$h{2} = "Version: " . $version;
				}

				# Bios Release Date
				if(my $date = $Registry->{"HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\BIOS\\BIOSReleaseDate"}){
					$h{3} = "Date: " . $date;
				}
				
				if(keys %h){
					return 'Bios-: ' . join( " | ", map{ $h{$_} } sort { $a <=> $b } keys %h );
				}

				return 'Bios-: Unknown';
			},

		mobo =>
			sub{
				my %h;

				# Motherboard Manufacturer
				if(my $manufacturer = $Registry->{"HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\BIOS\\BaseBoardManufacturer"}){
					$h{1} = "Manufacturer: " . wspaceTrim($manufacturer);
				}

				# Bios Version
				if(my $model = $Registry->{"HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\BIOS\\BaseBoardProduct"}){
					$h{2} = "Model: " . $model;
				}
				
				if(keys %h){
					return 'Motherboard-: ' . join( " | ", map{ $h{$_} } sort { $a <=> $b } keys %h );
				}

				return 'Motherboard-: Unknown';
			},

		# Show network ID
		# Assumes atleast one NIC exists
		netID =>
			sub{
				my %h;
				for my $v (Win32::OLE::in $wmi->InstancesOf('Win32_NetworkAdapter')){
					my $name = wspaceTrim($v->{name});
					$h{$v->{DeviceID}} = $name;
				}
				return join( "\n", map{"$_: $h{$_}"} sort { $a <=> $b } keys %h );
			}
	} 
};

sub wspaceTrim{
	# Handle unwanted whitespace
	my $trim = shift;
	$trim =~ s!^\s+|\s+$!!g;
	$trim =~ s! +! !g;
	return $trim;
}

sub neg2pos{
	# Negative to Positive
	my $convert = shift;
	return -($convert);
}

hook_command( 'CNS',
	sub{
		LABEL:
		my $one =
			hook_timer( 0,
				sub{
					conv->{nspeed}();
					return REMOVE;
				}
			)
		;
		my $two =
			hook_timer( 1000,
				sub{
					conv->{nspeed}();
					return REMOVE;
				}
			)
		;

			#1024
			#1048576
			my $total = ($one + $two) / 2;
			prnt $total;
			goto LABEL;
			prnt $total;
			#command('SAY ' . sprintf ("%.3g", ($two - $one) * 8 / 100));
			return EAT_XCHAT;
	},
	{ help_text => '/COS - Display operating system' } );

hook_command( 'COS',  sub{ command('SAY ' . conv->{os}()); return EAT_XCHAT; }, { help_text => '/COS - Display operating system' } );
hook_command( 'CCPU', sub{ command('SAY ' . conv->{cpu}()); return EAT_XCHAT; }, { help_text => '/CCPU - Display CPU' } );
hook_command( 'CHDD', sub{ command('SAY ' . conv->{hdd}()); return EAT_XCHAT; }, { help_text => '/CHDD - Display HDD(s)' } );
hook_command( 'CNET', sub{ command('SAY ' . conv->{net}()); return EAT_XCHAT; }, { help_text => '/CNET - Display Network Connection' } );
hook_command( 'CUP',  sub{ command('SAY ' . conv->{time}()); return EAT_XCHAT; }, { help_text => '/CUP - Display Uptime' } );
hook_command( 'CMEM', sub{ command('SAY ' . conv->{mem}()); return EAT_XCHAT; }, { help_text => '/CMEM - Display Memory' } );
hook_command( 'CSND', sub{ command('SAY ' . conv->{sound}()); return EAT_XCHAT; }, { help_text => '/CSND - Display Sound' } );
hook_command( 'CGPU', sub{ command('SAY ' . conv->{vcard}()); return EAT_XCHAT; }, { help_text => '/CCPU - Display Video card' } );
hook_command( 'CBAT', sub{ command('SAY ' . conv->{battery}()); return EAT_XCHAT; }, { help_text => '/CBAT - Display Battery' } );
hook_command( 'CBIOS',  sub{ command('SAY ' . conv->{bios}()); return EAT_XCHAT; }, { help_text => '/CBIOS - Display BIOS information --This may or may not return anything--' } );
hook_command( 'CMOBO',  sub{ command('SAY ' . conv->{mobo}()); return EAT_XCHAT; }, { help_text => '/CMOBO - Display motherboard information --This probably wont show anything on computers that are mass produced--' } );

hook_command(
	'CSYS',
	sub{
		my $s = ' | ';
		command('SAY '
			. conv->{os}()
			. $s . conv->{time}()
			. $s . conv->{cpu}()
			. $s . conv->{mem}()
			. $s . conv->{hdd}()
			. $s . conv->{sound}()
			. $s . conv->{vcard}()
			. $s . conv->{net}()
			. $s . conv->{battery}()
		);
		return EAT_XCHAT;
	},
	{
		help_text => '/CSYS - Display windows system information'
	}
);


#Show network ID and NAME for user to choose
hook_command( 'CNETID', 
	sub{
		prnt conv->{netID}();
		return EAT_XCHAT;
	},
	{ help_text => "/CNETID - Display NIC names and associated ID's for use in the script." }
);

# Doing menus in scripts needs to change
menus();
sub menus{
	command( 'MENU ADD _Sysinfo' );
	command( 'MENU ADD "_Sysinfo/_Sysinfo" csys' );
	command( 'MENU ADD "_Sysinfo/_OS" cos' );
	command( 'MENU ADD "_Sysinfo/_Processor" ccpu' );
	command( 'MENU ADD "_Sysinfo/_Hard Drive" chdd' );
	command( 'MENU ADD "_Sysinfo/_Uptime" cup' );
	command( 'MENU ADD "_Sysinfo/_Memory" cmem' );
	command( 'MENU ADD "_Sysinfo/_Graphics" cgpu' );
	command( 'MENU ADD "_Sysinfo/_Sound" csnd' );
	command( 'MENU ADD "_Sysinfo/_Network" cnet' );
	command( 'MENU ADD "_Sysinfo/_Battery" cbat' );
}

sub unload_menus {
	command('MENU DEL Sysinfo');
}



register( 'culb Windows sysinfo', '002', 'System information. Annoy people with your computers information.', \&unload_menus );

__END__
BEGIN
{
   use Win32::TieRegistry( Delimiter=>"\\", ArrayValues=>0 );
   $Registry = $Registry->Open('', {Access => 0x2000000});
}