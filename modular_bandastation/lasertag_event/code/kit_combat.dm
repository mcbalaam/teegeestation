
/// Handle being hit by projectile
/datum/component/lasertag_kit/proc/on_hit_by(datum/source, atom/movable/hitby, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	
	if(!istype(hitby, /obj/projectile/beam/lasertag))
		return
	
	if(!active)
		return TRUE // Kit disabled, block damage
	
	var/obj/projectile/beam/lasertag/beam = hitby
	
	// Check safe zone
	var/mob/living/owner = parent
	if(controller.is_in_safe_zone(owner))
		return TRUE
	
	// Calculate damage based on bodypart hit
	var/damage = 0
	var/is_headshot = FALSE
	
	// Check what body part was hit
	var/obj/item/bodypart/hit_part = owner.get_bodypart(beam.def_zone)
	if(hit_part)
		if(hit_part.body_zone == BODY_ZONE_HEAD)
			damage = LASERTAG_DAMAGE_HEAD
			is_headshot = TRUE
		else if(hit_part.body_zone == BODY_ZONE_CHEST)
			damage = LASERTAG_DAMAGE_CHEST
	
	if(damage <= 0)
		return TRUE // Not a valid hit zone
	
	// Apply damage to kit
	take_damage(damage, is_headshot, beam.firer)
	
	// Award points to shooter
	if(beam.firer && beam.firer.ckey)
		controller.award_hit_points(beam.firer.ckey, is_headshot)
		
		// Track hit for shooter's accuracy
		var/datum/component/lasertag_kit/shooter_kit = controller.all_players[beam.firer.ckey]
		if(shooter_kit)
			shooter_kit.shots_hit++
	
	return TRUE // Block actual mob damage

/// Take damage to kit
/datum/component/lasertag_kit/proc/take_damage(amount, is_headshot = FALSE, mob/attacker)
	if(!active)
		return
	
	hp -= amount
	
	if(hp <= 0)
		hp = 0
		on_kit_disabled(attacker)
