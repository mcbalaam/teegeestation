
/// Reload magazine (3 second doafter)
/obj/item/gun/energy/lasertag/blaster/proc/reload_magazine(mob/living/user)
	if(reloading)
		return
	
	if(cell.charge >= cell.maxcharge)
		to_chat(user, span_notice("[src] is already fully charged!"))
		return
	
	reloading = TRUE
	to_chat(user, span_notice("You begin reloading [src]..."))
	
	// 3 second doafter that doesn't interrupt on movement
	if(!do_after(user, LASERTAG_BLASTER_RELOAD_TIME, target = user, interaction_key = "lasertag_reload", progress = TRUE))
		reloading = FALSE
		to_chat(user, span_warning("You stop reloading [src]."))
		return
	
	// Refill magazine
	cell.charge = cell.maxcharge
	reloading = FALSE
	to_chat(user, span_notice("[src] is fully charged!"))
	playsound(src, 'sound/items/eshield_recharge.ogg', 50, TRUE)

/// Force refill (from respawn station)
/obj/item/gun/energy/lasertag/blaster/proc/refill_magazine()
	if(cell)
		cell.charge = cell.maxcharge

/// Start flashing red
/obj/item/gun/energy/lasertag/blaster/proc/start_flashing()
	if(flashing)
		return
	
	flashing = TRUE
	flash_loop()

/// Stop flashing
/obj/item/gun/energy/lasertag/blaster/proc/stop_flashing()
	flashing = FALSE
	if(flash_timer)
		deltimer(flash_timer)
		flash_timer = null
	
	// Reset to normal appearance
	alpha = 255

/// Flash loop
/obj/item/gun/energy/lasertag/blaster/proc/flash_loop()
	if(!flashing)
		return
	
	// Toggle between bright red flash and normal
	if(alpha == 255)
		color = "#FF0000"
		alpha = 200
	else
		color = initial(color)
		alpha = 255
	
	flash_timer = addtimer(CALLBACK(src, PROC_REF(flash_loop)), 0.5 SECONDS, TIMER_STOPPABLE)
