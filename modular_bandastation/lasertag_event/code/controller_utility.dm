
/// Remove player from game
/datum/lasertag_controller/proc/remove_player(ckey)
	var/datum/component/lasertag_kit/kit = all_players[ckey]
	if(!kit)
		return
	
	// Remove from team
	for(var/team_color in teams)
		teams[team_color].remove_member(ckey)
	
	all_players -= ckey

/// Get winning team based on current scores
/datum/lasertag_controller/proc/get_winning_team()
	var/highest_score = 0
	var/winning_team = null
	
	for(var/team_color in teams)
		var/datum/lasertag_team/team = teams[team_color]
		if(team.score > highest_score)
			highest_score = team.score
			winning_team = team_color
	
	return winning_team

/// Message all players
/datum/lasertag_controller/proc/message_all_players(message)
	for(var/ckey in all_players)
		var/datum/component/lasertag_kit/kit = all_players[ckey]
		if(kit && kit.parent)
			var/mob/living/owner = kit.parent
			to_chat(owner, message)

/// Get mode name string
/datum/lasertag_controller/proc/get_mode_name(mode)
	switch(mode)
		if(LASERTAG_MODE_TEAM_DEATHMATCH)
			return "Team Deathmatch"
		if(LASERTAG_MODE_CONTROL_POINT)
			return "Control Point"
		if(LASERTAG_MODE_ATTACK)
			return "Attack/Defense"
		if(LASERTAG_MODE_FREE_FOR_ALL)
			return "Free For All"
		if(LASERTAG_MODE_SHADOW_REALM)
			return "Shadow Realm"
	return "Unknown"

/// Randomize player positions (Shadow Realm mode)
/datum/lasertag_controller/proc/randomize_player_positions()
	// TODO: Implement position randomization
	return

/// Show return arrows to base
/datum/lasertag_controller/proc/show_return_arrows()
	// TODO: Implement return arrows
	return
