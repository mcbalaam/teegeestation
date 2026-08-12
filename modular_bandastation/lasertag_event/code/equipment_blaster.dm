/// Lasertag Blaster (Carbine)
/// Energy weapon with magnetic tether, infinite recharge
/obj/item/gun/energy/lasertag/blaster
	name = "lasertag blaster"
	desc = "A high-tech laser carbine for lasertag events. Returns to your back when dropped."
	icon_state = "lasertag_carbine"
	inhand_icon_state = "lasertag_carbine"
	ammo_type = list(/obj/item/ammo_casing/energy/lasertag_event)
	cell_type = /obj/item/stock_parts/power_store/cell/lasertag
	can_charge = FALSE
	selfcharge = TRUE
	
	/// Reference to the kit component
	var/datum/component/lasertag_kit/kit
	/// Is currently flashing red (disabled)
	var/flashing = FALSE
	/// Flash timer
	var/flash_timer
	/// Is reloading
	var/reloading = FALSE

/obj/item/gun/energy/lasertag/blaster/Initialize(mapload)
	. = ..()
	// TODO: Add magnetic tether component when available
	// AddComponent(/datum/component/item_equipped_slot_return, ITEM_SLOT_BACK)

/obj/item/gun/energy/lasertag/blaster/Destroy()
	kit = null
	if(flash_timer)
		deltimer(flash_timer)
	return ..()

/obj/item/gun/energy/lasertag/blaster/can_shoot()
	. = ..()
	if(!.)
		return FALSE
	
	// Check if kit is active
	if(kit && !kit.active)
		return FALSE
	
	// Check if in safe zone
	if(kit && kit.controller)
		var/mob/living/user = loc
		if(istype(user) && kit.controller.is_in_safe_zone(user))
			return FALSE
	
	return TRUE

/obj/item/gun/energy/lasertag/blaster/process_fire(atom/target, mob/living/user, message, params, zone_override, bonus_spread)
	// Check if can shoot
	if(!can_shoot())
		return
	
	return ..()
