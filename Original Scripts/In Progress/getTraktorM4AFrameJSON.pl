#!/usr/bin/perl -w

#Copyright 2022 DJ K-Tel / Kerry Uchida
#Derived from work by Adam Siroky <wide at dope cz>see more at http://dope.cz/code
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Getopt::Std;
use Data::Dumper qw(Dumper);
use Scalar::Util qw(reftype);
#use JSON::MaybeXS;

$Data::Dumper::Terse = 1;
$Data::Dumper::Pair = " : ";
$Data::Dumper::Useqq = 1;
$Data::Dumper::Sortkeys = \&my_filter;

#my $jsonOBJ = JSON::MaybeXS->new(utf8 => 1, pretty => 1);

#my $jsonData;
#my $jsonString = "";

my %metaDict;
my %headerDict;
my %dataDict;
my %syncDict;
my %hashDict;

my $metaHash;
my $headerHash;
my $dataHash;
my $syncHash;
my $chkSumHash;

my $parentID = '';

my %opts = ();
getopts("h", \%opts);


sub usage{
	print "This program reads M4A/AAC file, decodes PRIV frame named NITR (if exists)\n";
	print "and outputs its contents: item names and values as JSON.\n";
	print "Values whose meaning and format is known are output in meaningful, human-readable form,\n";
	print "others are output \"raw\" - as hexadecimal strings.\n";
	
	print "Usage: $0 [OPTION]... <FILE>\n";
	print "  OPTION is one/combination of:\n";
	print "    -h  add extra checkSumDict to JSON\n";
	print "  FILE is M4A/AAC file\n\n";
}

#if(scalar @ARGV < 1){
#	usage();
#	exit(1);
#}

sub t_string{	# "traktor string" decoder
	my ($data) = @_;
	
	#format: long containing string length and then characters, each followed by a '\0'
	##my $len = unpack("l", $data);
	
	#just return the string
	return pack('(A)*', unpack("x4 (Ax)*", $data));
}

