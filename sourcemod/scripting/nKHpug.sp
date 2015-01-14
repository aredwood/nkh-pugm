/*
	nKH! Pug Manager
	by da_apple
	it's my first plugin OK! :(
	I wonder if this will be of any use.
*/
#pragma semicolon 1
#include <sourcemod>
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
	version = "1.1",
	url = "http://steamcommunity.com/groups/nokidshere"
};
	//morecolors.inc needs this for backwars compatibility
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) { 
   		MarkNativeAsOptional("GetUserMessageType"); 
   		return APLRes_Success; 
	}
public OnPluginStart(){
	//Hooks
	HookEvent("teamplay_game_over", Event_gameOver);	//Event for when game ends.
	HookEvent("tf_game_over", Event_gameOver);			//Event for when game ends.

	//Allow people with sm_rcon access to use this plugin, makes sense.
		//Commands
		RegAdminCmd("lock", passwordLock, ADMFLAG_RCON);
		RegAdminCmd("unlock", passwordUnlock,ADMFLAG_RCON);
		RegAdminCmd("autolock", autoLock,ADMFLAG_RCON);
		RegAdminCmd("changemap",mapChange,ADMFLAG_RCON);
		RegAdminCmd("callspec",callSpec,ADMFLAG_RCON);
		RegConsoleCmd("mumble",mumble);
		RegConsoleCmd("pass", pass);
		RegConsoleCmd("getpass",pass);
		RegConsoleCmd("getstring",getString);
		RegConsoleCmd("listmaps",listMaps);
	//let em know.
	PrintToServer("nKH! Pug Manager 1.0 loaded.");
}
//A small thank you message.
new bool:thankYouInProgress = false;
public Action:Event_gameOver(Handle:event, String:name[], bool:dontBroadcast){
	if(thankYouInProgress == false){
		thankYouInProgress = true;
		new Float:thankYouDelay = 2.0;
		CreateTimer(thankYouDelay,thankYouDisplay);

	}

}
public Action:thankYouDisplay(Handle:timer){
	CPrintToChatAll("{strange}[nKH!]{white} Thank you for playing on nKH!");
	CPrintToChatAll("{strange}[nKH!]{white} http://steamcommunity.com/groups/NoKidsHerePugsandLobbies");
	thankYouInProgress = false;
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
		CPrintToChatAll("{strange}[nKH!]{white} Password has been changed to: {lightskyblue}%s",passwordLockGenerated);
 
	}
	else{
		//desired password, hopefully people won't use a password with >32 characters.
		new String:passwordLockDesired[32];
		GetCmdArg(1,passwordLockDesired,sizeof(passwordLockDesired));
	
		//Change password
		ServerCommand("sv_password %s",passwordLockDesired);
		CPrintToChatAll("{strange}[nKH!]{white} Password has been changed to: {lightskyblue}%s",passwordLockDesired);
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
new bool:printInProgress = false;
//Function to check whether to lock
public DoAutoLock(){
	if(CurrentPlayers >= AutoLockLimit && AutoLockBool == true){
		ServerCommand("lock");
		CPrintToChatAll("{strange}[nKH!]{white} Player limit reached, server locked.");
		AutoLockBool = false;
	}
	if(CurrentPlayers < AutoLockLimit && AutoLockBool == true){
		PlayerDifference = AutoLockLimit - CurrentPlayers;
		if(printInProgress == false){
			CreateTimer(3.0,playersLeft);
			printInProgress = true;
		}

	}
}
public Action:playersLeft(Handle:timer){
	if(PlayerDifference == 1){
		CPrintToChatAll("{strange}[nKH!]{white} {lightskyblue}%i {white}%s short.",PlayerDifference,"player");
	}
	if(PlayerDifference > 1){
		CPrintToChatAll("{strange}[nKH!]{white} {lightskyblue}%i {white}%s short.",PlayerDifference,"players");
	}
	printInProgress = false;
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
		CPrintToChat(client,"{strange}[nKH!]{white} Server will automatically lock when {lightskyblue}%i{white} players have connected.",AutoLockLimitDesired);
		AutoLockLimit = AutoLockLimitDesired;
		AutoLockBool = true;
	}
	//If the parameters make no sense.
	if(AutoLockLimitDesired < 0 || AutoLockLimitDesired > 99){
		CPrintToChat(client,"{strange}[nKH!]{white} Incorrent parameters!");
	}
	//For disabling autolock.
	if(AutoLockLimitDesired == 0){
		CPrintToChatAll("{strange}[nKH!]{white} Autolock has been disabled.");
		AutoLockBool = false;
	}
	DoAutoLock();
	return Plugin_Handled;
}
//Whenever a client connets.
public OnClientConnected(client){
	if(!IsClientSourceTV(client)){
		CurrentPlayers = CurrentPlayers + 1; //validate
		DoAutoLock();
	}

}
//Whenever a client disconnects.
public OnClientDisconnect(client){
	CurrentPlayers = CurrentPlayers - 1; //validate
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
		CPrintToChat(client,"{strange}[nKH!]{white} Current password is: {lightskyblue}%s",CurrentPassword);
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
		CPrintToChat(client,"{lightskyblue}connect %s:%s; password %s //%s", ip,hostport,CurrentPassword,hostname);
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
		CPrintToChatAll("{strange}[nKH!]{white} Changing map to {lightskyblue}%s{white} in 5 seconds.",MapName);
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
	ServerCommand("sm_csay SPEC; say SPEC");
}
/*
							Maps.     
*/
public Action:listMaps(client,args){
	new String:listMapsArg[16];
	GetCmdArg(1,listMapsArg,sizeof(listMapsArg));
	CPrintToChat(client,"{strange}[nKH!]{white} Check console for output.");
	FakeClientCommandEx(client,"sm_rcon maps %s",listMapsArg);
}
/*
							Dump Mumble Details
*/
public Action:mumble(client,args){
	new String:mumbleArg[4];
	GetCmdArg(1,mumbleArg,sizeof(mumbleArg));
	if(strcmp(mumbleArg,"all",false) == 0){
		CPrintToChatAll("{strange}[nKH!]{white} nKH! Mumble is: {lightskyblue}119.252.190.75 {white}| {lightskyblue}64888");
		CPrintToChatAll("{strange}[nKH!]{white} {lightskyblue}119.252.190.75{white} - Address");
		CPrintToChatAll("{strange}[nKH!]{white} {lightskyblue}64888{white} - Port");
	}else{
		CPrintToChat(client,"{strange}[nKH!]{white} nKH! Mumble is: {lightskyblue}119.252.190.75 {white}| {lightskyblue}64888");
		CPrintToChat(client,"{strange}[nKH!]{white} {lightskyblue}119.252.190.75{white} - Address");
		CPrintToChat(client,"{strange}[nKH!]{white} {lightskyblue}64888{white} - Port");
	}

}


