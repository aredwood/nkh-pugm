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
#include <tf2>
/*
	TODO LIST:

	Optimize,
	Add more comments,
*/

/*
										CVARS
*/

new Handle:g_defaultpassword = INVALID_HANDLE;
new Handle:g_thankyoudelay = INVALID_HANDLE;
new Handle:g_passaccessdefault = INVALID_HANDLE;
new Handle:g_speccalltimemin = INVALID_HANDLE;
new Handle:g_speccalltimemax = INVALID_HANDLE;
new Handle:g_changemapwaittime = INVALID_HANDLE;
new Handle:g_lockatplayerlimit = INVALID_HANDLE;
new Handle:g_rip = INVALID_HANDLE;
new Handle:g_meddrop = INVALID_HANDLE;
new Handle:g_autolockdefaulton = INVALID_HANDLE;
new Handle:g_autolockdefaultvalue = INVALID_HANDLE;

public OnPluginStart(){
	//Hooks
	HookEvent("teamplay_game_over", Event_gameOver);	//Event for when game ends.
	HookEvent("tf_game_over", Event_gameOver);			//Event for when game ends.
	HookEvent("player_death",Event_playerDeath); //When a player dies
	HookEvent("medic_death",Event_medicDeath);
	
	//Command listners
	AddCommandListener(joinTeamCmd, "jointeam");
	AddCommandListener(joinTeamCmd,"spectate");
	//Admin Commands
	RegAdminCmd("lock", passwordLock, ADMFLAG_RCON);
	RegAdminCmd("unlock", passwordUnlock,ADMFLAG_RCON);
	RegAdminCmd("autolock", autoLock,ADMFLAG_RCON);
	RegAdminCmd("changemap",mapChange,ADMFLAG_RCON);
	RegAdminCmd("callspec",callSpec,ADMFLAG_RCON);
	RegAdminCmd("thisisapug",thisisapug,ADMFLAG_RCON);
	RegAdminCmd("thisisalobby",thisisalobby,ADMFLAG_RCON);
	//Public Commands
	RegConsoleCmd("mumble",mumble);
	RegConsoleCmd("pass", pass);
	RegConsoleCmd("getpass",pass);
	RegConsoleCmd("getstring",getString);
	RegConsoleCmd("listmaps",listMaps);

	//CVARS
	//Default password for !unlock.
	g_defaultpassword = CreateConVar("pugm_defaultpassword","Medic!","Default password for !unlock");
	//A value of atleast 3.0 is best.
	g_thankyoudelay = CreateConVar("pugm_thankyoudelay","3.0","Ammount to delay the thank you message after the game ends.");
	//Should almost always be true.
	g_passaccessdefault = CreateConVar("pugm_passaccessdefault","1","Enable commands such as: !pass, !getpass, and !getstring by default.");
	//Minimum value to wait before calling spec.
	g_speccalltimemin = CreateConVar("pugm_speccalltimemin","5.0","Minimum ammount of time to wait before calling spec.");
	//Maximum value to wait before calling spec.
	g_speccalltimemax = CreateConVar("pugm_speccalltimemax","7.0","Maximum ammount of time to wait before calling spec.");
	//TIme to wait before changing map.
	g_changemapwaittime = CreateConVar("pugm_changemapwaittime","5.0","Time to wait after !changemap before changing the map.");
	//Either lock the server or print a message when the server has reached it's player limit.
	g_lockatplayerlimit = CreateConVar("pugm_lockatplayerlimit","0","Whether to lock at playerlimit or to just say it's full.");
	//rip
	g_rip = CreateConVar("pugm_rip","0","rip");
	//Med drop
	g_meddrop = CreateConVar("pugm_meddrop","0","DROPPED");
	//Autolock enabled by default.
	g_autolockdefaulton = CreateConVar("pugm_autolockdefaulton","1","Autolock enabled by default.");
	//Autolock's default value.
	g_autolockdefaultvalue = CreateConVar("pugm_autolockdefaultvalue","18","Autolock's default value");

	AutoExecConfig(true,"pugm");
	ServerCommand("exec pugm");
	//Don't think precaching is necessary. 
	PrecacheSound("misc/sniper_railgun_double_kill.wav",true);
}
/*
							Execute autolock on map start, if enabled.
*/
public OnMapStart(){
	//If pugm_autolockdefaulton == 1
	if(GetConVarInt(g_autolockdefaulton) == 1){
		//Set autolock to lock at pugm_autolockdefaultvalue.
		ServerCommand("autolock %i",GetConVarInt(g_autolockdefaultvalue));
	}
}

