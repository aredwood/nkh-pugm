nKH! Pug Manager
========

Private use only. Designed by da_apple and obla.

Commands
------------
### Locking Server
`!lock <password>` will change the password of the server to <password>, then broadcast the new password 	to all players on the server.
If <password> isn’t given, the plugin will generate a random 4 digit sequence (i.e. 6445), and set it as the server password, also broadcasting the new password to the server.

Example: Locking the server with a desired password. 

da_apple: `!lock HELLO`
[nKH!] Password has been changed to: HELLO

Example: Locking the server without a desired password.

da_apple: `!lock`
[nKH!] Password has been changed to: 5667

### Unlocking Server
`!unlock` Changes the server password to “Medic!”.
	
Example: unlocking the server.

da_apple: `!unlock`
[nKH!] Password has been changed to: Medic!

### Autolock
`!autolock <number of players to lock>` will automatically lock the server when the specified player limit (18 in this example) has been reached.

`autolock off` or `autolock 0` will disable the autolock, until it is enabled. Additionally, autolock will disable itself after locking the server.

NOTE: Every time a client connects, and autolock is enabled, the server will print out how many players are needed in order to reach the limit.

Example: Enabling autolock with a player limit of 18.

da_apple:/autolock 18
[nKH!] Server will automatically lock when 18 players have connected.
[nKH!] 17 players short.

Example: Disabling autolock.

da_apple:/autolock off
[nKH!] Autolock has been disabled.

Example: Autolock locking the server.

---18’th player has connected---
[nKH!] Player limit reached, server locked.
[nKH!] Password has been changed to: 5667


!getpass on / !pass off	(both commands work exactly the same way)
	If enabled this command will give the user the current server password.
	Enabled by “!pass on” “!pass off” or “!getpass on” “!getpass off”.
		Example: Using !getpass or !pass.
		da_apple:/pass
[nKH!] Current password is: 5667
		Example: Disabling the use of !pass or !getpass.
		da_apple:/pass off
		[nKH!] !pass has been disabled.
		Example: Enabling the use of !pass or !getpass.
		da_apple:/pass on
		[nKH!] !pass has been enabled.
		Example: Attempting to use !pass or !getpass, when blocked.
da_apple: /pass
[nKH!] !pass has been disabled by the administrator. 		

!getstring	
	If enabled this commands gives the user the connect string to the server.
	This is enabled when !pass / !getpas is enabled, and disabled when it isn’t.
		Example: Using !getstring.
		da_apple:/getstring
[nKH!] Connect string has also been given in console.
connect 127.0.0.1:27015;password 5667 // No Kids Here! #7
		Example: Attempting to use !getstring, when blocked.
		da_apple:/getstring
		[nKH!] !getstring has been disabled by an administrator.
		
!changemap (cp_dustbowl)
	This command will warn the users about a map change, then change the map some time		 	later (currently 5 seconds). However, only after verifying that the map is installed on the server.
		Example: Using !changemap with a valid map.
		da_apple:/changemap cp_granary
[nKH!] Changing map to cp_granary in 5 seconds.
Example: Using !changemap with an invalid map.
da_apple: /changemap pl_rightwater
[nKH!] Map isn’t valid, likely isn’t spelt correctly or not installed.
 	



	
!callspec
	This command will warn users about a spec call, then call sometime later ( currently, this		 	is set to call spec 5-7 seconds after the admin has entered the command.).

	NOTE: Messages appear both in chat, and in the center of the screen.
	NOTE: The admin who entered the command has no way of knowing exactly when the		 	plugin will call spec.
Example: using !speccall to call spec.
da_apple: /speccall
[nKH!] WARNING, SPEC CALL IMMINENT!
**SOME TIME LATER**
Console: spec

!list mumble
!list maps pl_
	This command is get to essentially dump information.
	 If “mumble” is used as the 1st argument, the plugin will broadcast the nKH! mumble		 	details to everyone on the server.
	
	If “maps” is used as the 1st argument, a 2nd argument will be required which will be the			“extension” of a map (pl_,cp_,koth_).The plugin will then dump all of the maps beginning with that		extension to the issuer’s console.
		Example: Using !list mumble to dump the mumble details.
		da_apple:/list mumble
		[nKH!] nKH! Mumble is: 119.252.190.75 | 64888
		[nKH!] 119.252.190.75 - Address
		[nKH!] 64888 - Port
		Example: Using !list maps pl_ to list all currently installed			payload maps.
		da_apple:/list maps pl_
		[nKH!] Map listing results for pl_ have been outputted to console.
		**IN CONSOLE**
		-------------
PENDING:   (fs) pl_badwater.bsp
PENDING:   (fs) pl_badwater_rainy.bsp
PENDING:   (fs) pl_badwater_snowy.bsp
PENDING:   (fs) pl_barnblitz.bsp
PENDING:   (fs) pl_barnblitz_pro.bsp
PENDING:   (fs) pl_barnblitz_pro4.bsp
		ect,ect,ect.


If a command has been used incorrectly, the plugin will notify the user.

To Do
------------
* Improve memory management
* Add help function, maybe?

Notes
------------
* It is very important that the plugin IS NOT reloaded during a game, a number of the functions in this plugin rely on accurate counting of players. Reloading the plugin will reset the counters.
* All commands (not their prints) can be hidden by replacing the “!” with a “/”.
