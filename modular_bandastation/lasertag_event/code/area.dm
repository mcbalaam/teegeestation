/// Lasertag Event Area
/// Special area where lasertag mechanics are active
/area/lasertag_event
	name = "Lasertag Arena"
	icon_state = "lasertag"
	requires_power = FALSE
	area_flags = UNIQUE_AREA | NOTELEPORT
	sound_environment = SOUND_AREA_STANDARD_STATION
	outdoors = TRUE // Forest arena

/area/lasertag_event/Initialize(mapload)
	. = ..()
	// Apply TRAIT_PACIFISM to all mobs that enter
	RegisterSignal(src, COMSIG_AREA_ENTERED, PROC_REF(on_entered))
	RegisterSignal(src, COMSIG_AREA_EXITED, PROC_REF(on_exited))

/area/lasertag_event/proc/on_entered(datum/source, atom/movable/arrived, area/old_area)
	SIGNAL_HANDLER
	
	if(!isliving(arrived))
		return
	
	var/mob/living/living_mob = arrived
	
	// Apply pacifism trait
	ADD_TRAIT(living_mob, TRAIT_PACIFISM, "lasertag_area")
	
	to_chat(living_mob, span_notice("You enter the lasertag arena. Physical violence is disabled."))

/area/lasertag_event/proc/on_exited(datum/source, atom/movable/gone, direction)
	SIGNAL_HANDLER
	
	if(!isliving(gone))
		return
	
	var/mob/living/living_mob = gone
	
	// Remove pacifism trait
	REMOVE_TRAIT(living_mob, TRAIT_PACIFISM, "lasertag_area")
	
	to_chat(living_mob, span_notice("You leave the lasertag arena."))
