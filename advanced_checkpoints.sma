// Thanks http://cs-mapping.com.ua/forum 
// Thanks Andrew from this forum

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

enum
{
	CP,
	GC
}

new const
	PLUGIN_NAME    [] = "Checkpoints & Teleport",
	PLUGIN_VERSION    [] = "1.0",
	PLUGIN_AUTHOR    [] = "Keys"

new bool:g_bHasCheckpoint[33];

new Float:g_bCheckpointOrigin[33][3];
new Float:g_bCheckpointAngle[33][3];
new Float:g_bCheckpointGravity[33][3];
new Float:g_bCheckpointVelocity[33][3];

new g_iDemNo[33][2];

new const Float:VEC_DUCK_HULL_MIN[3] = {-16.0, -16.0, -18.0}
new const Float:VEC_DUCK_HULL_MAX[3] = {16.0, 16.0, 32.0}
new const Float:VEC_DUCK_VIEW[3] = {0.0, 0.0, 12.0}
new const Float:VEC_NULL[3] = {0.0, 0.0, 0.0}

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	register_clcmd("say /teleport", "gocheckpoint");
	register_clcmd("say /checkpoints", "checkpoint_menu");
	register_clcmd("say /sm","checkpoint_menu");
}
public client_connect(id) {
	g_bHasCheckpoint[id] = false;
}

public checkpoint_menu(id){

	new menu = menu_create("Checkpoint Menu", "menu_handler");

	menu_additem(menu, "Save Checkpoint", "", 0);
	menu_additem(menu, "Teleport", "", 0);
	menu_additem(menu, "Delete Checkpoint", "", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}
public menu_handler(id, menu, item){
    
	if(item == MENU_EXIT)
	{
		menu_cancel(id);
		return PLUGIN_HANDLED;
	}

	new command[6], name[64], access, callback;

	menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback);

	switch(item)
	{
		case 0:SaveCheckpoint(id)
		case 1:fwTeleport(id)
		case 2:RemoveCheckpoint(id)
	}
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}


public fwTeleport(id){
    
	if (!is_user_connected(id) || cs_get_user_team(id) == CS_TEAM_SPECTATOR)         return;
	ExecuteHamB(Ham_CS_RoundRespawn, id)

	if(g_bHasCheckpoint[id] == true) {
	LoadCheckpoint(id);
	}
}
public gocheckpoint(id){
    
	if(is_user_alive(id)){
		fwTeleport(id);
	}
	return PLUGIN_HANDLED;
}

public SaveCheckpoint(id){
    
	if ( !is_user_alive(id) ) 
	{
		client_print(id, print_chat, "You have to be alive to save the checkpoint.");
		return PLUGIN_HANDLED;
	}

	pev(id, pev_origin, g_bCheckpointOrigin[id])
	pev(id, pev_v_angle, g_bCheckpointAngle[id])
	pev(id, pev_gravity, g_bCheckpointGravity[id][2])
	pev(id, pev_velocity, g_bCheckpointVelocity[id])
	
	g_iDemNo[id][CP] ++

	client_print(id, print_chat, "Checkpoint saved!");

	if ( !g_bHasCheckpoint[id] )            g_bHasCheckpoint[id] = true;

	g_iDemNo[id][GC] ++
	
	client_cmd(id, "stop; record ^"CP%d-GC%d^"", g_iDemNo[id][CP], g_iDemNo[id][GC]);
	
	return PLUGIN_HANDLED;
}
public LoadCheckpoint(id) {
    
	if ( !is_user_alive(id) )
	{
		client_print(id, print_chat, "You have to be alive if you want to teleport.");
		return PLUGIN_HANDLED;
	}
	set_checkpoint(id, g_bCheckpointOrigin[id], g_bCheckpointAngle[id], g_bCheckpointVelocity[id])
	
	g_iDemNo[id][GC] ++
	
	client_cmd(id, "stop; record ^"CP%d-GC%d^"", g_iDemNo[id][CP], g_iDemNo[id][GC]);

	return PLUGIN_HANDLED;
}
public RemoveCheckpoint(id)
{
	g_bHasCheckpoint[id] = false;
	client_print(id, print_chat, "Checkpoint removed!")
}

set_checkpoint(id, Float:flOrigin[3], Float:flAngles[3], Float:flVelocity[3]) {
    
	new iFlags = pev(id, pev_flags)
	iFlags &= ~FL_BASEVELOCITY
	iFlags |= FL_DUCKING
	set_pev(id, pev_flags, iFlags)
	engfunc(EngFunc_SetSize, id, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX)
	engfunc(EngFunc_SetOrigin, id, flOrigin)
	set_pev(id, pev_view_ofs, VEC_DUCK_VIEW)

	set_pev(id, pev_v_angle, VEC_NULL)
	set_pev(id, pev_velocity, flVelocity)
	set_pev(id, pev_basevelocity, VEC_NULL)
	set_pev(id, pev_angles, flAngles)
	set_pev(id, pev_punchangle, VEC_NULL)
	set_pev(id, pev_fixangle, 1)

	set_pev(id, pev_gravity, flAngles[2])

	set_pev(id, pev_fuser2, 0.0)
}