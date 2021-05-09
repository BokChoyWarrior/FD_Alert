

# FD Alert

This addon gives alerts when your Feign Death resists. 
- Sends a custom message to a chat channel (say, yell, raid etc.)
- Plays a sound of your choice
- Tracks your resists per fight

### Guide
FD Alert uses a few slash commands to configure. By default it sends a message in /say, plays a bell sound, and does not send any whispers. You can change the messages (both channel and whisper messages can be different), and change which channel they send to or which person they whisper. The sound alert can be changed to one of 10 built in sounds, or any sound in the WoW files.

Commands | Effect
-----------|------------
`/fda` or `/fda help` | Shows command list
`/fda enable` | Toggle mod on/off
`/fda message <message>` | Changes the main message, e.g `/fda message My FD resisted!`*
`/fda channel <channel>` | Sets the main channel to announce in (say, yell, pary, raid, raid_warning, and numbers 1-9) or 0 to disable
`/fda sound <number>` | Select a sound. (1-10) or 0 to disable**
`/fda tally` | Whether FD Alert will tally your resists/attempts per fight
`/fda test` | Simulate a FD resist based on your current settings
`/fda status` | Display current settings
`/fda default` | Reset settings to default


*The string `%p` can be used to enter the player's name. For example the player named `Leeroy` would use 
>`/fda message %p couldn't play dead well enough!` 

which would equate to
>`Leeroy couldn't play dead well enough!`

(Just for you lazy people out there)

**FD Alert has 10 sounds built in, but you can use any WoW sound you like by editing the saved variables folder, found in: WoW\WTF\Account\\<account>\\<server>\\<character>\SavedVariables\FD_Alert.lua

A WoW sound list can be found at http://www.wowwiki.com/API_PlaySoundFile_SoundList (warning, there are thousands of them. I just picked 10 random ones that sounded decent for the mod)

You can turn off the channel messages or sound alert by setting them to "0".

### Possible features

- [ ] Simple GUI
- [ ] Adding visual alert
  
### Changelog
2.0.0
- Simplified addon and neatened code
- Added way to get player's name

1.1.3
- Added tracking of resists/attempts per fight
- Added consecutive resists mentioned in chat

----------------------------------

1.1 and older made by Intermission
1.1
- fixed a couple of typos (didnt effect functionality)
- added a readme.txt (that nobody will read anyway)
- made some of the code slightly more sexier than before

1.0
- release, it works.
----------------------------------
Original by Intermission, on Frostmourne-US
Modernised by CGN - https://github.com/BokChoyWarrior
