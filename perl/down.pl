#!/usr/bin/perl
#
# 18.12.2025 JS
#
# This script downloads a S-Record file into memory.
#
# Be carefull not to overwrite the "receiver buffer full"
# interrupt vector at 0x130 or the bootloader will stop.
# Also try to stay clear of the stack at the top of the
# 32k RAM.
#
# The read_const_time in the script slows down the host
# computer so the 68901 can keep up without RTS/CTS.
#

use strict;
use warnings;
use Getopt::Std;
use Device::SerialPort;

# flush stdout
$| = 1;

my %opts;
if(@ARGV < 1 or !getopts('bmd:f:', \%opts)) {
        print "syntax: $0 -d <device> -b -m -f <file>\n";
	print "    -d: serial device\n";
	print "    -b: send break\n";
	print "    -m: monitor\n";
	print "    -f: S-Record file to be downloaded\n";
        exit 1;
}

my $loop = 1;
$SIG{INT}  = \&signal_handler;
sub signal_handler {
	$loop = 0;
}

my $device = defined $opts{'d'} ? $opts{'d'} : "/dev/ttyUSB0";
my $dev = Device::SerialPort->new($device);
$dev or die "can't open $device\n";
$dev->baudrate(9600);
$dev->databits(8);
$dev->parity("none");
$dev->stopbits(1);
$dev->handshake("none");
$dev->purge_all();
$dev->read_const_time(100);

if(defined($opts{'b'})) {
	$dev->pulse_break_on(100);
}

if(defined($opts{'f'})) {
	my $file = $opts{'f'};
	open(FILE, '<', $file) or die "can't open $file\n";
	while(<FILE>) {
		$dev->write($_);
		my ($n, $char) = $dev->read(1);
		$n and print $char;
	}
	close FILE;
	# send EOT
	$dev->write(pack("C", 0x04));
	my ($n, $char) = $dev->read(1);
	$n and print $char;
}

if(defined($opts{'m'})) {
	$dev->read_const_time(1000);
	while($loop and $opts{'m'}) {
		my ($n, $char) = $dev->read(1);
		$n and print $char;
	}
}

$dev->close();

exit 0;

