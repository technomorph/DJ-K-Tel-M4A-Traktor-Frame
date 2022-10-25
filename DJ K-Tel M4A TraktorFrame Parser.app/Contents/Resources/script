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

my %opts = ();
getopts("nro", \%opts);

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
	my ($id, $len, $children, $rest) = unpack("x$offset A4 V V", $data);
	
	$offset += 12; #length of my header.. data or another container follows
	my $pcdl = 0;  #previous child data length
	
	
	#indentation?
	if(! defined($opts{n})){
		print "\t" x $depth;
	}
	#names backwards?
	my $di = reverse $id;
	if(defined($opts{o})){
		print "$id:";
	}else{
		print "$di:";
	}
	
	
	if($children == 0){	#this is data item, not a container
		
		#interpret value if possible
		if(defined $opts{r}){
			my $l2 = $len * 2;
			my $value = unpack("x$offset H$l2", $data);
			print " raw:$value";
			
		}else{
			my $interpreted = "";
			
			if($di eq "FMOD"){
				#modified date
				$interpreted = join('/', unpack("x$offset c c s", $data));
				#$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "VRSN"){
				#version..
				$interpreted = unpack("x$offset l", $data);
				if($interpreted != 3){
					$interpreted .= " -- original parser based on version 3";
				}
			}elsif($di eq "BPMT"){
				#BPM
				$interpreted = unpack("x$offset f", $data);
			}elsif($di eq "BPMQ"){
				#BPM quality
				$interpreted = unpack("x$offset f", $data);
			}elsif($di eq "HBPM"){
				#BPM "transientcoherence"
				$interpreted = unpack("x$offset f", $data);
			}elsif($di eq "PKDB"){
				#peak DB
				$interpreted = unpack("x$offset f", $data);
			}elsif($di eq "PCDB"){
				#percieved DB
				$interpreted = unpack("x$offset f", $data);
			}elsif($di eq "BITR"){
				#bitrate
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "TNMO"){
				#of tracks
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "FLGS"){
				#flags? haven't seen anything else than '2'
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "LOCK"){
				#locked
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "COLR"){
				#Color
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "RANK"){
				#ranking
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "PCNT"){
				#play count
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "MATY"){
				#?????
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "MKEY"){
				#key
				#$interpreted = t_string(unpack("x$offset a$len", $data));
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "CUEP"){
				#cue points..
				
				#output number of cue points
				my $cuepoints = unpack("x$offset l", $data);
				$interpreted .= "$cuepoints";
				
				#offset used for individual cuepoints, skip 4 bytes (number of cuepoints)
				my $cueoff = $offset + 4;
				
				for(my $i = 0; $i < $cuepoints; $i++){
					$interpreted .= "\n";
					#indentation
					if(! defined($opts{n})){
						$interpreted .= "\t" x ($depth + 1);
					}
					
					$interpreted .= "CUE$i";
					#first long should be 1 ..?
					my $first = unpack("x$cueoff l", $data);
					if($first != 1){
						$interpreted .= " Format not recognized: $first";
						last;
					}else{
						#skip the first long
						$cueoff += 4;
						
						#cuepoint name, stored as "traktor string"
						my $namelen = unpack("x$cueoff l", $data);
						
						#namestring length: long (length of string) + 2 * string length
						my $namestrlen = 4 + $namelen * 2;
						$interpreted .= ", " . t_string(unpack("x$cueoff a$namestrlen", $data));
						
						#add to the offset: namestring length
						$cueoff += $namestrlen;
						
						#rest of the cuepoint contents
						my ($displ_order, $type, $start, $len, $repeats, $hotcue) = unpack("x$cueoff l l d d l l", $data);
						
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
						
						$interpreted .= " dispOrder:$displ_order, type:$type_t, start:$start, len:$len, repeats:$repeats, hotcue:$hotcue";
						
						#lengh of the rest
						$cueoff += 32;
					}
				}
			}elsif($di eq "TRCK"){
				#track #
				$interpreted = unpack("x$offset l", $data);
			}elsif($di eq "TLEN"){
				#track length
				$interpreted = unpack("x$offset l", $data);
				my $sec = $interpreted % 60;
				$sec = "0$sec" if $sec < 10;
				$interpreted = int($interpreted/60) . ":" . $sec;
			}elsif($di eq "TIT1"){
				#key
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "TIT2"){
				#track title
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "TALB"){
				#album title
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "TCON"){
				#genre
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "TCOM"){
				#composer
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "COMM"){
				#comment
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "COM2"){
				#comment
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "CTLG"){
				#catalog
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "TPE1"){
				#author
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "PROD"){
				#producer
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "TPE4"){
				#remix
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "TMIX"){
				#mix
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "LABL"){
				#label
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}elsif($di eq "RLDT"){
				#release date
				$interpreted = join('/', unpack("x$offset c c s", $data));
			}elsif($di eq "IPDT"){
				#import date
				$interpreted = join('/', unpack("x$offset c c s", $data));
			}elsif($di eq "LPDT"){
				#last played date
				$interpreted = join('/', unpack("x$offset c c s", $data));
			}elsif($di eq "TKEY"){
				#key
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}
			elsif($di eq "LMDT"){
				#last modified date
				$interpreted = t_string(unpack("x$offset a$len", $data));
			}

			if($interpreted ne ""){
				print " $interpreted";
			}else{
				#print raw, truncate to 60 characters..
				my $l2 = $len * 2;
				if($l2 > 60){
					$l2 = 60;
				}
				my $value = unpack("x$offset H$l2", $data);
				print " 0x$value";
				print "..." if($len > 30);
			}
		}
	}
	print "\n";
	
	#if this is not a data node (ie children > 0)
	#iterate through all children and descend recursively
	for(my $i = 0; $i < $children; $i++){
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
	print "NITR\n";
	decode(1, 16, $data);
	my $rest = $data;
	$found = 1;
}

if(! $found){
	print "TRAKTOR4 PRIV frame not found\n";
}

print "DONE\n";



#			elsif($di eq "TRN3"){
#				#unknown
#				$interpreted = t_string(unpack("x$offset a$len", $data));
#			}

#			elsif($di eq "USLT"){
#				#key_lyrics
#				$interpreted = t_string(unpack("x$offset a$len", $data));
#			}


#elsif($di eq "CHKS"){
#	#CHECKSUM
#	$interpreted = unpack("x$offset 1", $data);
#	}
