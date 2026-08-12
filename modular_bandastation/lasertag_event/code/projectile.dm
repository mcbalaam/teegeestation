/// Lasertag Event Projectile
/// Checks bodypart hit and deals damage only to kit, not mob
/obj/projectile/beam/lasertag/event
	name = "lasertag beam"
	icon_state = "lasertag_beam"
	damage = 0 // No actual damage to mob
	damage_type = STAMINA // For visual effects
	flag = ENERGY
	hitsound = 'sound/weapons/tap.ogg'
	
	/// Who fired this beam
	var/mob/firer

/obj/projectile/beam/lasertag/event/Initialize(mapload)
	. = ..()
	// Set color based on team (handled by gun)
	
/obj/projectile/beam/lasertag/event/fire(setAngle)
	// Store firer reference
	if(firer_source_atom && ismob(firer_source_atom))
		firer = firer_source_atom
	return ..()

/obj/projectile/beam/lasertag/event/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	
	// Only affect living mobs
	if(!isliving(target))
		return BULLET_ACT_BLOCK
	
	var/mob/living/victim = target
	
	// Check if victim is in lasertag area
	var/area/target_area = get_area(victim)
	if(!istype(target_area, /area/lasertag_event))
		return BULLET_ACT_BLOCK
	
	// Check if victim has a kit
	var/datum/component/lasertag_kit/victim_kit = victim.GetComponent(/datum/component/lasertag_kit)
	if(!victim_kit)
		return BULLET_ACT_BLOCK
	
	// Check if kit is active
	if(!victim_kit.active)
		return BULLET_ACT_BLOCK
	
	// Check friendly fire
	if(firer && victim_kit.controller)
		var/datum/component/lasertag_kit/firer_kit = firer.GetComponent(/datum/component/lasertag_kit)
		if(firer_kit)
			// Same team check
			if(!victim_kit.controller.friendly_fire && firer_kit.team_color == victim_kit.team_color)
				return BULLET_ACT_BLOCK
	
	// Damage is handled by the kit component via COMSIG_ATOM_HITBY
	// The component will read def_zone to determine bodypart
	
	// Play hit sound
	playsound(victim, 'sound/weapons/tap.ogg', 50, TRUE)
	
	// Visual effect
	new /obj/effect/temp_visual/lasertag_hit(get_turf(victim))
	
	return BULLET_ACT_HIT
