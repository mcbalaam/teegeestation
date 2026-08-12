
/// Stop the game
/datum/lasertag_controller/proc/stop_game()
	if(!game_active)
		return
	
	game_active = FALSE
	
	// Disable all kits
	for(var/ckey in all_players)
		var/datum/component/lasertag_kit/kit = all_players[ckey]
		if(kit)
			kit.disable_kit()
	
	// Show return arrows to base
	show_return_arrows()
	
	// Give action button to open leaderboard
	give_leaderboard_actions()
	
	message_all_players(span_boldannounce("Game ended! Check the leaderboard."))

/// Called when timer expires
/datum/lasertag_controller/proc/end_game_timer()
	if(!game_active)
		return
	
	// Determine winner based on mode
	var/winning_team = get_winning_team()
	if(winning_team)
		message_all_players(span_boldannounce("[winning_team] team wins!"))
	
	stop_game()

/// Add a team to the game
/datum/lasertag_controller/proc/add_team(team_color, obj/machinery/spawner)
	if(teams[team_color])
		return // Team already exists
	
	teams[team_color] = new /datum/lasertag_team(team_color, src)
	teams[team_color].lasertag_spawner = spawner

/// Remove a team
/datum/lasertag_controller/proc/remove_team(team_color)
	if(!teams[team_color])
		return
	
	QDEL_NULL(teams[team_color])
	teams -= team_color

/// Add player to a team
/datum/lasertag_controller/proc/add_player(ckey, team_color, datum/component/lasertag_kit/kit)
	all_players[ckey] = kit
	
	if(teams[team_color])
		teams[team_color].add_member(ckey, kit)
