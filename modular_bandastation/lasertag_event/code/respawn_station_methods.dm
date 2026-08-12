
/// Respawn the player's kit
/obj/machinery/lasertag/respawn_station/proc/respawn_kit(mob/living/user, datum/component/lasertag_kit/kit)
	// Enable kit
	kit.enable_kit()
	
	// Decrement uses
	if(uses_remaining > 0)
		uses_remaining--
		update_appearance()
	
	// Set cooldown
	player_cooldowns[user.ckey] = world.time + cooldown_time
	
	// Visual feedback
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	do_sparks(3, FALSE, src)
	
	to_chat(user, span_notice("Your kit has been restored!"))

/// Set uses
/obj/machinery/lasertag/respawn_station/proc/set_uses(new_uses)
	uses_remaining = new_uses
	max_uses = new_uses
	update_appearance()

/// Reset uses to max
/obj/machinery/lasertag/respawn_station/proc/reset_uses()
	uses_remaining = max_uses
	update_appearance()

/obj/machinery/lasertag/respawn_station/update_overlays()
	. = ..()
	
	// Add team color glow
	if(team_color)
		var/mutable_appearance/glow = mutable_appearance(icon, "[icon_state]_glow")
		switch(team_color)
			if("red")
				glow.color = "#FF0000"
			if("blue")
				glow.color = "#0000FF"
		glow.layer = ABOVE_LIGHTING_LAYER
		. += glow
	
	// Add uses counter hologram (if finite)
	if(uses_remaining >= 0)
		var/mutable_appearance/counter = mutable_appearance(icon, "counter")
		counter.maptext = MAPTEXT("<span style='font-size: 14px; color: #00FF00;'>[uses_remaining]</span>")
		counter.maptext_x = 8
		counter.maptext_y = 20
		counter.layer = ABOVE_LIGHTING_LAYER
		. += counter

// Red team variant
/obj/machinery/lasertag/respawn_station/red
	team_color = "red"
	icon_state = "respawn_station_red"

// Blue team variant
/obj/machinery/lasertag/respawn_station/blue
	team_color = "blue"
	icon_state = "respawn_station_blue"
