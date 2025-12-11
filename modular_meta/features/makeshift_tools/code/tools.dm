/obj/item/radio/off/makeshift	// Makeshift SBR, limited use cases but could be useful.
	icon = 'modular_meta/features/makeshift_tools/icons/improvised.dmi'
	icon_state = "radio_makeshift"
	subspace_switchable = TRUE  // Made with a headset, so it can transmit over subspace I guess
	freqlock = TRUE

/obj/item/storage/belt/utility/makeshift
	name = "makeshift toolbelt"
	desc = "A shoddy holder of tools."
	icon = 'modular_meta/features/makeshift_tools/icons/belts.dmi'
	worn_icon = 'modular_meta/features/makeshift_tools/icons/mob_belts.dmi'
	lefthand_file = 'modular_meta/features/makeshift_tools/icons/belt_lefthand.dmi'
	righthand_file = 'modular_meta/features/makeshift_tools/icons/belt_righthand.dmi'
	inhand_icon_state = "makeshiftbelt"
	worn_icon_state = "makeshiftbelt"
	icon_state = "makeshiftbelt"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/utility/makeshift/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 6 //It's a very crappy belt
	atom_storage.max_total_storage = 16

/obj/item/crowbar/makeshift
	name = "makeshift crowbar"
	desc = "A crude, self-wrought crowbar. Heavy."
	icon = 'modular_meta/features/makeshift_tools/icons/improvised.dmi'
	icon_state = "crowbar_makeshift"
	worn_icon_state = "crowbar"
	force = 12 //same as large crowbar, but bulkier and slower
	w_class = WEIGHT_CLASS_BULKY
	toolspeed = 2

/obj/item/crowbar/makeshift/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	..()
	if(prob(5))
		to_chat(user, span_danger("[src] crumbles apart in your hands!"))
		qdel(src)
		return

/obj/item/knife/kitchen/makeshift/makeshift
	name = "makeshift knife"
	icon_state = "knife_makeshift"
	icon = 'modular_meta/features/makeshift_tools/icons/improvised.dmi'
	desc = "A flimsy, poorly made replica of a classic cooking utensil."
	force = 8
	throwforce = 8

/obj/item/knife/kitchen/makeshift/makeshift/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	..()
	if(prob(5))
		to_chat(user, span_danger("[src] crumbles apart in your hands!"))
		qdel(src)
		return

/obj/item/multitool/makeshift
	name = "makeshift multitool"
	desc = "As crappy as it is, its still mostly the same as a standard issue Nanotrasen one."
	icon = 'modular_meta/features/makeshift_tools/icons/improvised.dmi'
	icon_state = "multitool_makeshift"
	toolspeed = 2

/obj/item/multitool/makeshift/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	..()
	if(prob(5))
		to_chat(user, span_danger("[src] crumbles apart in your hands!"))
		qdel(src)
		return

/obj/item/screwdriver/makeshift
	name = "makeshift screwdriver"
	desc = "Crude driver of screws. A primitive way to screw things up."
	icon = 'modular_meta/features/makeshift_tools/icons/improvised.dmi'
	icon_state = "screwdriver_makeshift"
	toolspeed = 2
	random_color = FALSE

/obj/item/screwdriver/makeshift/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	..()
	if(prob(5))
		to_chat(user, span_danger("[src] crumbles apart in your hands!"))
		qdel(src)
		return

/obj/item/weldingtool/makeshift
	name = "makeshift welding tool"
	desc = "A MacGyver-style welder."
	icon = 'modular_meta/features/makeshift_tools/icons/improvised.dmi'
	icon_state = "welder_makeshift"
	toolspeed = 2
	max_fuel = 10
	starting_fuel = FALSE
	change_icons = FALSE
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*0.7)

/obj/item/weldingtool/makeshift/switched_on(mob/user)
	..()
	if(welding && get_fuel() >= 1 && prob(2))
		var/datum/effect_system/reagents_explosion/e = new()
		to_chat(user, span_userdanger("Shoddy construction causes [src] to blow the fuck up!"))
		e.set_up(round(get_fuel() / 10, 1), get_turf(src), 0, 0)
		e.start()
		qdel(src)
		return

/obj/item/wirecutters/makeshift
	name = "makeshift wirecutters"
	desc = "Mind your fingers."
	icon = 'modular_meta/features/makeshift_tools/icons/improvised.dmi'
	icon_state = "cutters_makeshift"
	toolspeed = 2
	random_color = FALSE

/obj/item/wirecutters/makeshift/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	..()
	if(prob(5))
		to_chat(user, span_danger("[src] crumbles apart in your hands!"))
		qdel(src)
		return

/obj/item/wrench/makeshift
	name = "makeshift wrench"
	desc = "A crude, self-wrought wrench with common uses. Can be found in your hand."
	icon = 'modular_meta/features/makeshift_tools/icons/improvised.dmi'
	icon_state = "wrench_makeshift"
	toolspeed = 2

/obj/item/wrench/makeshift/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	..()
	if(prob(5))
		to_chat(user, span_danger("[src] crumbles apart in your hands!"))
		qdel(src)
		return

