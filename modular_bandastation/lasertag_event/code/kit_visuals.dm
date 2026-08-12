
/// Handle gun fired
/datum/component/lasertag_kit/proc/on_fired_gun(datum/source, obj/item/gun/gun, mob/living/user, atom/target, params, zone_override, list/bonus_spread)
	SIGNAL_HANDLER
	
	shots_fired++

/// Start disabled visuals (red flashing, cross icon)
/datum/component/lasertag_kit/proc/start_disabled_visuals()
	// Flash vest red
	if(vest)
		vest.start_flashing()
	
	// Flash blaster red
	if(blaster)
		blaster.start_flashing()
	
	// Add cross icon above head
	var/mob/living/owner = parent
	if(owner)
		owner.add_overlay(image('icons/effects/effects.dmi', "lasertag_dead")) // TODO: proper icon

/// Stop disabled visuals
/datum/component/lasertag_kit/proc/stop_disabled_visuals()
	// Stop flashing
	if(vest)
		vest.stop_flashing()
	
	if(blaster)
		blaster.stop_flashing()
	
	// Remove cross icon
	var/mob/living/owner = parent
	if(owner)
		owner.cut_overlay(image('icons/effects/effects.dmi', "lasertag_dead")) // TODO: proper icon

/// Get accuracy percentage
/datum/component/lasertag_kit/proc/get_accuracy()
	if(shots_fired <= 0)
		return 0
	return round((shots_hit / shots_fired) * 100, 0.1)

/// Bind equipment to kit
/datum/component/lasertag_kit/proc/bind_equipment(obj/item/clothing/suit/armor/vest/lasertag/new_vest, obj/item/clothing/head/lasertag_band/new_headband, obj/item/gun/energy/lasertag/new_blaster)
	vest = new_vest
	headband = new_headband
	blaster = new_blaster
	
	// Set references back
	if(vest)
		vest.kit = src
	if(headband)
		headband.kit = src
	if(blaster)
		blaster.kit = src
