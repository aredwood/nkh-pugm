/*
	nKH! Pug Manager
	by da_apple
	it's my first plugin OK! :(
	I wonder if this will be of any use.
*/
#pragma semicolon 1
#include <morecolors>
#include <sdkhooks>
/*
	TODO LIST:

	Optimize,
	Add more comments,
	Add map listing / searching,
	Add customization via ConVars





*/

public Plugin:myinfo = {
	name = "nKH! Pug Manager",
	author = "da_apple",
	description = "Simplifys Pug management",
	version = "1.0",
	url = "http://steamcommunity.com/groups/nokidshere"
};
	//morecolors.inc needs this for backwars compatibility
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) { 
   		MarkNativeAsOptional("GetUserMessageType"); 
   		return APLRes_Success; 
	}
public OnPluginStart(){

	//Hooks
	//HookEvent("teamplay_game_over", Event_gameOver);	//Event for when game ends.
	HookEvent("tf_game_over", Event_gameOver);			//Event for when game ends.

	//Allow people with sm_rcon access to use this plugin, makes sense.
		//Commands
		RegAdminCmd("lock", passwordLock, ADMFLAG_RCON);
		RegAdminCmd("unlock", passwordUnlock,ADMFLAG_RCON);
		RegAdminCmd("autolock", autoLock,ADMFLAG_RCON);
		RegAdminCmd("changemap",mapChange,ADMFLAG_RCON);
		RegAdminCmd("callspec",callSpec,ADMFLAG_RCON);
		RegAdminCmd("list",list,ADMFLAG_RCON);
		RegConsoleCmd("pass", pass);
		RegConsoleCmd("getpass",pass);
		RegConsoleCmd("getstring",getString);


	//let em know.
	PrintToServer("nKH! Pug Manager 1.0 loaded.");
}
//A small thank you message.
public Action:Event_gameOver(Handle:event, const String:reason[],){

	//The only reason this uses a timer, is because STV record messages and PREC messages can easily flood chat.
	new Float:thankYouDelay = 2.0;
	CreateTimer(thankYouDelay,thankYouDisplay);
}

public Action:thankYouDisplay(Handle:timer){
	CPrintToChatAll("{strange}[nKH!]{white} Thank you for playing on nKH!");
	CPrintToChatAll("{strange}[nKH!]{white} http://steamcommunity.com/groups/NoKidsHerePugsandLobbies");
}

/*                                                      
							Function that manages password locking.

*/

public Action:passwordLock(client,args){
	//If user supplied a password.
	if(GetCmdArgs() < 1){
		//generate new pass
		new String:Nums[] = "0123456789";
		new String:passwordLockGenerated[5];
		for (new i = 0; i <= 3; i++){
			//Could actually just use the number generated from RandomNum instead of using it to get a value from an array.
			new RandomNum = GetRandomInt(0,9);
			passwordLockGenerated[i] = Nums[RandomNum];
		}
		ServerCommand("sv_password %s",passwordLockGenerated);
		CPrintToChatAll("{strange}[nKH!]{white} Password has been changed to: %s",passwordLockGenerated);
 
	}
	else{
		//desired password, hopefully people won't use a password with >32 characters.
		new String:passwordLockDesired[32];
		GetCmdArg(1,passwordLockDesired,sizeof(passwordLockDesired));
	
		//Change password
		ServerCommand("sv_password %s",passwordLockDesired);
		CPrintToChatAll("{strange}[nKH!]{white} Password has been changed to: %s",passwordLockDesired);
	}
}
/*
										Function that manages unlocking.	
*/
public Action:passwordUnlock(client,args){
	ServerCommand("lock Medic!");
}
/*                                              
										Function that manages autolocking (actually the most useful feature of this plugin.)
*/

//Why isn't there a tag for integers?
new CurrentPlayers;
new bool:AutoLockBool = false;
new AutoLockLimit; //This varible was actually a float at some stage.
new PlayerDifference;

