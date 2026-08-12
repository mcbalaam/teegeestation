
/// Kit disabled (0 HP)
/datum/component/lasertag_kit/proc/on_kit_disabled(mob/attacker)
	active = FALSE
	deaths++
	
	// Award death penalty
	var/mob/living/owner = parent
	if(owner && owner.ckey)
		controller.award_death_penalty(owner.ckey)
	
	// Award kill to attacker
	if(attacker && attacker.ckey)
		var/datum/component/lasertag_kit/attacker_kit = controller.all_players[attacker.ckey]
		if(attacker_kit)
			attacker_kit.kills++
	
	// Visual effects
	start_disabled_visuals()
	
	// Show death message
	if(owner)
		to_chat(owner, span_userdanger("Your kit has been disabled! Return to base to respawn."))

/// Disable kit (admin command or game end)
/datum/component/lasertag_kit/proc/disable_kit()
	active = FALSE
	start_disabled_visuals()

/// Enable kit (respawn)
/datum/component/lasertag_kit/proc/enable_kit()
	hp = max_hp
	active = TRUE
	stop_disabled_visuals()
	
	// Refill blaster ammo
	if(blaster)
		blaster.refill_magazine()
	
	var/mob/living/owner = parent
	if(owner)
		to_chat(owner, span_notice("Kit reactivated! You have [hp] HP."))

/// Reset kit stats
/datum/component/lasertag_kit/proc/reset_kit()
	score = 0
	kills = 0
	deaths = 0
	shots_fired = 0
	shots_hit = 0
	enable_kit()

/// Add score to player
/datum/component/lasertag_kit/proc/add_score(points)
	score += points
