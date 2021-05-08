FD Alert
version 1.1.3
by Intermission, on Frostmourne-US
Added features by CGN (track FD resists per fight)

==== What it does ====

This addon gives alerts when your Feign Death resists. When a resist occurs, it does 3 things:

- Sends a custom message to any chat channel (say, yell, raid, etc)
- Sends a custom message via whisper to any name
- Plays a sound of your choice.


==== How to install ====

Download and unzip the FD_Alert folder inside WoW\Interface\Addons folder. Or use the WoWInterface updater program, found at http://www.wowinterface.com/forums/showthread.php?t=14971


==== How to use it ====

FD Alert uses a few slash commands to configure. By default it sends a message in /say, plays a bell sound, and does not send any whispers. You can change the messages (both channel and whisper messages can be different), and change which channel they send to or which person they whisper. The sound alert can be changed to one of 10 built in sounds, or any sound in the WoW files.

Here is the list of commands:

/fda 				= shows command list list
/fda help 			= show detailed help
/fda enable 			= toggles mod on/off
/fda message <message> 		= sets the message to send to the channel
/fda chan <channel> 		= sets the channel to send the message to*
/fda wm <message> 		= sets the message to send in the whisper
/fda wt <whisper target> 	= sets the target to whisper
/fda sound <number> 		= selects a sound, valid choices are 0-10 (0 = off)**
/fda tally                  = Chooses whether to tally up FD's + resists for an encounter. Note: This feature is useless outside of boss fights. ^
/fda test 			= simulates a Feign Death resist with the current settings
/fda status 			= displays current settings
/fda reset 			= resets all settings to default

*Valid chat channels: say, emote, yell, party, raid, raid_warning, guild, officer, and the channel numbers 1 to 9.

**FD Alert has 10 sounds built in, but you can use any WoW sound you like by editing the saved variables folder, found in: WoW\WTF\Account\<account>\<server>\<character>\SavedVariables\FD_Alert.lua
A WoW sound list can be found at http://www.wowwiki.com/API_PlaySoundFile_SoundList (warning, there are thousands of them. I just picked 10 random ones that sounded decent for the mod)

You can turn off the channel messages, whisper messages, or sound alert by setting them to "0".

^Added by CGN

==== On the horizon ====

Stuff I hope to implement soon:

- send message to multiple channels
- send whisper message to multiple people
- ability for user to add custom sounds (those that are not in the default 10) via slash command instead of editing SavedVariables
- simple GUI
- adding a visual alert, such as a screen flash/shake or an image flash
- adding cooldown detection to FD, so a sound and visual alert is made when FD is ready to be used again
- checking that it works in WotLK (if I get a key)


==== Changelog and other stuff ====

Newest version can be found at WoWInterface: http://www.wowinterface.com/downloads/info10329-FDAlert.html - outdated

Current version:

1.1.3
- Added tracking of resists/attempts per fight
- Added consecutive resists mentioned in chat


Older versions:

1.1.1 and newer made by CGN ^ ^ ^
----------------------------------
1.1 and older made by Intermission v v v

1.1
- fixed a couple of typos (didnt effect functionality)
- added a readme.txt (that nobody will read anyway)
- made some of the code slightly more sexier than before

1.0
- release, it works.



This is my first mod, and first attempt at programming! I've tested it and it all works, but please report any bugs you may find. Criticism, tips and requests are welcome.

Cheers,
Intermission