/datum/atom_skin/patriotic_pin
	abstract_type = /datum/atom_skin/patriotic_pin

/datum/atom_skin/patriotic_pin/russ
	preview_name = "Russian flag"
	new_icon_state = "flag_russ"

/datum/atom_skin/patriotic_pin/imper
	preview_name = "Imperial flag"
	new_icon_state = "flag_imper"

/datum/atom_skin/patriotic_pin/china
	preview_name = "China flag"
	new_icon_state = "flag_china"

/datum/atom_skin/patriotic_pin/germ
	preview_name = "German flag"
	new_icon_state = "flag_germ"

/datum/atom_skin/patriotic_pin/serb
	preview_name = "Serbian flag"
	new_icon_state = "flag_serb"

/datum/atom_skin/patriotic_pin/kaz
	preview_name = "Kazakh flag"
	new_icon_state = "flag_kaz"

/datum/atom_skin/patriotic_pin/iran
	preview_name = "Iranian flag"
	new_icon_state = "flag_iran"

/datum/atom_skin/patriotic_pin/cuba
	preview_name = "Cuban Pete"
	new_icon_state = "flag_cuba"

/obj/item/clothing/accessory/pride // actually patriotic (override)
	name = "patriotic pin"
	desc = "A Nanotrasen holographic pin to show off your patriotic."
	icon = 'massmeta/icons/obj/clothing/accessories.dmi'
	worn_icon = 'massmeta/icons/mob/clothing/accessories.dmi'
	icon_state = "flag_russ"
	obj_flags = UNIQUE_RENAME


/obj/item/clothing/accessory/pride/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/reskinable_item, /datum/atom_skin/patriotic_pin, infinite = TRUE)