sub decode{
	my ($depth, $offset, $data) = @_;
	my ($frameDI, $len, $children, $rest) = unpack("x$offset A4 V V", $data);
	
	$offset += 12; #length of my header.. data or another container follows
	my $pcdl = 0;  #previous child data length
	
	my $frameID = reverse $frameDI;
	
	if($children == 0){	#this is data item, not a container
		#interpret value if possible
		my $currentValue = "";
		
		if($frameID eq "FMOD"){
			#modified date
			$currentValue = join('/', unpack("x$offset c c s", $data));
			#$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "VRSN"){
			#version..
			$currentValue = unpack("x$offset l", $data);
			if($currentValue != 3){
				$currentValue .= " -- original parser based on version 3";
			}
		}elsif($frameID eq "BPMT"){
			#BPM
			$currentValue = unpack("x$offset f", $data);
		}elsif($frameID eq "BPMQ"){
			#BPM quality
			$currentValue = unpack("x$offset f", $data);
		}elsif($frameID eq "HBPM"){
			#BPM "transientcoherence"
			$currentValue = unpack("x$offset f", $data);
		}elsif($frameID eq "ANDB"){
			#analyzed DB
			$currentValue = unpack("x$offset f", $data);
		}elsif($frameID eq "PKDB"){
			#peak DB
			$currentValue = unpack("x$offset f", $data);
		}elsif($frameID eq "PCDB"){
			#percieved DB
			$currentValue = unpack("x$offset f", $data);
		}elsif($frameID eq "BITR"){
			#bitrate
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "TNMO"){
			#of tracks
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "FLGS"){
			#flags? haven't seen anything else than '2'
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "LOCK"){
			#locked
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "COLR"){
			#Color
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "RANK"){
			#ranking
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "PCNT"){
			#play count
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "MATY"){
			#?????
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "MKEY"){
			#musical key
			#$currentValue = t_string(unpack("x$offset a$len", $data));
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "TRCK"){
			#track #
			$currentValue = unpack("x$offset l", $data);
		}elsif($frameID eq "TLEN"){
			#track length
			$currentValue = unpack("x$offset l", $data);
			$dataDict{"TLEN2"} = $currentValue;
			my $sec = $currentValue % 60;
			$sec = "0$sec" if $sec < 10;
			$currentValue = int($currentValue/60) . ":" . $sec;
		}elsif($frameID eq "AUID"){
			#audioID
			#my $len2 = $len * 2;
			#$currentValue = unpack("x$offset H$len2", $data);
#			print "Audio ID value is:$currentValue\n";
#			$currentValue = decode("utf8", $currentValue);
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TIT1"){
			#grouping
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TIT2"){
			#track title
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TALB"){
			#album title
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TCON"){
			#genre
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TCOM"){
			#composer
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "COMM"){
			#comment
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "COM2"){
			#comment
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "CTLG"){
			#catalog
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TPE1"){
			#author
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "PROD"){
			#producer
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TPE4"){
			#remix
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TMIX"){
			#mix
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "LABL"){
			#label
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "TKEY"){
			#key
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "USLT"){
			#user lyrics
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "RLDT"){
			#release date
			$currentValue = join('/', unpack("x$offset c c s", $data));
		}elsif($frameID eq "IPDT"){
			#import date
			$currentValue = join('/', unpack("x$offset c c s", $data));
		}elsif($frameID eq "LPDT"){
			#last played date
			$currentValue = join('/', unpack("x$offset c c s", $data));
		}elsif($frameID eq "LMDT"){
			#lock modified date and time
			$currentValue = t_string(unpack("x$offset a$len", $data));
		}elsif($frameID eq "CUEP"){
			#cue points..
			#number of cue points
			my $cuepoints = unpack("x$offset l", $data);
			
			#offset used for individual cuepoints, skip 4 bytes (number of cuepoints)
			my $cueoff = $offset + 4;
			my @cuesArray;
			for(my $i = 0; $i < $cuepoints; $i++){
				my %currentCueDict;
				$currentCueDict{"Number"} = $i; #($i + 1);
				#first long should be 1 ..?
				my $first = unpack("x$cueoff l", $data);
				if($first != 1){
					$currentValue .= " Format not recognized: $first";
					last;
				}else{
					#skip the first long
					$cueoff += 4;
					
					#cuepoint name, stored as "traktor string"
					my $namelen = unpack("x$cueoff l", $data);
					#namestring length: long (length of string) + 2 * string length
					my $namestrlen = 4 + $namelen * 2;
					my $cueName = t_string(unpack("x$cueoff a$namestrlen", $data));
					$currentCueDict{"Name"} = $cueName;
					
					#add to the offset: namestring length
					$cueoff += $namestrlen;
					
					#rest of the cuepoint contents
					my ($dispOrder, $type, $start, $len, $repeats, $hotcue) = unpack("x$cueoff l l d d l l", $data);
					
					#type translated
					my $typeName = $type;
					if($type == 0){
						$typeName = "CUE";
					}elsif($type == 1){
						$typeName = "IN";
					}elsif($type == 2){
						$typeName = "OUT";
					}elsif($type == 3){
						$typeName = "LOAD";
					}elsif($type == 4){
						$typeName = "GRID";
					}elsif($type == 5){
						$typeName = "LOOP";
					}
					
					$currentCueDict{"DispOrder"} = $dispOrder;
					$currentCueDict{"Type"} = $typeName;
					$currentCueDict{"Start"} = $start;
					$currentCueDict{"Length"} = $len;
					$currentCueDict{"Repeats"} = $repeats;
					$currentCueDict{"HotCue"} = $hotcue; #($hotcue + 1);
					
					#lengh of the rest
					$cueoff += 32;
				}
				push (@cuesArray, \%currentCueDict);
			}
			my @cuesSorted = sort {$$a{"HotCue"} <=> $$b{"HotCue"} } @cuesArray;
			$dataDict{"CUEP"} = \@cuesSorted;
		}
		
		if($currentValue eq ""){
			#get raw, truncate to 60 characters..
			my $l2 = $len * 2;
			if(($l2 > 60) && ($frameID ne "TRN3")){
				$l2 = 60;
			}
			my $value = unpack("x$offset H$l2", $data);
			$currentValue .= "0x$value";
			if(($len > 30) && ($frameID ne "TRN3")) {
				$currentValue .= "...";
			}
		}
		
		if($parentID eq "TRMD"){
			$metaDict{"$frameID"} = $currentValue;
		}elsif($parentID eq "HDR"){
			$headerDict{"$frameID"} = $currentValue;
		}elsif($parentID eq "DATA" && $frameID ne "CUEP"){
			$dataDict{"$frameID"} = $currentValue;
		}elsif($parentID eq "SYNC"){
			$syncDict{"$frameID"} = $currentValue;
		}
		
	}else {
		#this is not a data node (ie children > 0)
		#iterate through all children and descend recursively
		if($frameID eq "TRMD"){
			$parentID = "TRMD";
		}elsif($frameID eq "HDR"){
			$parentID = "HDR";
		}elsif($frameID eq "DATA"){
			$parentID = "DATA";
		}elsif($frameID eq "SYNC"){
			$parentID = "SYNC";
		}
		
		for(my $i = 0; $i < $children; $i++){
			$pcdl += 12 + decode($depth + 1, $offset + $pcdl, $data);
		}
		
		if($parentID eq "SYNC"){
			$parentID = "DATA";
		}
	}
	
	#returns length of the current item so the next iteration can add it to the offset
	return($len);
}