//Function to check whether to lock
public DoAutoLock(){
	if(CurrentPlayers >= AutoLockLimit && AutoLockBool == true){
		ServerCommand("lock");
		CPrintToChatAll("{strange}[nKH!]{white} Player limit reached, server locked.");
		AutoLockBool = false;
	}
	if(CurrentPlayers < AutoLockLimit && AutoLockBool == true){
		PlayerDifference = AutoLockLimit - CurrentPlayers;
		//CPrintToChatAll("{strange}[nKH!]{white} %i players short.",PlayerDifference);
		if(PlayerDifference = 1){
			CPrintToChatAll("{strange}[nKH!]{white} %i %s short.",PlayerDifference,"player");
		}
		if(PlayerDifference > 1){
			CPrintToChatAll("{strange}[nKH!]{white} %i %s short.",PlayerDifference,"players");
		}
	}
	//playerlimit not reached, or autolock is disabled.

}
//This function is executed upon !autolock
public Action:autoLock(client,args){
	//passwords set via !lock will have a 15 character limit.
	new String:AutoLockLimitDesiredString[16]; 

	GetCmdArg(1,AutoLockLimitDesiredString,sizeof(AutoLockLimitDesiredString));
	//Apparently argruments are ALWAYS returned as strings, we'll need to convert them.
	new AutoLockLimitDesired = StringToInt(AutoLockLimitDesiredString);
	//If I wanted to be smart, i'd make it so that the desired limit would be <= MaxPlayers.
	if(AutoLockLimitDesired > 0 && AutoLockLimitDesired < 99){
		CPrintToChat(client,"{strange}[nKH!]{white} Server will automatically lock when %i players have connected.",AutoLockLimitDesired);
		AutoLockLimit = AutoLockLimitDesired;
		AutoLockBool = true;
	}
	//If the parameters make no sense.
	if(AutoLockLimitDesired < 0 || AutoLockLimitDesired > 99){
		CPrintToChat(client,"{strange}[nKH!]{white} Incorrent parameters!");
	}
	//For disabling autolock.
	if(AutoLockLimitDesired == 0 || !strcmp(AutoLockLimitDesiredString,"off")){
		CPrintToChatAll("{strange}[nKH!]{white} Autolock has been disabled.");
		AutoLockBool = false;
	}
	DoAutoLock();
	return Plugin_Handled;
}
//Whenever a client connets.
public OnClientConnected(){
	CurrentPlayers = CurrentPlayers + 1;
	DoAutoLock();
}
//Whenever a client disconnects.
public OnClientDisconnect(){
	CurrentPlayers = CurrentPlayers - 1;
	DoAutoLock();
}
/*                                                                                                                 
										Function to manage !getpass and !pass.
*/
new bool:GetPass = true; //Getstring shares this.
public Action:pass(client,args){
	if(GetCmdArgs() < 1 && GetPass == true){
		//Get's password.
		new Handle:CurrentPasswordHandler = FindConVar("sv_password");
		decl String:CurrentPassword[64];
		GetConVarString(CurrentPasswordHandler,CurrentPassword,sizeof(CurrentPassword));
		//CPrint password to client.
		CPrintToChat(client,"{strange}[nKH!]{white} Current password is: %s",CurrentPassword);
	}
	//If someone requests the password, but it has been disabled by an admin.
	if(GetCmdArgs() < 1 && GetPass == false){
		CPrintToChat(client,"{strange}[nKH!]{white} !pass has been disabled by the administrator.");
	}

	//Controls the enabling and disabling of !pass and !getpass.
	if(CheckCommandAccess(client,"pass",ADMFLAG_RCON)){
		new String:PassArgOne[4];
		GetCmdArg(1,PassArgOne,4);
		if(strcmp(PassArgOne,"on",false) == 0){
			GetPass = true;
			CPrintToChatAll("{strange}[nKH!]{white} !pass has been enabled.");
		}
		if(strcmp(PassArgOne,"off",false) == 0){
			GetPass = false;
			CPrintToChatAll("{strange}[nKH!]{white} !pass has been disabled.");
		}
	}
}
/*
							Function to control !getstring
*/

