
/// Flash loop
/obj/item/clothing/suit/armor/vest/lasertag/proc/flash_loop()
	if(!flashing)
		return
	
	// Toggle between bright red flash and normal
	if(alpha == 255)
		color = "#FF0000"
		alpha = 200
	else
		color = initial(color)
		alpha = 255
	
	// Update on mob
	var/mob/living/wearer = loc
	if(istype(wearer))
		wearer.update_clothing(ITEM_SLOT_OCLOTHING)
	
	flash_timer = addtimer(CALLBACK(src, PROC_REF(flash_loop)), 0.5 SECONDS, TIMER_STOPPABLE)

// Red team variant
/obj/item/clothing/suit/armor/vest/lasertag/red
	name = "red lasertag vest"
	color = "#AA0000"

// Blue team variant
/obj/item/clothing/suit/armor/vest/lasertag/blue
	name = "blue lasertag vest"
	color = "#0000AA"
