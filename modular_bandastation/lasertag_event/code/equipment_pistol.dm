
/// Trigger reload when empty
/obj/item/gun/energy/lasertag/blaster/process_chamber(empty_chamber, from_firing, chamber_next_round)
	. = ..()
	
	// Auto-reload when empty
	if(cell.charge <= 0)
		var/mob/living/user = loc
		if(istype(user))
			reload_magazine(user)

// Red team variant
/obj/item/gun/energy/lasertag/blaster/red
	name = "red lasertag blaster"
	color = "#AA0000"

// Blue team variant
/obj/item/gun/energy/lasertag/blaster/blue
	name = "blue lasertag blaster"
	color = "#0000AA"

/// Lasertag Pistol (Engineer)
/// Weaker pistol with longer reload
/obj/item/gun/energy/lasertag/pistol
	name = "lasertag pistol"
	desc = "A compact laser pistol for lasertag events. Weaker than the carbine."
	icon_state = "lasertag_pistol"
	inhand_icon_state = "lasertag_pistol"
	ammo_type = list(/obj/item/ammo_casing/energy/lasertag_event)
	cell_type = /obj/item/stock_parts/power_store/cell/lasertag_pistol
	can_charge = FALSE
	selfcharge = TRUE
	
	/// Reference to the kit component
	var/datum/component/lasertag_kit/kit
	/// Is reloading
	var/reloading = FALSE

/obj/item/gun/energy/lasertag/pistol/Initialize(mapload)
	. = ..()
	// TODO: Add magnetic tether component when available
	// AddComponent(/datum/component/item_equipped_slot_return, ITEM_SLOT_BACK)

/obj/item/gun/energy/lasertag/pistol/Destroy()
	kit = null
	return ..()

/obj/item/gun/energy/lasertag/pistol/can_shoot()
	. = ..()
	if(!.)
		return FALSE
	
	// Check if kit is active
	if(kit && !kit.active)
		return FALSE
	
	return TRUE
