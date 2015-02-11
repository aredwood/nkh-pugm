/*
	nKH! pug manager.
	by da_apple
*/
//Requirements
#pragma semicolon 1
#include <sourcemod>
#include <morecolors>
#include <tf2>

//Definitions
#define tagColor "{strange}"
#define textColor "{white}"
#define textHighLight "{community}"
//CVAR Handles
	//What will happen when autolock ticks.
		new Handle:pugm_autolockaction = INVALID_HANDLE;
	//Defined default max player limit.
		new Handle:pugm_definedMaxPlayers = INVALID_HANDLE;

//On Plugin Start
public OnPluginStart(){
	//Cvars
		pugm_autolockaction = CreateConVar("pugm_autolockaction","lock","Action to take when autolock ticks. (lock or print)");

		pugm_definedMaxPlayers = CreateConVar("pugm_definedmaxplayers","18","Used to determine the max value, while validing autolock input.");

	//Event hooks

	//Command Listeners

	//Admin Commands
		RegAdminCmd("autolock",autolock,ADMFLAG_RCON);
		RegAdminCmd("lock",lock,ADMFLAG_RCON);
	//Public Commands	
}
//On Map Start
public OnMapStart(){

}

/*
	Player Counter
*/
	new currentPlayers;
	//When a client connects.
		public OnClientConnected(client){
			//If client is SourceTV
			if(!IsClientSourceTV(client)){
				currentPlayers = currentPlayers + 1;
			}
		}
	//When a client disconnects.
		public OnClientConnected(client){
			//If client is SourceTV
			if(!IsClientSourceTV(client)){
				currentPlayers = currentPlayers - 1;
			}
		}
/*
	Lock
*/
	public Action:lock(client,args){
		//User didn't supply a password.
		if(GetCmdArgs() == 0){
			//Sting to store new password.
			new String:generatedPassword[5];
			for(new tmp = 0; tmp < sizeof(generatedPassword) - 2;tmp++){
				//Generate a random number.
				new randInt = GetRandomInt(0,9);
				//Fill the string with the random ints.
				generatedPassword[tmp] = randInt;
			}
			//Change the password.
			ServerCommand("sv_passwoes %s",generatedPassword);
			CPrintToChatAll("%s[nKH!]%s Password has been changed to:%s %s",tagColor,textColor,textHighLight,generatedPassword);
		}
		if(GetCmdArgs() == 1){
			//String to store user defined password.
			new String:givenPassword[32];
			GetCmdArg(1,givenPassword,sizeof(givenPassword));

			//Change the password.
			ServerCommand("sv_password %s",givenPassword);
			CPrintToChatAll("%s[nKH!]%s Password has been changed to:%s %s",tagColor,textColor,textHighLight,givenPassword);
		}
	}
/*	
	Autolock
*/
	//Variables relating to autolock.
	new bool:autoLockActive = false; 
	new bool:autoLockPlayerLimit;
	public Acion:autolock(client,args){
		//Client presented no argruments.
		if(GetCmdArgs() == 0){
			CReplyToCommand(client,"%s[nKH!]%s No parameters specified.",tagColor,textColor);
		}
		//Client presented a single argrument.
		if(GetCmdArgs() == 1){
			//Get string and turn it into an integer.
			new String:autoLockPlayerLimitDesiredString[3];
			GetCmdArg(1,autoLockPlayerLimitDesiredString,sizeof(autoLockPlayerLimitDesiredString));
			new autoLockPlayerLimitDeired = StringToInt(autoLockPlayerLimitDesiredString);

			//If the given limit matches criteria.
			if(autoLockPlayerLimitDesired > 0 && autoLockPlayerLimitDesired < GetConVarInt(pugm_definedMaxPlayers)){
				//Given limit matched criteria.
				autoLockPlayerLimit = autoLockPlayerLimitDesired;
				autoLockActive = true;
			}
			else{
				CReplyToCommand("%s[nKH!]%s Invalid player limit given.");
			}

		}
		//Client presented three agruments.
		if(CmdArgs == 2){

		}
		return Plugin_Handled;
	}
	performAutoLockCheck(){
		if(autoLockActive){
			if(currentPlayers >= autoLockPlayerLimit){
				CPrintToChatAll("%s[nKH!]%s");
			}
		}
	}
