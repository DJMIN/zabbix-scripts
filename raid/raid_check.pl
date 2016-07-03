#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Switch;

my ($mode,$mode_item,$adapter,$enclosure_id,$disk_id,$vdisk_id);

GetOptions (
	"mode=s"	=> \$mode,
	"item=s"	=> \$mode_item,
	"adapter=i"	=> \$adapter,
	"enclosure:i"	=> \$enclosure_id,
	"pdisk:i"	=> \$disk_id,
	"vdisk:i"	=> \$vdisk_id
) or die("Error in command line arguments\n");

my $cli	= 'sudo /opt/MegaRAID/CmdTool2/CmdTool264';
die("Mode is not defined. Use --mode parameter") if !defined $mode;
die("Adapter is not defined. Use --adapter parameter") if !defined $adapter;

switch ($mode) {
	case 'pdisk'	{ &pdisk_item(item=>$mode_item,adapter=>$adapter,enclosure=>$enclosure_id,disk=>$disk_id) }
	case 'vdisk'	{ &vdisk_item(item=>$mode_item,adapter=>$adapter,vd=>$vdisk_id) }
	case 'bbu'		{ &bbu_item(item=>$mode_item,adapter=>$adapter) }
	case 'adapter'	{ &adapter_item(item=>$mode_item,adapter=>$adapter) }
	else			{ die("Unknown mode, use pdisk, vdisk, bbu or adapter mode") }
}

sub pdisk_item() {
	my %options = @_;
	my $item = $options{item} if defined $options{item} or die("use --item to define which item should be checked");
	my $enclosure = $options{enclosure} if defined $options{enclosure} or die("use --enclosure to define enclosure on adapter");
	my $adapter= $options{adapter} if defined $options{adapter} or die("use --adapter to define which adapter should be checked");
	my $disk = $options{disk} if defined $options{disk} or die("use --pdisk to define which physical disk should be checked");

	my $regex = '';
	my $item_found = 0;

	switch ($item) {
		case 'firmware_state'		{ $regex = '^Firmware state:\s(.*)' }
		case 'raw_size'				{ $regex = '^Raw Size:\s+(\d+\.\d+\s..)' }
		case 'predictive_errors'	{ $regex = '^Predictive Failure Count:\s(.*)' }
		case 'inquiry_data'			{ $regex = '^Inquiry Data:\s+(.*)' }
		case 'media_errors'			{ $regex = '^Media Error Count:\s(.*)' }
		case 'temperature'			{ $regex = '^Drive Temperature\s:\s?(\d+)' }
		else						{ die("Unknown item $item for physical disk check") }
	}

	if ($enclosure == -1) { $enclosure = '' }
	my @output = `$cli -pdinfo -PhysDrv[$enclosure:$disk] -a $adapter`;

	foreach my $line (@output) {
		if ($line =~ $regex) {
			if ((length($line) >= 2) or ($item ne 'temperature')) {
				print $1;
			}
			else {
				print '0';
			}
			$item_found = 1;
			last;
		}
	}
	if (($item_found == 0) and ($item eq 'temperature')) { print '0' }
}

sub vdisk_item() {
	my %options = @_;
	my $item = $options{item} if defined $options{item} or die("use --item to define which item should be checked");
	my $adapter= $options{adapter} if defined $options{adapter} or die("use --adapter to define which adapter should be checked");
	my $vd = $options{vd} if defined $options{vd} or die("use --vdisk to define which virtual disk should be checked");

	my $regex = '';
	my $item_found = 0;

	switch ($item) {
		case 'vd_state'			{ $regex = '^State\s+:\s(.*)$' }
		case 'vd_size'			{ $regex = '^Size\s+:\s(\d+\.\d+\s..)' }
		else					{ die("Unknown item $item for virtual disk check") }
	}

	my @output = `$cli -LDinfo -L $vd -a $adapter`;
	foreach my $line (@output) {
		if ($line =~ $regex) {
			print $1;
			$item_found = 1;
			last;
		}
	}
}

sub bbu_item() {
	my %options = @_;
	my $item = $options{item} if defined $options{item} or die("use --item to define which item should be checked");
	my $adapter= $options{adapter} if defined $options{adapter} or die("use --adapter to define which adapter should be checked");

	my $regex = '';
	my $command = '';
	my $item_found = 0;

	switch ($item) {
		case 'bbu_state'		{ $command = '-GetBbuStatus';$regex = 'Battery State\s*:\s(.*)$' }
		case 'design_capacity'	{ $command = '-GetBBUDesignInfo';$regex = 'Design\sCapacity:\s(\d+)\smAh' }
		case 'full_capacity'	{ $command = '-GetBBUCapacityInfo';$regex = 'Full\sCharge\sCapacity:\s(\d+)\smAh' }
		case 'state_of_charge'	{ $command = '-GetBBUCapacityInfo';$regex = 'Absolute\sState\sof\scharge\s*:\s(\d+).*%' }
		else					{ die("Unknown item $item for battery unit check") }
	}

	my @output = `$cli -AdpBbuCmd $command -a $adapter`;
	foreach my $line (@output) {
		if ($line =~ $regex) {
			print $1;
			$item_found = 1;
			last;
		}
	}
	#if (($item_found == 0) and ($item eq 'bbu_state')) { print 'Optimal' }
}

sub adapter_item() {
	my %options = @_;
	my $item = $options{item} if defined $options{item} or die("use --item to define which item should be checked");
	my $adapter= $options{adapter} if defined $options{adapter} or die("use --adapter to define which adapter should be checked");

	my $regex = '';
	my $item_found = 0;

	switch ($item) {
		case 'fw_version'	{ $regex = '^\s*FW\sPackage\sBuild:\s(.*)$' }
		case 'product_name'	{ $regex = '^\s*Product\sName\s*:\s(.*)$' }
		else				{ die("Unknown item $item for adapter check") }
	}

	my @output = `$cli -AdpAllInfo -a $adapter`;
	foreach my $line (@output) {
		if ($line =~ $regex) {
			print $1;
			$item_found = 1;
			last;
		}
	}
}