//morecolors.inc needs this for backwars compatibility
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) { 
	MarkNativeAsOptional("GetUserMessageType"); 
	return APLRes_Success; 
}

/*
							Function that manages the "thankyou" message, at the end of every game
*/
//Used to prevent the message triggering twice.
new bool:thankYouInProgress = false;
public Action:Event_gameOver(Handle:event, String:name[], bool:dontBroadcast){
	if(thankYouInProgress == false){
		thankYouInProgress = true;
		CreateTimer(GetConVarFloat(g_thankyoudelay),thankYouDisplay);
	}
	return Plugin_Handled;
}
public Action:thankYouDisplay(Handle:timer){
	CPrintToChatAll("{strange}[nKH!]{white} Thank you for playing on nKH!");
	//Group link is far to long to fit within 1 line of in game chat. 
	CPrintToChatAll("{strange}[nKH!]{white} http://steamcommunity.com/groups/NoKidsHerePugsandLobbies");
	thankYouInProgress = false;
	return Plugin_Handled;
}

/*                                                      
							Function that manages password locking.
*/
public Action:passwordLock(client,args){
	//If user didn't supplied a password.
	if(GetCmdArgs() < 1){
		//generate new pass
		//This whole process could be shortened by using the int generated by RandonInt in the password, instead of pulling a value out of an array.
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
	return Plugin_Handled;
}

/*
							Function that manages unlocking.	
*/
public Action:passwordUnlock(client,args){
	new String:defaultPassword[32];
	GetConVarString(g_defaultpassword,defaultPassword,sizeof(defaultPassword));
	ServerCommand("lock %s",defaultPassword);
	return Plugin_Handled;
}

/*
							When a player dies
*/
public Action:Event_playerDeath(Handle:event,const String:name[],bool:Broadcast){
	if(GetConVarInt(g_rip) == 1){
		new deadeeId = GetEventInt(event,"userid");
		new deadee = GetClientOfUserId(deadeeId);
		CPrintToChat(deadee,"{strange}[nKH!]{white} rip");
	}
	return Plugin_Handled;
}

/*                                              
							Function that manages autolocking (actually the most useful feature of this plugin.)
*/
//Why isn't there a tag for integers?
new CurrentPlayers;
new AutoLockLimit; //This varible was actually a float at some stage.
new PlayerDifference;
new bool:AutoLockBool = false;
new bool:printInProgress = false;
new bool:lockatplayerlimit = false;

//Function to check whether to lock
public DoAutoLock(){
	if(GetConVarInt(g_lockatplayerlimit) == 1){
		lockatplayerlimit = true;
	}
	if(GetConVarInt(g_lockatplayerlimit) == 0){
		lockatplayerlimit = false;
	}
	if(CurrentPlayers >= AutoLockLimit && AutoLockBool == true){
		if(lockatplayerlimit == true){
			ServerCommand("lock");
			CPrintToChatAll("{strange}[nKH!]{white} Player limit reached, server locked.");
			AutoLockBool = false;
		}
		if(lockatplayerlimit == false){
			CPrintToChatAll("{strange}[nKH!]{white} Players required reached, let's play!");
			AutoLockBool = false;
		}
	}
	if(CurrentPlayers < AutoLockLimit && AutoLockBool == true){

		if(printInProgress == false){
			CreateTimer(3.0,playersLeft);
			printInProgress = true;
		}
	}
	return Plugin_Handled;
}
public Action:playersLeft(Handle:timer){
	PlayerDifference = AutoLockLimit - CurrentPlayers;
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
		//CPrintToChat(client,"{strange}[nKH!]{white} Server will automatically lock when {lightskyblue}%i{white} players have connected.",AutoLockLimitDesired);
		CReplyToCommand(client,"{strange}[nKH!]{white} Server will automatically lock when {lightskyblue}%i{white} players have connected.",AutoLockLimitDesired);
		AutoLockLimit = AutoLockLimitDesired;
		AutoLockBool = true;
	}
	//If the parameters make no sense.
	if(AutoLockLimitDesired < 0 || AutoLockLimitDesired > 99){
		//CPrintToChat(client,"{strange}[nKH!]{white} Incorrent parameters!");
		CReplyToCommand(client,"{strange}[nKH!]{white} Incorrent parameters!");
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
	if(!IsClientSourceTV(client)){
		CurrentPlayers = CurrentPlayers - 1;
		DoAutoLock();
	}
}

/*
							Medic Death
*/
public Action:Event_medicDeath(Handle:event,const String:name[],bool:Broadcast){
	//If pugm_meddrop == 1, and a med (with some charge) dies.
	if(GetConVarInt(g_meddrop) == 1 && GetEventBool(event,"charged") == true){
		//get user id of ded med.
		new medID = GetEventInt(event,"userid");
		//create string to store the med name.
		new String:medName[33];
		new medIndex = GetClientOfUserId(medID);

		GetClientName(medIndex,medName,sizeof(medName));
		//[nKH!] drop queen dropped.
		CPrintToChatAll("{strange}[nKH!] {lightskyblue}%s {white}dropped!",medName);
		for(new tmp = 1; tmp <= CurrentPlayers; tmp++){
			ClientCommand(tmp,"playgamesound player/medic_charged_death.wav; playgamesound misc/sniper_railgun_double_kill.wav; playgamesound player/medic_charged_death.wav");
		}
	}
	return Plugin_Handled;
}
/*
							Executes pugm config
*/
public Action:thisisapug(client,args){
	ServerCommand("exec pug");
	CPrintToChatAll("{strange}[nKH!]{white} pugm config executed.");
	return Plugin_Handled;
}
/*
							Executes TF2C config
*/
public Action:thisisalobby(client,args){
	ServerCommand("exec TF2Center");
	CPrintToChatAll("{strange}[nKH!]{white} TF2Center config executed.");
	return Plugin_Handled;
}
/*                                                                                                                 
							Function to manage !getpass and !pass.
*/

new bool:GetPass;
public Action:pass(client,args){
	if(GetConVarInt(g_passaccessdefault) == 1){
		GetPass = true;
	}
	if(GetConVarInt(g_passaccessdefault) == 0){
		GetPass = false;
	}
	if(GetCmdArgs() < 1 && GetPass == true){
		//Get's password.
		new Handle:CurrentPasswordHandler = FindConVar("sv_password");
		decl String:CurrentPassword[64];
		GetConVarString(CurrentPasswordHandler,CurrentPassword,sizeof(CurrentPassword));
		//CPrint password to client.
		//CPrintToChat(client,"{strange}[nKH!]{white} Current password is: {lightskyblue}%s",CurrentPassword);
		CReplyToCommand(client,"{strange}[nKH!]{white} Current password is: {lightskyblue}%s",CurrentPassword);

	}
	//If someone requests the password, but it has been disabled by an admin.
	if(GetCmdArgs() < 1 && GetPass == false){
		//CPrintToChat(client,"{strange}[nKH!]{white} !pass has been disabled by the administrator.");
		CReplyToCommand(client,"{strange}[nKH!]{white} !pass has been disabled by the administrator.");
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
	return Plugin_Handled;
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
		//CPrintToChat(client,"{strange}[nKH!]{white} Connect string has also been given in console.");
		//CPrintToChat(client,"{lightskyblue}connect %s:%s; password %s //%s", ip,hostport,CurrentPassword,hostname);
		CReplyToCommand(client,"{strange}[nKH!]{white} Connect string has also been given in console.");
		CReplyToCommand(client,"{lightskyblue}connect %s:%s; password %s //%s", ip,hostport,CurrentPassword,hostname);
		PrintToConsole(client,"connect %s:%s; password %s //%s",ip,hostport,CurrentPassword,hostname);
	}
	//Client requested the string, but GetPass was set to false.
	if(GetCmdArgs() < 1 && GetPass == false){
		//CPrintToChat(client,"{strange}[nKH!]{white} !getstring has been disabled by an administrator.");
		CReplyToCommand(client,"{strange}[nKH!]{white} !getstring has been disabled by an administrator.");
	}
	return Plugin_Handled;
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
		//CPrintToChat(client,"{strange}[nKH!]{white} Incorrect usage!");
		CReplyToCommand(client,"{strange}[nKH!]{white} Incorrect usage!");
	}

	if(SplitString(MapInput,".bsp",MapName,sizeof(MapName)) == -1){
		//Actually forgot what this all means.
		strcopy(MapName,sizeof(MapName),MapInput);
	}
	if(IsMapValid(MapName)){
		new Float:waitTime = GetConVarFloat(g_changemapwaittime);
		CPrintToChatAll("{strange}[nKH!]{white} Changing map to {lightskyblue}%s{white} in %f seconds.",MapName,waitTime);
		//Whole purpose of the timer is to alert players of the map change.

		CreateTimer(waitTime,MapTimer);
	}else{
		//When a map that isn't installed is given, or something like !changemap SWAGBOIZE happens.
		//CPrintToChat(client,"{strange}[nKH!]{white} Map not found, likely spelt incorrectly or not installed.");
		CReplyToCommand(client,"{strange}[nKH!]{white} Map not found, likely spelt incorrectly or not installed.");
	}
	return Plugin_Handled;
}
public Action:MapTimer(Handle:timer){
	//Change the map.
	ServerCommand("changelevel %s",MapName);
}
/*
							Function to manage spec calling.
*/
new bool:specCallInProgress = false;
public Action:callSpec(client,args){
	specCallInProgress = true;
	new Float:specMinTime = GetConVarFloat(g_speccalltimemin);
	new Float:specMaxTime = GetConVarFloat(g_speccalltimemax);
	new Float:specTime = GetRandomFloat(specMinTime,specMaxTime); 
	CreateTimer(specTime,specCall);
	//GIves out the warning.
	CPrintToChatAll("{strange}[nKH!]{white} WARNING, SPEC CALL IMMINENT!");
	ServerCommand("sm_csay WARNING");
	return Plugin_Handled;
}
public Action:joinTeamCmd(client, const String:command[], argc){

	decl String:argWhole[11];
	decl String:argOne[11];
	GetCmdArg(0,argWhole,sizeof(argWhole));
	GetCmdArg(1,argOne,sizeof(argOne));
	if(strcmp(argOne,"spectate",false) == 0 || strcmp(argWhole,"spectate",false) == 0){
		if(specCallInProgress){
			CPrintToChat(client,"{strange}[nKH!]{white} Spec hasn't been called yet.");
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
//Call Spec.
public Action:specCall(Handle:timer){
	specCallInProgress = false;
	ServerCommand("sm_csay SPEC; say SPEC");
}
/*
							Maps.     
*/
public Action:listMaps(client,args){
	new String:listMapsArg[16];
	GetCmdArg(1,listMapsArg,sizeof(listMapsArg));
	//CPrintToChat(client,"{strange}[nKH!]{white} Check console for output.");
	CReplyToCommand(client,"{strange}[nKH!]{white} Check console for output.");
	FakeClientCommandEx(client,"sm_rcon maps %s",listMapsArg);
	return Plugin_Handled;
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
		return Plugin_Handled;
	}
	CReplyToCommand(client,"{strange}[nKH!]{white} nKH! Mumble is: {lightskyblue}119.252.190.75 {white}| {lightskyblue}64888");
	CReplyToCommand(client,"{strange}[nKH!]{white} {lightskyblue}119.252.190.75{white} - Address");
	CReplyToCommand(client,"{strange}[nKH!]{white} {lightskyblue}64888{white} - Port");
	return Plugin_Handled;
}

public Plugin:myinfo = {
	name = "nKH! Pug Manager",
	author = "da_apple",
	description = "Simplifys Pug management",
	version = "1.2",
	url = "http://steamcommunity.com/groups/nokidshere"
};