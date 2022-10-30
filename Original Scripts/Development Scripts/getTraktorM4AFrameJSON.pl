#!/usr/bin/perl -w

#Copyright 2010 Adam Siroky <wide at dope cz>
#see more at http://dope.cz/code
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
#use MP3::Tag;
use Getopt::Std;
use Data::Dumper qw(Dumper);

my %opts = ();
getopts("nro", \%opts);

my %traktorMetaDict;
my %headerDict;
my %dataDict;
my %currentDict;
my $parentID = '';

sub usage{
	print "This program reads mp3 file, decodes id3v2 PRIV frame named TRAKTOR4 (if exists)\n";
	print "and outputs its contents: item names and values.\n";
	print "Values whose meaning and format is known are output in meaningful, human-readable form,\n";
	print "others are output \"raw\" - as hexadecimal strings.\n";
	print "More info: http://dope.cz/code\n\n";
	
	print "Usage: $0 [OPTION]... <FILE>\n";
	print "  OPTION is one/combination of:\n";
	print "    -n  Noindent (do Not iNdent output)\n";
	print "    -r  output Raw values (may contain long lines - hundreds of kilobytes)\n";
	print "    -o  write original item names (backwards)\n";
	print "  FILE is mp3 file\n\n";
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
	
	print "===== depth is $depth\n";
	#indentation?
	if(! defined($opts{n})){
		print "\t" x $depth;
	}
	#names backwards?
	my $frameID = reverse $frameDI;
	if(defined($opts{o})){
		print "$frameDI:";
	}else{
		print "$frameID:";
	}
	
	
	if($children == 0){	#this is data item, not a container
		#print "=================== NO CHILDREN";
		#interpret value if possible
		if(defined $opts{r}){
			my $l2 = $len * 2;
			my $value = unpack("x$offset H$l2", $data);
			print " raw:$value";
			
		}else{
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
				#key
				#$currentValue = t_string(unpack("x$offset a$len", $data));
				$currentValue = unpack("x$offset l", $data);
			}elsif($frameID eq "CUEP"){
				#cue points..
				
				#output number of cue points
				my $cuepoints = unpack("x$offset l", $data);
				#$currentValue .= "$cuepoints";
				
				#offset used for individual cuepoints, skip 4 bytes (number of cuepoints)
				my $cueoff = $offset + 4;
				
				my @cuesArray;
				for(my $i = 0; $i < $cuepoints; $i++){
					#$currentValue .= "\n";
					my %currentCueDict;
					#indentation
					print "=================== NEW CUE POINTS LIST depth is ($depth + 1)";
					if(! defined($opts{n})){
						$currentValue .= "\t" x ($depth + 1);
					}
					
					my $cueNumber = "CUE$i";
					$currentCueDict{"Number"} = $i;
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
						#$currentValue .= ", ";
						#add to the offset: namestring length
						$cueoff += $namestrlen;
						
						#rest of the cuepoint contents
						my ($frameIDspl_order, $type, $start, $len, $repeats, $hotcue) = unpack("x$cueoff l l d d l l", $data);
						
						#type translated
						my $type_t = $type;
						if($type == 0){
							$type_t = "CUE";
						}elsif($type == 1){
							$type_t = "IN";
						}elsif($type == 2){
							$type_t = "OUT";
						}elsif($type == 3){
							$type_t = "LOAD";
						}elsif($type == 4){
							$type_t = "GRID";
						}elsif($type == 5){
							$type_t = "LOOP";
						}
						
						$currentCueDict{"DispOrder"} = $frameIDspl_order;
						$currentCueDict{"Type"} = $type_t;
						$currentCueDict{"Start"} = $start;
						$currentCueDict{"Length"} = $len;
						$currentCueDict{"Repeats"} = $repeats;
						$currentCueDict{"HotCue"} = $hotcue;
						#$currentValue .= " dispOrder:$frameIDspl_order, type:$type_t, start:$start, len:$len, repeats:$repeats, hotcue:$hotcue";
						
						#lengh of the rest
						$cueoff += 32;
					}
					push @cuesArray, %currentCueDict;
				}
				$dataDict{"CUEP"} = qw(@cuesArray);
			}elsif($frameID eq "TRCK"){
				#track #
				$currentValue = unpack("x$offset l", $data);
			}elsif($frameID eq "TLEN"){
				#track length
				$currentValue = unpack("x$offset l", $data);
				my $sec = $currentValue % 60;
				$sec = "0$sec" if $sec < 10;
				$currentValue = int($currentValue/60) . ":" . $sec;
			}elsif($frameID eq "TIT1"){
				#key
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
			}elsif($frameID eq "RLDT"){
				#release date
				$currentValue = join('/', unpack("x$offset c c s", $data));
			}elsif($frameID eq "IPDT"){
				#import date
				$currentValue = join('/', unpack("x$offset c c s", $data));
			}elsif($frameID eq "LPDT"){
				#last played date
				$currentValue = join('/', unpack("x$offset c c s", $data));
			}elsif($frameID eq "TKEY"){
				#key
				$currentValue = t_string(unpack("x$offset a$len", $data));
			}
			elsif($frameID eq "LMDT"){
				#last modified date
				$currentValue = t_string(unpack("x$offset a$len", $data));
			}

			if($currentValue ne ""){
				print "$currentValue";
			}else{
				#print raw, truncate to 60 characters..
				my $l2 = $len * 2;
				if($l2 > 60){
					$l2 = 60;
				}
				my $value = unpack("x$offset H$l2", $data);
				print " 0x$value";
				$currentValue .= $value;
				if($len > 30) {
					print "...";
					$currentValue .= "...";
				}
			}
			if($parentID eq "TRMD"){
				$traktorMetaDict{"$frameID"} = "$currentValue";
			}elsif($parentID eq "HDR"){
				$headerDict{"$frameID"} = "$currentValue";
			}
			elsif($parentID eq "DATA"){
				$dataDict{"$frameID"} = "$currentValue";
			}
		}
	}
	print "\n";
	#print "=================== END SUB DECODE AFTER NEW LINE \n";
	
	#if this is not a data node (ie children > 0)
	#iterate through all children and descend recursively
	if($frameID eq "TRMD"){
		$parentID = "TRMD";
	}elsif($frameID eq "HDR"){
		$parentID = "HDR";
	}
	elsif($frameID eq "DATA"){
		$parentID = "DATA";
	}
	for(my $i = 0; $i < $children; $i++){
		#print "======child:$i ofTotal:$children";
		$pcdl += 12 + decode($depth + 1, $offset + $pcdl, $data);
	}
	
	#returns length of the current item so the next iteration can add it to the offset
	return($len);
}

