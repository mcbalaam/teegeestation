
/// Reset team (clear scores, keep members)
/datum/lasertag_team/proc/reset()
	score = 0
	
	// Reset all member kits
	for(var/ckey in members)
		var/datum/component/lasertag_kit/kit = members[ckey]
		if(kit)
			kit.reset_kit()

/// Check if team can accept new members (balancing)
/datum/lasertag_team/proc/can_join(datum/lasertag_controller/game_controller)
	// Check if other teams have fewer members
	for(var/other_color in game_controller.teams)
		if(other_color == team_color)
			continue
		
		var/datum/lasertag_team/other_team = game_controller.teams[other_color]
		if(get_size() > other_team.get_size())
			return FALSE
	
	return TRUE
