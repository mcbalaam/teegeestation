/// Lasertag Headband
/// NODROP headwear that's part of the kit
/obj/item/clothing/head/lasertag_band
	name = "lasertag headband"
	desc = "A headband with hit sensors. Counts as a 2x damage zone."
	icon_state = "lasertag_band"
	clothing_traits = list(TRAIT_NODROP)
	
	/// Reference to the kit component
	var/datum/component/lasertag_kit/kit

/obj/item/clothing/head/lasertag_band/Destroy()
	kit = null
	return ..()

/obj/item/clothing/head/lasertag_band/dropped(mob/user, silent)
	. = ..()
	// Prevent dropping
	if(user && kit)
		to_chat(user, span_warning("[src] is magnetically sealed to your head!"))
		user.equip_to_slot_if_possible(src, ITEM_SLOT_HEAD, disable_warning = TRUE)

// Red team variant
/obj/item/clothing/head/lasertag_band/red
	name = "red lasertag headband"
	color = "#AA0000"

// Blue team variant
/obj/item/clothing/head/lasertag_band/blue
	name = "blue lasertag headband"
	color = "#0000AA"