public Action:getString(client,args){
	//ip 															//	FIND
	new String:ip[16];												//	A
	new Handle:ipHandler = FindConVar("ip");						//	MUCH
	GetConVarString(ipHandler,ip,sizeof(ip));						//	BETTER
																	//	FUCKING
	//hostport 														//	WAY
	new String:hostport[7];											//	TO
	new Handle:hostportHandler = FindConVar("hostport");			//	DO
	GetConVarString(hostportHandler,hostport,sizeof(hostport));		//	THIS.
																	//	THIS
	//hostname  													//	COULDN'T 
	new String:hostname[32];										//	BE
	new Handle:hostnameHandler = FindConVar("hostname");			//	ANYMORE
	GetConVarString(hostnameHandler,hostname,sizeof(hostname));		//	INEFFICIENT

	//GetPass is true, and no extra values were specified
	if(GetCmdArgs() < 1 && GetPass == true){
		//Get's password.
		new Handle:CurrentPasswordHandler = FindConVar("sv_password");
		decl String:CurrentPassword[64];
		GetConVarString(CurrentPasswordHandler,CurrentPassword,sizeof(CurrentPassword));
		//CPrint password to client.
		CPrintToChat(client,"{strange}[nKH!]{white} Connect string has also been given in console.");
		CPrintToChat(client,"{white}connect %s:%s; password %s //%s", ip,hostport,CurrentPassword,hostname);
		PrintToConsole(client,"connect %s:%s; password %s //%s",ip,hostport,CurrentPassword,hostname);
	}
	//Client requested the string, but GetPass was set to false.
	if(GetCmdArgs() < 1 && GetPass == false){
		CPrintToChat(client,"{strange}[nKH!]{white} !getstring has been disabled by an administrator.");
	}
}
/*                                             
							Function to manage map changing. (Please note, that the only advantage to using this feature is that players will get a warning before the map changes.)
*/
//Is MapTimer still able to access this, if it was in MapName.
new String:MapName[16]; //Scratch 16 length string variable.

public Action:mapChange(client,args){
	//Get the desired map.
	new String:MapInput[16];
	GetCmdArg(1,MapInput,sizeof(MapInput));
	//Map wasn't specified.
	if(GetCmdArgs() < 1){
		//you fukt it.
		CPrintToChat(client,"{strange}[nKH!]{white} Incorrect usage!");
	}

	if(SplitString(MapInput,".bsp",MapName,sizeof(MapName)) == -1){
		//Actually forgot what this all means.
		strcopy(MapName,sizeof(MapName),MapInput);
	}
	if(IsMapValid(MapName)){
		CPrintToChatAll("{strange}[nKH!]{white} Changing map to %s in 5 seconds.",MapName);
		//Whole purpose of the timer is to alert players of the map change.
		CreateTimer(5.0,MapTimer);
	}else{
		//When a map that isn't installed is given, or something like !changemap SWAGBOIZE happens.
		CPrintToChat(client,"{strange}[nKH!]{white} Map not found, likely spelt incorrectly or not installed.");
	}
}
public Action:MapTimer(Handle:timer){
	//Change the map.
	ServerCommand("changelevel %s",MapName);
}
/*
							Function to manage spec calling.
*/
public Action:callSpec(client,args){
	//It's safe to edit this.
	new Float:specTime = GetRandomFloat(5.0,7.0); 
	CreateTimer(specTime,specCall);
	//GIves out the warning.
	CPrintToChatAll("{strange}[nKH!]{white} WARNING, SPEC CALL IMMINENT!");
	ServerCommand("sm_csay WARNING");
}
//Call Spec.
public Action:specCall(Handle:timer){
	ServerCommand("sm_csay spec; say spec");
}
/*
							This function's main purpose is to dump information.           
*/
public Action:list(client,args){
	new String:listArgOne[8];
	new String:listArgTwo[8];
	GetCmdArg(1,listArgOne,sizeof(listArgOne));
	GetCmdArg(2,listArgTwo,sizeof(listArgTwo));
	//If the first parameter is "mumble" the No Kids Here! mumble details are dumped.
	if(strcmp(listArgOne,"mumble",false) == 0){
		CPrintToChatAll("{strange}[nKH!]{white} nKH! Mumble is: 119.252.190.75 | 64888");
		CPrintToChatAll("{strange}[nKH!]{white} 119.252.190.75 - Address");
		CPrintToChatAll("{strange}[nKH!]{white} 64888 - Port");
	}
	//manages map list 
	if(strcmp(listArgOne,"maps",false) == 0 && GetCmdArgs() <= 3){
		CPrintToChat(client,"{strange}[nKH!]{white} Map listing results for \"%s\" have been outputted to console.", listArgTwo);
		FakeClientCommand(client,"sm_rcon maps %s",listArgTwo);
		PrintToConsole(client,"[nKH!] END OF LISTING.");
	}
}



