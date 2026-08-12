
/// Reload magazine (5 second doafter for pistol)
/obj/item/gun/energy/lasertag/pistol/proc/reload_magazine(mob/living/user)
	if(reloading)
		return
	
	if(cell.charge >= cell.maxcharge)
		to_chat(user, span_notice("[src] is already fully charged!"))
		return
	
	reloading = TRUE
	to_chat(user, span_notice("You begin reloading [src]..."))
	
	// 5 second doafter
	if(!do_after(user, LASERTAG_PISTOL_RELOAD_TIME, target = user, interaction_key = "lasertag_reload", progress = TRUE))
		reloading = FALSE
		to_chat(user, span_warning("You stop reloading [src]."))
		return
	
	// Refill magazine
	cell.charge = cell.maxcharge
	reloading = FALSE
	to_chat(user, span_notice("[src] is fully charged!"))
	playsound(src, 'sound/items/eshield_recharge.ogg', 50, TRUE)

/// Force refill
/obj/item/gun/energy/lasertag/pistol/proc/refill_magazine()
	if(cell)
		cell.charge = cell.maxcharge

/// Auto-reload when empty
/obj/item/gun/energy/lasertag/pistol/process_chamber(empty_chamber, from_firing, chamber_next_round)
	. = ..()
	
	if(cell.charge <= 0)
		var/mob/living/user = loc
		if(istype(user))
			reload_magazine(user)

/// Battery cells for lasertag weapons
/obj/item/stock_parts/power_store/cell/lasertag
	name = "lasertag carbine cell"
	maxcharge = LASERTAG_BLASTER_MAGAZINE_SIZE
	charge = LASERTAG_BLASTER_MAGAZINE_SIZE

/obj/item/stock_parts/power_store/cell/lasertag_pistol
	name = "lasertag pistol cell"
	maxcharge = LASERTAG_PISTOL_MAGAZINE_SIZE
	charge = LASERTAG_PISTOL_MAGAZINE_SIZE
