
/// Give leaderboard action buttons to all players
/datum/lasertag_controller/proc/give_leaderboard_actions()
	// TODO: Implement leaderboard actions
	return

/// Award points for a hit
/datum/lasertag_controller/proc/award_hit_points(ckey, is_headshot = FALSE)
	var/datum/component/lasertag_kit/kit = all_players[ckey]
	if(!kit)
		return
	
	var/points = is_headshot ? LASERTAG_SCORE_HEADSHOT : LASERTAG_SCORE_BODYSHOT
	
	// Control Point mode reduces kill points
	if(game_mode == LASERTAG_MODE_CONTROL_POINT)
		points = points / 10
	
	kit.add_score(points)
	
	// Add to team score if applicable
	var/team_color = kit.team_color
	if(team_color && teams[team_color])
		teams[team_color].add_score(points)

/// Award death penalty
/datum/lasertag_controller/proc/award_death_penalty(ckey)
	var/datum/component/lasertag_kit/kit = all_players[ckey]
	if(!kit)
		return
	
	kit.add_score(LASERTAG_SCORE_DEATH)
	
	// Add to team score if applicable
	var/team_color = kit.team_color
	if(team_color && teams[team_color])
		teams[team_color].add_score(LASERTAG_SCORE_DEATH)

/// Check if player is in safe zone (near respawn station)
/datum/lasertag_controller/proc/is_in_safe_zone(mob/living/target)
	for(var/obj/machinery/lasertag/respawn_station/station in respawn_stations)
		if(get_dist(target, station) <= LASERTAG_RESPAWN_SAFE_RADIUS)
			return TRUE
	return FALSE
