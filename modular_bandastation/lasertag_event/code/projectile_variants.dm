
// Red team projectile variant
/obj/projectile/beam/lasertag/event/red
	name = "red lasertag beam"
	color = "#FF0000"

// Blue team projectile variant
/obj/projectile/beam/lasertag/event/blue
	name = "blue lasertag beam"
	color = "#0000FF"

/// Ammo casing for lasertag weapons
/obj/item/ammo_casing/energy/lasertag_event
	name = "lasertag beam"
	projectile_type = /obj/projectile/beam/lasertag/event
	e_cost = 100 // 1 charge per shot (out of maxcharge)
	select_name = "lasertag"

/// Visual hit effect
/obj/effect/temp_visual/lasertag_hit
	icon = 'icons/effects/effects.dmi'
	icon_state = "lasertag_hit"
	duration = 0.3 SECONDS
	randomdir = TRUE
