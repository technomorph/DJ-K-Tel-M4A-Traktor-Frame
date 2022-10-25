# DJ-K-Tel-M4A-Traktor-Frame
Decode the Traktor Private NITR Frame on M4A Files

Traktor stores it's own Metadata in a Private Frame.
On mp3 Files this is stored in the TRAKTOR4 Private Frame.
You can get this information via a web decoder from Hellricer Here:
https://hellricer.github.io/2021/05/05/decoding-traktor4-field.html

His code is based on the work that was done with this Perl Script info Here:
https://web.archive.org/web/20130525033615/http://dope.cz/code 

My code is based on the above Perl Script: getTraktorFrame.pl
which is no longer available on that site, but included in the Original Scripts Folder named: getTraktorFrameOrig.pl

The getTraktorFrame.pl Script was getting the NITR Frame which is the older name that Traktor used.
But was only able to get the Private NITR Frame from mp3 files using mp3Tag.

I have been exploring with all of the Tag Readers/Writers that I can.
My choice has been Kid3 as i found Acoustic Brains just adding a bunch of junk I didn't need.
Kid3 was also easily scriptable and adaptable to my needs for working with FLAC files and M4A files.
I'll soon upload some of my custom scripts.  

I noticed that Kid3 (with the right settings) was recognizing the TRAKTOR4 Private frame on mp3 files.
But my current workflow is using straight M4A files at 512kbs / 96kHz converted from FLAC 24Bit/44.1-192kHz Files.
I was still not able to find any TRAKTOR4 or NITR frames on M4A files via any programs until I tried out EXIF Tool.

Running EXIF Tool forcing it so scan all frames and include unknown frames, revealed the Unknon_NITR
...TRIMMED DATA.....
Composer                        : FLAC 24bit/176.4khz
Unknown_NITR                    : (Binary data 79459 bytes, use -b option to extract)
ContentCreateDate               : 1977
...TRIMMED DATA.....


