/obj/item/gun/magic/staff/chair
	name = "staff of the chair"
	desc = "An artefact that expels encapsulating bolts, for incapacitating thy enemy."
	fire_sound = 'sound/effects/magic/staff_change.ogg'
	icon = 'modular_bandastation/chair_staff/icons/chair.dmi'
	ammo_type = /obj/item/ammo_casing/magic/chair
	icon_state = "chair"
	inhand_icon_state = "locker"
	worn_icon_state = "lockerstaff"
	max_charges = 6
	recharge_rate = 4
	school = SCHOOL_TRANSMUTATION

/obj/item/ammo_casing/magic/chair
	projectile_type = /obj/projectile/magic/chair

/obj/projectile/magic/chair
	name = "chair bolt"
	icon = 'modular_bandastation/chair_staff/icons/chair.dmi'
	icon_state = "projectile"
	var/created = FALSE

/obj/projectile/magic/chair/Initialize(mapload)
	. = ..()

/obj/projectile/magic/chair/prehit_pierce(atom/A)
	. = ..()
	if(. == PROJECTILE_DELETE_WITHOUT_HITTING && created)
		var/obj/structure/chair/chair_temp_instance = locate() in get_turf(src)
		qdel(chair_temp_instance)
		return PROJECTILE_DELETE_WITHOUT_HITTING

	if(created)
		return

	if(A.density && !isliving(A))
		new /obj/structure/chair(get_turf(loc))
		created = TRUE
		return PROJECTILE_DELETE_WITHOUT_HITTING

	if(isliving(A))
		RegisterSignal(src, COMSIG_PROJECTILE_ON_HIT, PROC_REF(handle_mob_hit))
		return PROJECTILE_PIERCE_PHASE

/obj/projectile/magic/chair/proc/handle_mob_hit(atom/target)
	SIGNAL_HANDLER
	if(isliving(target) && !created)
		var/obj/structure/chair/new_chair = new(get_turf(target))
		if(new_chair.buckle_mob(target))
			target.visible_message(span_warning("[target] получает стул!"))
		if(ishuman(target))
			var/mob/living/carbon/human/this_human = target
			this_human.drop_all_held_items()
			if(!this_human.handcuffed)
				this_human.handcuffed = new /obj/item/restraints/handcuffs/cable/zipties(src)
		created = TRUE

/obj/projectile/magic/chair/on_hit(atom/target, blocked = 0, pierce_hit)
	UnregisterSignal(src, COMSIG_PROJECTILE_ON_HIT)
	return ..()
