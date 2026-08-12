/// The Lasertag Event Controller manages an individual lasertag game
/// Each game has its own controller handling game-wide functionality
/datum/lasertag_controller
	/// Unique ID for this game instance
	var/game_id = "lasertag_main"
	/// Whether this game is currently running
	var/game_active = FALSE
	/// Current game mode (LASERTAG_MODE_*)
	var/game_mode = LASERTAG_MODE_NONE
	/// Game timer in deciseconds
	var/game_timer = LASERTAG_DEFAULT_TIMER
	/// Time when game started (world.time)
	var/game_start_time = 0
	
	/// List of all teams (team_color -> /datum/lasertag_team)
	var/list/datum/lasertag_team/teams = list()
	/// List of all active players (ckey -> /datum/component/lasertag_kit)
	var/list/all_players = list()
	
	/// List of control points (for CP mode)
	var/list/obj/machinery/lasertag/control_point/control_points = list()
	/// List of respawn stations
	var/list/obj/machinery/lasertag/respawn_station/respawn_stations = list()
	/// Attack mode beacon (for Attack mode)
	var/obj/machinery/lasertag/beacon/attack_beacon
	
	/// Number of respawn uses (-1 = infinite)
	var/respawn_uses = LASERTAG_DEFAULT_RESPAWNS
	/// HUD enabled (affects Shadow Realm mode)
	var/hud_enabled = TRUE
	/// Friendly fire enabled
	var/friendly_fire = FALSE

/datum/lasertag_controller/New(game_id)
	. = ..()
	src.game_id = game_id
	if(!GLOB.lasertag_games)
		GLOB.lasertag_games = list()
	GLOB.lasertag_games[game_id] = src

/datum/lasertag_controller/Destroy(force)
	GLOB.lasertag_games[game_id] = null
	return ..()

/// Start the game
/datum/lasertag_controller/proc/start_game(mode = LASERTAG_MODE_TEAM_DEATHMATCH)
	if(game_active)
		return FALSE
	
	game_active = TRUE
	game_mode = mode
	game_start_time = world.time
	
	// Mode-specific initialization
	switch(mode)
		if(LASERTAG_MODE_FREE_FOR_ALL)
			friendly_fire = TRUE
			hud_enabled = FALSE
		if(LASERTAG_MODE_SHADOW_REALM)
			hud_enabled = FALSE
			randomize_player_positions()
	
	// Announce game start
	message_all_players(span_boldannounce("Lasertag game started! Mode: [get_mode_name(mode)]"))
	
	// Start game timer if applicable
	if(game_timer > 0)
		addtimer(CALLBACK(src, PROC_REF(end_game_timer)), game_timer)
	
	return TRUE