#-----------------------------------------------------

if(! -f $ARGV[0]){
	print "No such file: $ARGV[0]\n";
	exit(1);
}

#my $mp3 = MP3::Tag->new($ARGV[0]);
#my $data = `exiftool -Unknown_NITR -u -U -b -f -s "/Volumes/Tekno/Users/kerry/Music/iTunes/iTunes Media/Music/Musical Youth/The Youth of Today/Pass The Dutchie (Special Dub Mix).m4a"`;

#my $data = `exiftool -Unknown_NITR -u -U -b -f -s "/Volumes/Panko/zz Programming Transfers/AV Foundation/zzzz Audio Metadata/Traktor Frame/Traktor Frame OLD/Dreams.m4a"`;

#
print "Parsing File: $ARGV[0]\n\n";


my $data = `/usr/local/bin/exiftool -Unknown_NITR -u -U -b -f -s "$ARGV[0]"`;
my $found = 0;
if($data){
	#print "NITR\n";
	#my %headerDict;
	my %traktorMetaDict;
	my %headerDict;
	my %dataDict;
	my %currentDict;
	decode(0, 16, $data);
	my $rest = $data;
	$found = 1;
	
	$traktorMetaDict{"HDR"} = \%headerDict;
	$traktorMetaDict{"DATA"} = \%dataDict;
	print Dumper \%headerDict;
	print Dumper \%dataDict;
	print Dumper \%traktorMetaDict;
}

if(! $found){
	print "TRAKTOR4 PRIV frame not found\n";
}



print "DONE\n";



#			elsif($frameID eq "TRN3"){
#				#unknown
#				$currentValue = t_string(unpack("x$offset a$len", $data));
#			}

#			elsif($frameID eq "USLT"){
#				#key_lyrics
#				$currentValue = t_string(unpack("x$offset a$len", $data));
#			}


#elsif($frameID eq "CHKS"){
#	#CHECKSUM
#	$currentValue = unpack("x$offset 1", $data);
#	}
