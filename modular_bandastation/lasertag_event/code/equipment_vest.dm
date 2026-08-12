/// Lasertag Vest
/// NODROP armor that stores kit HP and provides visual feedback
/obj/item/clothing/suit/armor/vest/lasertag
	name = "lasertag vest"
	desc = "A high-tech vest equipped with hit sensors. Part of the lasertag kit."
	icon_state = "lasertag_vest"
	inhand_icon_state = "armor"
	armor_type = /datum/armor/vest_lasertag
	clothing_traits = list(TRAIT_NODROP)
	
	/// Reference to the kit component
	var/datum/component/lasertag_kit/kit
	/// Is the vest currently flashing red
	var/flashing = FALSE
	/// Flash timer
	var/flash_timer

/datum/armor/vest_lasertag
	melee = 0
	bullet = 0
	laser = 0
	energy = 0
	bomb = 0
	bio = 0
	fire = 0
	acid = 0

/obj/item/clothing/suit/armor/vest/lasertag/Destroy()
	kit = null
	if(flash_timer)
		deltimer(flash_timer)
	return ..()

/obj/item/clothing/suit/armor/vest/lasertag/dropped(mob/user, silent)
	. = ..()
	// Prevent dropping
	if(user && kit)
		to_chat(user, span_warning("[src] is magnetically sealed to your body!"))
		user.equip_to_slot_if_possible(src, ITEM_SLOT_OCLOTHING, disable_warning = TRUE)

/// Start flashing red
/obj/item/clothing/suit/armor/vest/lasertag/proc/start_flashing()
	if(flashing)
		return
	
	flashing = TRUE
	flash_loop()

/// Stop flashing
/obj/item/clothing/suit/armor/vest/lasertag/proc/stop_flashing()
	flashing = FALSE
	if(flash_timer)
		deltimer(flash_timer)
		flash_timer = null
	
	// Reset to normal appearance
	alpha = 255
