# DJ K-Tel M4A Traktor Frame

**Decoding the Traktor Private NITR Frame on M4A Files**

## TABLE OF CONTENTS

1. [Traktor Private Frame Info](#privFrameInfo )
2. [Reading the Traktor Frame](#readFrame)
3. [EXIF Tool](#exifTool)
4. [Script Modification](#scriptMod)
5. [Requirements](#require)
6. [Installation](#install)
7. [Running](#running)
8. [Road Map](#roadMap)
9. [Contribute](#contribute)



<h2 id="privFrameInfo"\> Traktor Private Frame Info</h2\>

Traktor stores it's own Metadata in a Private Frame.
 On mp3 Files this is stored in the TRAKTOR4 Private Frame.
 You can get this information via a web decoder from Hellricer Here: <https://hellricer.github.io/2021/05/05/decoding-traktor4-field.html>

His code is based on the work that was done with this Perl Script info Here:
 <https://web.archive.org/web/20130525033615/http://dope.cz/code>

My code is based on the above Script: *getTraktorFrame.pl* which is no longer available on that site, but I've included it in the Original Scripts Folder named: *getTraktorFrameOrig.pl*

The *getTraktorFrame.pl* Script was getting the NITR Frame which is the older name that Traktor used. But was only able to get the Private NITR Frame from mp3 files using mp3Tag.

READING THE TRAKTOR FRAME
-------------------------

 I have been exploring with all of the Tag Readers/Writers that I can. My choice has been Kid3 as i found Music Brains just adding a bunch of junk I didn't need. Kid3 was also easily scriptable and adaptable to my needs for working with FLAC files and M4A files. I'll soon upload some of my custom scripts. 

I noticed that Kid3 (with the right settings) was recognizing the TRAKTOR4 Private frame on mp3 files. But my current workflow is using straight M4A files at 512kbs / 96kHz converted from FLAC 24Bit/44.1-192kHz Files.
 I was still not able to find any TRAKTOR4 or NITR frames on M4A files via any programs until I tried out EXIF Tool.

EXIF Tool
---------

Running EXIF Tool forcing it so scan all frames and include unknown frames, revealed the Unknown\_NITR

```perl
exiftool -all -a -u -U -f -s "$PATH TO FILE IN QUOTES" OR ESCAPED
...TRIMMED DATA.....
Composer                        : FLAC 24bit/176.4khz
Unknown_NITR                    : (Binary data 79459 bytes, use -b option to extract)
ContentCreateDate               : 1977
...TRIMMED DATA.....
```

EXIF Tool also allowed me to just extra the single Unknown\_NITR frame as Binary data.

```perl
exiftool -Unknown_NITR -u -U -b -f -s "$PATH TO FILE" 
6cNTKB6[dataDMRTG4RDH 0SKHC???DOMF	?NSRVATAD?3DNAAWTRAq}} 117/VT5AJPBHDST53A13UP2BBNPVZC1C??????????????????????????????????????????????????????????????????????
******************TRIMMED MIDDLE HERE - ARTWORK DATA****************
??????????????????????????????????????????????????????????????????????????????????????????????????????????????DIUA#434333#3333333C3CC333B234CC33334ED34434344D#434444D3D3333DC33ES33C33DUUDC43335DDC43##D4D33###4DC332"3C22"33"#3#2#"#2#B222232223C22"234DCC33233#33#433#33433333344344D34DC34DfSSCC223TETDC33T44333##4DED43##DDD33333D4D3322#33C22222DDCCC22DC23DC34D3!RTIB?]QMPB??RLOCMMOC
176GLTC$C345D0D113847284PEUC?n.n.t?p????@????
                                             Beat Marker?V????@????n.n.?V????@
dv?@????SGLFMPBHĚ?BTDPI?LBAL*FLAC 24bit/176.4khzYEKMBDCPABDKP??@KNAR?TDLR?CNYSYTAMBLAT"Rumours SACD HDNOCT
                                                                                                          Rock2TITDreamsNELTOMNT
Fleetwood MacKCRT3NRT?;????W???8Ɩ?;?a??b?1???3B@?B??C?i?`ד???>'??B?m????2??3C??5?????`@?@??'??|?B@?@j?I??0@̧?=?                  1EPT
?B?B?
@dt2??C?p@GAH??'2@??:=??B ?=@
ޣ=;r!B?)@?o?>??B?t@?sL? @    ?6???C`?3@?|(??8@W??=?3?B?<*@???>??C? @R?%???I=???B,'@???>ͼ?B p ??K?@y'@
                         ޠ=?W?B`Չ W???C@!@l%?<?[B?5?!@?+? S"@?>=@BCB?׃"@?g??-(C`??#@???Ć$@Л
?t?	C ??$@y>?:`?%@??(?`?=v&?>??C?Q|&@U??֧	C?5x'@0?=?E?'@?ږ=}??B?t(@??@?C?h?(@??;? ******************TRIMMED TO END FROM HERE - UNKNOWN DATA (TRANSIENTS?) ***************
```

MODIFY SCRIPT
-------------

I then modified the orignal Perl Script to get the data via EXIF Tool rather than mp3Tag and then process the data. I had to make a few small other adjustments.

## PACKAGE SCRIPT
I then packaged the Perl Script into a Mac App using 
**Platypus** https://sveinbjorn.org/platypus

<h2 id="require">REQUIREMENTS</h2>

- Mac OSX 10.11 or Later
- Traktor m4a files (Test files included)
- EXIF Tool
    - INSTALL FROM HERE : https://exiftool.org
    - Direct Mac Download Here: https://exiftool.org/ExifTool-12.49.dmg
    - See Also info on testing EXIF in Installation and Instructions Folder

INSTALLATION
------------

* Copy or Move the Whole Folder to anywhere
* Download Release from here: <https://github.com/technomorph/DJ-K-Tel-M4A-Traktor-Frame/releases>
* Move the **DJ K-Tel M4A TraktorFrame Parser** to applications folder (optional)

<h2 id="running">RUNNING</h2>

- Launch the App and it will ask for a file
- Or drop a m4a file onto it
- If finds the Frame it will decode and print to the screen.
- You can save the output (example below) from the app.

```perl
Parsing File: /Volumes/Panko/zz Programming Transfers/AV Foundation/zzzz Audio Metadata/Traktor Frame/DJ K-Tel M4A Traktor Frame/Dreams.m4a

NITR
	TRMD:
		HDR:
			CHKS: 0xbecfd300
			FMOD: 9/7/2022
			VRSN: 7 -- original parser based on version 3
		DATA:
			ANDB: 0x181d0441
			ARTW: 0x087d0000007d000000200000003100310037002f0056005400350041004a...
			AUID: 0x000100000102012334333433333323333333333333334333434333333342...
			BITR: 6144000
			BPMQ: 1
			COLR: 4
			COMM: 176
			CTLG: C345D0D113847284
			CUEP: 3
				CUE0, n.n. dispOrder:0, type:CUE, start:661.209319, len:0, repeats:-1, hotcue:1
				CUE1, Beat Marker dispOrder:0, type:GRID, start:1339.378558, len:0, repeats:-1, hotcue:0
				CUE2, n.n. dispOrder:0, type:LOOP, start:1339.378558, len:7914.113624, repeats:-1, hotcue:2
			FLGS: 14
			HBPM: 121.302276611328
			IPDT: 2/7/2022
			LABL: FLAC 24bit/176.4khz
			MKEY: 0
			PCDB: 8.25710296630859
			PKDB: 5.18993711471558
			RANK: 255
			RLDT: 1/1/1977
			SYNC:
				MATY: 3
			TALB: Rumours SACD HD
			TCON: Rock
			TIT2: Dreams
			TLEN: 4:19
			TNMO: 12
			TPE1: Fleetwood Mac
			TRCK: 2
			TRN3: 0xba030000000000c0f8c6573fce1caf38c696943b000000008661e83f62d9...
DONE
```

ROAD MAP
--------

* Be able to also parse the TRAKTOR4 frame
* Be able to generate a JSON Dict of the DATA
* Change the parser from Perl to Objective-C (My main programming language)
* Try to be able to modify and resave the frame back to the file. 
  * I know the CHKS is an important part.
  * in the example file Shown data is 79459 bytes
  * and the parsed CHKS is 0xbecfd300

CONTRIBUTE
----------

Let me know if your interested in helping further develop in anyway

* get and parse the TRAKTOR4 frame
* create HASH properties in Perl
* create JSON in Perl
* export JSON in Perl
* parse NSData in Objective-C
* attempt at Modifing and Resaving the frame