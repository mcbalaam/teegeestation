/// Lasertag Respawn Station
/// Fixed station that restores kit HP and ammo
/obj/machinery/lasertag/respawn_station
	name = "lasertag respawn station"
	desc = "A station that restores your lasertag kit. Click it to respawn."
	icon = 'icons/obj/machines/computer.dmi' // Placeholder icon
	icon_state = "computer"
	anchored = TRUE
	density = TRUE
	
	/// Team this station belongs to
	var/team_color
	/// Reference to controller
	var/datum/lasertag_controller/controller
	/// Remaining uses (-1 = infinite)
	var/uses_remaining = -1
	/// Max uses
	var/max_uses = -1
	/// Cooldown per player (to prevent spam)
	var/list/player_cooldowns = list()
	/// Cooldown duration
	var/cooldown_time = 1 SECONDS

/obj/machinery/lasertag/respawn_station/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/machinery/lasertag/respawn_station/Destroy()
	controller = null
	player_cooldowns.Cut()
	return ..()

/obj/machinery/lasertag/respawn_station/examine(mob/user)
	. = ..()
	
	if(uses_remaining < 0)
		. += span_notice("Uses remaining: Infinite")
	else
		. += span_notice("Uses remaining: [uses_remaining]")

/obj/machinery/lasertag/respawn_station/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	
	// Check if player has lasertag kit
	var/datum/component/lasertag_kit/kit = user.GetComponent(/datum/component/lasertag_kit)
	if(!kit)
		to_chat(user, span_warning("You don't have a lasertag kit!"))
		return
	
	// Check team
	if(team_color && kit.team_color != team_color)
		to_chat(user, span_warning("This station is for [team_color] team only!"))
		return
	
	// Check cooldown
	if(player_cooldowns[user.ckey] && world.time < player_cooldowns[user.ckey])
		var/time_left = round((player_cooldowns[user.ckey] - world.time) / 10, 0.1)
		to_chat(user, span_warning("Station is on cooldown! Wait [time_left] seconds."))
		return
	
	// Check uses
	if(uses_remaining == 0)
		to_chat(user, span_warning("[src] has no uses remaining!"))
		return
	
	// Respawn kit
	respawn_kit(user, kit)
