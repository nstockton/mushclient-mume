# mushclient-mume
A portable copy of [MUSHclient](http://mushclient.com/mushclient/mushclient.htm "MUSHclient Home Page") bundled with scripts for playing [MUME](http://mume.org "MUME Official Site") and a [mapper](https://github.com/nstockton/mapperproxy-mume "Mapper Proxy GitHub Page") for use by blind players.

## License And Credits
All of the MUSHclient plugins that I (Nick Stockton) wrote are licensed under the terms of the [Mozilla Public License, version 2.0.](https://www.mozilla.org/en-US/MPL/2.0/ "MPL2 official Site") MUSHclient is copyrighted by Nick Gammon, and licenses for MUSHclient and bundled third-party components can be found in the docs directory of this project.

## Installation
### Screen Reader Specific Instructions.
#### NVDA
If you are an [NVDA](https://www.nvaccess.org "NV ACCESS Official Site") user, please first install the MUSHclient add-on for NVDA, located in the nvda_addon directory of this project.
* If you are using a normal (not portable) installation of NVDA, you can begin the installation process by pressing enter on the add-on file.
* If you are using a portable copy of NVDA, install the add-on through the add-ons manager (NVDA+N to bring up the NVDA menu, select Tools, select Manage add-ons).
### If Running From Source
Install the [Python interpreter](https://python.org "Python Home Page"), and make sure it's in your path before running this package.

## Running MUSHclient With The Mapper
You should start MUSHclient by pressing enter on the mc.bat file. Do *not* try to run it by running MUSHclient.exe. mc.bat will first start the mapper and then mushclient.
Windows fire wall may prompt you to add an exception for the mapper. This is because the mapper acts as a proxy between MUSHclient and Mume. Add the exception if prompted.

## MUSHclient Plugins
This project contains the following MUSHclient plugins and commands.
### Auto Enchanting
For use with characters with the enchant spell practiced, this script will automatically pull an arrow out of a container of non-enchanted arrows, cast enchant on the arrow, compare it against an already max-chanted arrow, and put the arrow in a container of chanted arrows if it was max-chanted or back in the unchanted container otherwise. The plugin also handles automatic sleeping until the character has full mana, automatic drinking and eating when needed, and training skills so they don't decay while auto-chanting. Note that autochanting requires you to be wielding a max-chanted arrow to be compared against.
#### Aliases
* autochant  --  Start or stop auto-enchant mode.
* setarrow [keyword]  --  Set the keyword to be used when handling arrows to be enchanted (defaults to 'arrow').
* setunchanted [keyword]  --  Set the keyword for the container containing unchanted arrows (defaults to 1.quiver).
* setchanted [keyword]  --  Set the keyword for the container containing max-chanted arrows (defaults to 2.quiver).
### Castor Spell Translator
When a mob or player casts a spell, translate his/her incantation such as 'yzabra' into the human readable spell name 'fear'. Also shorten some overly verbose messages such as 'You raise your hand and an icy wind starts to blow through the room.' and replace them with shortened messages such as 'Feared!'.
#### Macros
Control+I  --  Toggle the interrupting of speech when someone or something casts a spell (defaults to off).
### Communication
Log and review communication channels.
#### Aliases
* pl [text|number]  -  Review the log for the pray channel. If a string is passed to the alias, search the log for that text. If a number is passed, Print that many lines from the end of the log. If no argument is given, print the last 20 lines from the log.
* nl [text|number]  -  Review the log for the narrate channel. If a string is passed to the alias, search the log for that text. If a number is passed, Print that many lines from the end of the log. If no argument is given, print the last 20 lines from the log.
* sl [text|number]  -  Review the log for the say channel. If a string is passed to the alias, search the log for that text. If a number is passed, Print that many lines from the end of the log. If no argument is given, print the last 20 lines from the log.
* tl [text|number]  -  Review the log for the tell channel. If a string is passed to the alias, search the log for that text. If a number is passed, Print that many lines from the end of the log. If no argument is given, print the last 20 lines from the log.
* x  -  Print the last line from the say log.
* X  -  Print the last line from the tell log.
* rep [text]  -  Send a reply to the last player who sent you a tell.
### Doors
Perform actions on doors.
#### Aliases
* autoopen  --  Turn on or off automatic opening of doors when the player runs into them (Defaults to on).
* door [text|clear]  --  manually set the door name or clear the previously set value.
* d[bcklopru][neswud]  --  Bash, close, block, lock, open, pick, break, unlock the door north, east, south, west, up, down. If the door name was manually set, use it. Otherwise, use the door name from the mapper.
### Grouping
Makes you more useful in a group.
#### Aliases
* leader [name|clear]  --  Manually set or clear the leader.
* fs  --  Follow self. Stops you from following someone.
* autogroup  --  Turn automatic grouping of players when they raise their hand on or off (defaults to off).
* autoride  --  Turn automatic riding or leading when the leader rides or leads on or off (defaults to on)
* lt [text]  --  Tell the leader a message.
* lp  --  Protect the leader.
* lw  --  Whois leader.
* lr  --  Rescue leader.
* lf  --  Follow leader.
### Herb Substitutions
Add the name of herbs to their description when dropped in a room.
### Hunting
Provides a targeting system for attacking things.
#### Aliases
* ac[1|2] [command]  --  Set the primary or secondary action to be performed on target when using the macros. With no arguments, defaults to primary.
* b[b][d][f]  --  Bash primary or secondary target. If 'd' is given, sends 'bash dis' instead of 'bash'. If 'f' is given, also sends 'flee' after the command.
* e[e]t  --  Examine primary or secondary target.
* h[h][f]  --  Shoot primary or secondary target. If 'f' is given, also sends'flee' after the command.
* j[j][f]  --  Backstab primary or secondary target. If 'f' is given, also sends 'flee' after the command.
* k[k][f]  --  Kill primary or secondary target. If 'f' is given, also sends 'flee' after the command.
* k[bedahmor]  --  Kill *bear*, *elf*, *dwarf*, *half-elf*, *hobbit*, *man*, *orc*, or *troll*.
* t[t] [name]  --  Set the primary or secondary target.
* t[t][bedahmor]  --  Set primary or secondary target to *bear*, *elf*, *dwarf*, *half-elf*, *hobbit*, *man*, *orc*, or *troll*.
* .[.]  --  Track primary or secondary target.
* ,[,]  --  Where primary or secondary target.
#### Macros
* Alt+1 through Alt+0  --  Perform primary action on 1.primary target through10.primary target.
* Alt+shift+1 through Alt+shift+0  --  Perform secondary action on 1.primary target through 10.primary target.
* Control+1 through Control+0  --  Perform primary action on 1.secondary target through 10.secondary target.
* Control+shift+1 through Control+shift+0  --  Perform secondary action on 1.secondary target through 10.secondary target.
### Key Substitutions
Adds information about which door a key unlocks when the key is in the player's inventory.
### Lock Pick Substitutions
Adds information about which lock pick upgrades a set of lock picks has when the picks are examined.
### Macros
Contains macros for performing different tasks. Some macros are different depending on whether the player is using the standard QWERTY keyboard layout or the [Dvorak](https://en.wikipedia.org/wiki/Dvorak_Simplified_Keyboard "Dvorak Entry On Wikipedia") layout.
#### QWERTY And Dvorak Common Macros
* Control+B  --  bash
* Control+H  --  shoot
* Control+M  --  assist
* Control+U  --  Clear input line.
#### QWERTY Macros
* Alt+I  --  north
* Alt+shift+I  --  scout north
* Alt+L  --  east
* Alt+shift+L  --  scout east
* Alt+K  --  south
* Alt+shift+K  --  scout south
* Alt+J  --  west
* Alt+shift+J  --  scout west
* Alt+U  --  up
* Alt+shift+U  --  scout up
* Alt+O  --  down
* Alt+shift+O  --  scout down
* Alt+;  --  Speak the current room name.
* Alt+G  --  Speak current buffer's health and name.
* Alt+F  --  Speak current opponent's health and name.
* Alt+D  --  Speak current Health.
* Alt+S  --  Speak current Mana.
* Alt+A  --  Speak current Moves and current mount's moves if riding.
* Alt+Z  --  Speak current room's light status.
* Alt+X  --  Speak current room's terrain.
* Alt+C  --  Speak health and name of the last opponent.
* Alt+V  --  Speak current movement flags (sneaking, swimming, climbing, riding).
* Alt+B  --  Speak Sneaking status.
* Alt+Q  --  First user definable key. Perform command associated with this key.
* Alt+shift+Q  --  Set the associated command for the first user definable key from the contents of the input line, then clear the input line.
* Alt+W  --  Second user definable key. Perform command associated with this key.
* Alt+shift+W  --  Set the associated command for the second user definable key from the contents of the input line, then clear the input line.
* Alt+E  --  Third user definable key. Perform command associated with this key.
* Alt+shift+E  --  Set the associated command for the third user definable key from the contents of the input line, then clear the input line.
* Alt+R  --  Fourth user definable key. Perform command associated with this key.
* Alt+shift+R  --  Set the associated command for the fourth user definable key from the contents of the input line, then clear the input line.
#### Dvorak Macros
* Alt+C  --  north
* Alt+shift+C  --  scout north
* Alt+N  --  east
* Alt+shift+N  --  scout east
* Alt+T  --  south
* Alt+shift+T  --  scout south
* Alt+H  --  west
* Alt+shift+H  --  scout west
* Alt+G  --  up
* Alt+shift+G  --  scout up
* Alt+R  --  down
* Alt+shift+R  --  scout down
* Alt+S  --  Speak the current room name.
* Alt+I  --  Speak current buffer's health and name.
* Alt+U  --  Speak current opponent's health and name.
* Alt+E  --  Speak current Health.
* Alt+O  --  Speak current Mana.
* Alt+A  --  Speak current Moves and current mount's moves if riding.
* Alt+;  --  Speak current room's light status.
* Alt+Q  --  Speak current room's terrain.
* Alt+J  --  Speak health and name of the last opponent.
* Alt+K  --  Speak current movement flags (sneaking, swimming, climbing, riding).
* Alt+X  --  Speak Sneaking status.
* Alt+'  --  First user definable key. Perform command associated with this key.
* Alt+shift+'  --  Set the associated command for the first user definable key from the contents of the input line, then clear the input line.
* Alt+,  --  Second user definable key. Perform command associated with this key.
* Alt+shift+,  --  Set the associated command for the second user definable key from the contents of the input line, then clear the input line.
* Alt+.  --  Third user definable key. Perform command associated with this key.
* Alt+shift+.  --  Set the associated command for the third user definable key from the contents of the input line, then clear the input line.
* Alt+p  --  Fourth user definable key. Perform command associated with this key.
* Alt+shift+p  --  Set the associated command for the fourth user definable key from the contents of the input line, then clear the input line.
### Misc
Miscellaneous aliases and triggers that don't belong anywhere else.
#### Aliases
* affect  --  Prints a list of spells and other things the player is affected by.
* age  --  Prints the character's age.
* align  --  Prints the character's alignment.
* bc[number]  --  Butcher number.corpse.
* belt  --  Switch the belt the character is currently wearing with the one in the character's pack.
* bpack  --  Switch the boots that the character is currently wearing with the ones in the character's pack.
* bpouch  --  Switch the boots that the character is currently wearing with the ones in the character's pouch.
* ccring  --  Use the cure critic ring in the character's pack.
* cir  --  Remove the character's helm, and switch to using the character's circlet.
* citizen  --  Print the list of towns in which the character has citizenship.
* cpack  --  Switch the cloak, fur, or mantle that the character is currently wearing with the cloak in the character's pack.
* cpouch  --  Switch the cloak, fur, or mantle that the character is currently wearing with the cloak in the character's pouch.
* dg  --  Drink from the goblet in the character's pack.
* dragall  --  Drag all corpses in the room.
* fbag  --  Get food from the character's elven bag and eat it.
* fpack  --  Switch the cloak, fur, or mantle that the character is wearing with the fur in the character's pack.
* fpouch  --  Switch the cloak, fur, or mantle that the character is wearing with the fur in the character's pouch.
* helm  --  Remove the character's circlet, and switch to using the character's helm.
* kbag  --  Get a butcher knife from the character's elven bag.
* lev  --  Prints the character's current level.
* li [container]  --  Look in container.
* money  --  Print how much money the character has.
* movestakes  --  Open azra-zaira's door.
* mpack  --  Switch the cloak, fur, or mantle that the character is currently wearing with the mantle in the character's pack.
* mpouch  --  Switch the cloak, fur, or mantle that the character is currently wearing with the mantle in the character's pouch.
* newid  --  Generate a new unique ID and copy it to the clipboard. This is used for plugin developers.
* pbs [player]  --  Get the PBS from the character's pack, wield it, and use it. If a player name is supplied, use the pbs on him/her instead of self.
* pg  --  Pour water into the character's goblet stored in the character's pack.
* pipe  --  Rest and use the pipe stored in the character's pack.
* ra  --  Reveal all. Use this if you find someone hiding in a room to alert everyone else in the room to the player's presents.
* rbag  --  Get a rope from the character's elven bag.
* rq  --  Reveal quick.
* rr  --  Get all.arrow all.corpse, get all.arrow, put all.arrow quiver.
* rt  --  reveal thorough.
* sq  --  Search quick.
* st  --  Search thorough.
* string  --  Use the strength ring in the character's pack.
* wbag  --  Get water from the character's elven bag and drink it.
* weight  --  Print the weight of the character's equipment.
* ws  --  Wake, stand.
### Mob Substitutions
Add info about the mob's level for known mobs.
### Path Walker
This plugin allows you to automatically walk along roads. It works by looking for directions in the exits line enclosed in '=' signs. If the end of the road or a junction is reached, automatic walking will stop.
#### Aliases
* p [direction]  --  Start walking along the road in direction.
* pp  --  Stop auto walking along the road.
### Reentering
This plugin provides aliases for escaping and for returning from the direction the player fled from.
#### Aliases
* v  --  Return the way you came from after fleeing out of a room.
* nn  --  Escape north.
* ee  --  Escape east.
* ss  --  Escape south.
* ww  --  Escape west.
* uu  --  Escape up.
* dd  --  Escape down.
### Report
Provides aliases for printing and reporting the character's current hit/mana/movement points.
#### Aliases
* hp  --  Print the character's current hit points.
* mp  --  Print the character's current mana points.
* mv  --  Print the character's current movement points.
* tnl  --  Print how much xp and tp the character needs to level.
* rp  --  Report the character's current hit/mana/movement points to the room.
* rptnl  --  Report how much xp and tp the character needs to level to the room.
* rpf  --  Report hit/mana/movement points and xp/tp needed to level to the room.
### Secrets Database
Provides a database of secret door names and commands to add/modify/view the data. This database is separate from the mapper's database.
#### Aliases
* dadd [name] [direction]  --  Add a door with name to direction. The current room name will be used as the key when searching.
* ddel [name|all] [direction|all]  --  Delete a door with name to direction. The current room name will be used as the key when searching.
* dinfo [text]  --  Print the secret exit information for all room names in the database that match text.
* ddo  --  Open all secret exits that have a room name that matches the current room's name.
### Sounds
Provides sound triggers for MUME. When you land an aggressive spell on someone else, the corresponding sound will be played on the left channel. When someone lands an aggressive spell on you, the corresponding sound will play on the right channel. Everything else will be played in both channels.
#### Macros
* F12  --  Raise sound volume.
* shift+F12  --  Lower sound volume.
* Control+shift+F12  --  Mute sounds.
### Spell Timers
Shows how long your support spells have been up. you can see the list of support spells as part of the info command, the status command, or the affect alias from the Misc plugin.
### Time
Allows you to see the current game time, how long until next winter, how long until DK opens, etc. The time will be synchronized to dawn/dusk events, or when you walk into a room with a clock.
#### Aliases
* pulldate  --  Pull the appropriate levers to unlock the door in Mystical.
* ti  --  Print time information.
* nti  --  Narrate time information.
* sti  --  Say time information.
### XML Parser
This plugin parses the XML output from mume and dispatches events to other plugins for each supported XML element.
#### Aliases
* showprompt  --  Toggle the displaying of the MUME prompt on or off (defaults to on). Once you get used to using the macros for speaking prompt information, you might find it less spammy to turn showprompt off and use the macros to get your health information instead.
### XP Counter
Keeps track of how much XP/TP you've gained for each kill, how much you've gained for the current session, and how much you need to level.
#### Aliases
* xp  --  Print how much XP/TP gained for last kill, for current session, and how much is needed to level. Values are updated each time you kill something.
* TP  --  Print how much TP gained since last kill or since the tp alias was last executed, How much gained for current session, and how much is needed to level. This is useful while TPing as the XP alias only updates it's values after you kill something.
### Output Functions
Originally written by Oriol Gomez and modified by me (Nick Stockton), this plugin allows you to review the lines in the output window without using screen reader specific commands. It's useful to utilize it as a second buffer for reviewing text that has scrolled off the screen while using the screen reader's review commands to review the current output. This plugin contains Macros exclusive to the QWERTY and [Dvorak](https://en.wikipedia.org/wiki/Dvorak_Simplified_Keyboard "Dvorak Entry On Wikipedia") keyboard layouts.
#### QWERTY And Dvorak Common Macros
* Control+shift+C  --  If the current line being reviewed contains a locate key or item's magical key, copy *just* the key to the clipboard.
* Control+alt+enter  --  Toggle speech interrupt when the enter key is pressed.
* Control+shift+space  --  Set a start marker on the currently reviewed line for copying text to the clipboard. When this Macro is pressed a second time, the lines from start to the currently reviewed line will be copied to the clipboard.
#### QWERTY Macros
* Control+shift+j  --  Review the previous line.
* Control+shift+k  --  Review the current line.
* Control+shift+l  --  Review the next line.
* Control+shift+h  --  Review the first line in the output buffer.
* Control+shift+;  --  Review the last line in the output buffer.
#### Dvorak Macros
* Control+shift+h  --  Review the previous line.
* Control+shift+t  --  Review the current line.
* Control+shift+n  --  Review the next line.
* Control+shift+d  --  Review the first line in the output buffer.
* Control+shift+s  --  Review the last line in the output buffer.
### Repeat Command
This plugin by Nick Gammon allows you to repeat a command multiple times.
#### Aliases
* #[number] [command]  --  Repeat command number times.
### Screen Reader Speak
I (Nick Stockton) wrote this plugin to be a drop-in replacement for the Mush Reader plugin used by other projects. It wraps the various screen reader APIs directly using the FFI library built into LuaJit, rather than requiring a separate dll to wrap the APIs.
#### Aliases
* tts  --  Toggle automatic speech output via the screen reader on or off (defaults to on).

## Mapper Proxy
### Auto Mapping Commands
Auto mapping mode must be on for these commands to have any effect.
* autolink  --  Toggle Auto linking on or off. If on, the mapper will attempt to link undefined exits in newly added rooms.
* automap  --  Toggle automatic mapping mode on.
* automerge  --  Toggle automatic merging of duplicate rooms on or off.
* autoupdate  --  Toggle Automatic updating of room name/descriptions/dynamic descriptions on or off.
### Map Editing Commands
* doorflags [add|remove] [hidden|needkey|noblock|nobreak|nopick|delayed|reserved1|reserved2] [north|east|south|west|up|down]  --  Modify door flags for a given direction.
* exitflags [add|remove] [exit|door|road|climb|random|special|avoid|no_match] [north|east|south|west|up|down]  --  Modify exit flags for a given direction.
* ralign [good|neutral|evil|undefined]  --  Modify the alignment flag of the current room.
* ravoid [+|-]  --  Set or clear the avoid flag for the current room. If the avoid flag is set, the mapper will try to avoid the room when path finding.
* rdelete [vnum]  --  Delete the room with vnum. If the mapper is synced and no vnum is given, delete the current room.
* rlabel [add|delete|info|search] [label] [vnum]  --  Manage room labels. Vnum is only used when adding a room. Leave it blank to use the current room's vnum. Use rlabel info all to get a list of all labels.
* rlight [lit|dark|undefined]  --  Modify the light flag of the current room.
* rlink [add|remove] [oneway] [vnum] [north|east|south|west|up|down]  --  Manually manage links from the current room to room with vnum. If oneway is given, treat the link as unidirectional.
* rloadflags [add|remove] [treasure|armour|weapon|water|food|herb|key|mule|horse|packhorse|trainedhorse|rohirrim|warg|boat|attention|tower]  --  Modify the load flags of the current room.
* rmobflags [add|remove] [rent|shop|weaponshop|armourshop|foodshop|petshop|guild|scoutguild|mageguild|clericguild|warriorguild|rangerguild|smob|quest|any|reserved2]  --  Modify the mob flags of the current room.
* rnote [text]  --  Modify the note for the current room.
* rportable [portable|notportable|undefined]  --  Modify the portable flag of the current room.
* rridable [ridable|notridable|undefined]  --  Modify the ridable flag of the current room.
* rterrain [death|city|shallowwater|forest|hills|road|cavern|field|water|underwater|rapids|indoors|brush|tunnel|mountains|random|undefined]  --  Modify the terrain of the current room.
* rx [number]  --  Modify the X coordinate of the current room.
* ry [number]  --  Modify the Y coordinate of the current room.
* rz [number]  --  Modify the Z coordinate of the current room.
* savemap  --  Save modifications to the map to disk.
* secret [add|remove] [name] [north|east|south|west|up|down]  --  Add or remove a secret door in the current room.
### Searching Commands
* fdoor [text]  --  Search the map for rooms with doors matching text. Returns the closest 20 rooms to you based on the [Manhattan Distance.](https://en.wikipedia.org/wiki/Taxicab_geometry "Wikipedia Page On Taxicab Geometry")
* fdynamic [text]  --  Search the map for rooms with dynamic descriptions matching text. Returns the nearest 20 rooms to you (furthest to closest) based on the [Manhattan Distance.](https://en.wikipedia.org/wiki/Taxicab_geometry "Wikipedia Page On Taxicab Geometry")
* flabel [text]  --  Search the map for rooms with labels matching text. Returns the nearest 20 rooms to you (furthest to closest) based on the [Manhattan Distance.](https://en.wikipedia.org/wiki/Taxicab_geometry "Wikipedia Page On Taxicab Geometry") If no text is given, will show the 20 closest labeled rooms.
* fname [text]  --  Search the map for rooms with names matching text. Returns the closest 20 rooms to you based on the [Manhattan Distance.](https://en.wikipedia.org/wiki/Taxicab_geometry "Wikipedia Page On Taxicab Geometry")
* fnote [text]  --  Search the map for rooms with notes matching text. Returns the closest 20 rooms to you based on the [Manhattan Distance.](https://en.wikipedia.org/wiki/Taxicab_geometry "Wikipedia Page On Taxicab Geometry")
### Miscellaneous Mapper Commands
* getlabel [vnum]  --  Returns the label or labels defined for the room with vnum. If no vnum is supplied, the current room's vnum is used.
* gettimer  --  Returns the amount of seconds since the mapper was started in an optimal format for triggering. This is to assist scripters who use clients with no time stamp support such as VIP Mud.
* gettimerms  --  Returns the amount of milliseconds since the mapper was started in an optimal format for triggering. This is to assist scripters who use clients with no time stamp support such as VIP Mud.
* path [vnum|label] [nodeath|nocity|noshallowwater|noforest|nohills|noroad|nocavern|nofield|nowater|nounderwater|norapids|noindoors|nobrush|notunnel|nomountains|norandom|noundefined]  --  Print speed walk directions from the current room to the room with vnum or label. If one or more avoid terrain flags are given after the destination, the mapper will try to avoid all rooms with that terrain type. Multiple avoid terrains can be ringed together with the '|' character, for example, path ingrove noroad|nobrush.
* rinfo [vnum|label]  --  Print info about the room with vnum or label. If no vnum or label is given, use current room.
* run [c|t] [vnum|label] [nodeath|nocity|noshallowwater|noforest|nohills|noroad|nocavern|nofield|nowater|nounderwater|norapids|noindoors|nobrush|notunnel|nomountains|norandom|noundefined]  --  Automatically walk from the current room to the room with vnum or label. If 'c' is provided instead of a vnum or label, the mapper will recalculate the path from the current room to the previously provided destination. If t (short for target) is given before the vnum or label, the mapper will store the destination, but won't start auto walking until the user enters 'run c'. If one or more avoid terrain flags are given after the destination, the mapper will try to avoid all rooms with that terrain type. Multiple avoid terrains can be ringed together with the '|' character, for example, run ingrove noroad|nobrush.
* secretaction [action] [north|east|south|west|up|down]  --  Perform an action on a secret door in a given direction. This command is meant to be called from an alias. For example, secretaction open east.
* step [label|vnum]  --  Move 1 room towards the destination room matching label or vnum.
* stop  --  Stop auto walking.
* sync [vnum|label]  --  Manually sync the map to the room with vnum or label. If no vnum or label is given, mapper will be placed in an unsynced state, and will try to automatically sync to the current room.
* tvnum  --  Tell the vnum of the current room to another player.
* vnum  --  Print the vnum of the current room.