sub my_filter {
	my ($hash) = @_;
	# return an array ref containing the hash keys to dump
	# in the order that you want them to be dumped
	
	return [
	# Sort the keys of base
	#(($hash eq \%metaDict) || ($hash eq $jsonString)) ? ("HDR","DATA","HASHES") :
	($hash eq \%metaDict) ? ("HDR","DATA","HASHES") :
	# Sort keys in default order for all other hashes
	(sort keys %$hash)
	];
}

#-----------------------------------------------------
#------------- MAIN FUNCTIONS BELOW     --------------
#-----------------------------------------------------

if(! -f $ARGV[0]){
	print "No such file: $ARGV[0]\n";
	exit(1);
}


#my $data = `exiftool -Unknown_NITR -u -U -b -f -s "/Volumes/Panko/zz Programming Transfers/AV Foundation/zzzz Audio Metadata/Traktor Frame/Traktor Frame OLD/Dreams.m4a"`;

# print "Parsing File: $ARGV[0]\n\n";


my $data = `/usr/local/bin/exiftool -Unknown_NITR -u -U -b -f -s "$ARGV[0]"`;
my $found = 0;
if($data){
	
	decode(0, 16, $data);
	my $rest = $data;
	$found = 1;
	
	$dataDict{"SYNC"} = \%syncDict;
	$metaDict{"HDR"} = \%headerDict;
	$metaDict{"DATA"} = \%dataDict;
	
	if(defined $opts{h}){ #add checkSumDict
		my $metaHash = \%metaDict;
		$metaHash = "$metaHash";
		my $headerHash = \%headerDict;
		$headerHash = "$headerHash";
		my $dataHash = \%dataDict;
		$dataHash = "$dataHash";
		my $syncHash = \%syncDict;
		$syncHash = "$syncHash";
		my $chkSumHash = $headerDict{"CHKS"};
		
		$hashDict{"metaHash"} = $metaHash;
		$hashDict{"headerHash"} = $headerHash;
		$hashDict{"dataHash"} = $dataHash;
		$hashDict{"syncHash"} = $syncHash;
		$hashDict{"traktorHash"} = $chkSumHash;
		
		$metaDict{"HASHES"} = \%hashDict;
	}
	
	#print "-------------------------------------------------- metaDict Below\n";
	print Dumper \%metaDict;
	
	#	$jsonData = $jsonOBJ->encode(\%metaDict);
	#	$jsonString = $jsonOBJ->decode($jsonData);
	#
	#	print "------------------------------ DUMPER jsonString Below\n";
	#	print Dumper $jsonString;
	
}

if(! $found){
	print "TRAKTOR4 PRIV frame not found\n";
}


