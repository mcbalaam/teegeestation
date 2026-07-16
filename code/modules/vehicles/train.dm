/obj/vehicle/ridden/train
	name = "train"
	dir = EAST
	max_occupants = 1
	max_drivers = 1

	/// Active engines driving this train
	var/active_engines = 0
	/// All carts in this train
	var/list/active_carts = list()
	/// The leading train cart
	var/obj/vehicle/ridden/train/lead = null
	/// The train cart we're towing
	var/obj/vehicle/ridden/train/tow = null
	/// Length of the train this car is part of
	var/train_length = 1
	/// Whether to display chat messages for latching/unlatching
	var/display_to_chat = FALSE
	/// Riding component type to use for this vehicle
	var/riding_component_type = /datum/component/riding/vehicle/train

/obj/vehicle/ridden/train/Initialize(mapload)
	. = ..()
	if(riding_component_type)
		AddElement(/datum/element/ridable, riding_component_type)
	for(var/obj/vehicle/ridden/train/T in orange(1, src))
		latch(T)

/obj/vehicle/ridden/train/Destroy(force)
	lead = null
	tow = null
	return ..()

/obj/vehicle/ridden/train/Move(newloc, dir)
	var/atom/old_loc = loc
	. = ..()
	if(.)
		if(tow)
			tow.Move(old_loc)
	else if(lead)
		unattach()

/obj/vehicle/ridden/train/explode()
	if(tow)
		tow.unattach()
	unattach()

/obj/vehicle/ridden/train/mouse_drop_receive(atom/dropped, mob/living/user, params)
	if(user.buckled || user.stat || HAS_TRAIT(user, TRAIT_RESTRAINED) || !Adjacent(user) || !user.Adjacent(dropped) || !istype(dropped) || (user == dropped && !(user.mobility_flags & MOBILITY_MOVE)))
		return
	if(istype(dropped, /obj/vehicle/ridden/train))
		latch(dropped, user)
	else
		return ..()

/obj/vehicle/ridden/train/verb/unlatch_v()
	set name = "Unlatch"
	set desc = "Unhitches this train from the one in front of it."
	set category = "Object"
	set src in view(1)

	if(!istype(usr, /mob/living/carbon/human))
		return

	if(usr.incapacitated || !Adjacent(usr))
		return

	unattach(usr)


//-------------------------------------------
// Latching/unlatching procs
//-------------------------------------------

//attempts to attach src as a follower of the train T
/obj/vehicle/ridden/train/proc/attach_to(obj/vehicle/ridden/train/T, mob/user)
	display_to_chat = FALSE
	if(istype(user))
		display_to_chat = TRUE

	if(get_dist(src, T) > 1)
		if(display_to_chat)
			to_chat(user, span_danger("[src] is too far away from [T] to hitch them together."))
		return

	if(lead)
		if(display_to_chat)
			to_chat(user, span_danger("[src] is already hitched to something."))
		return

	if(T.tow)
		if(display_to_chat)
			to_chat(user, span_danger("[T] is already towing something."))
		return

	//check for cycles.
	var/obj/vehicle/ridden/train/next_car = T
	while(next_car)
		if(next_car == src)
			if(display_to_chat)
				to_chat(user, span_danger("That seems very silly."))
			return
		next_car = next_car.lead

	//latch with src as the follower
	lead = T
	T.tow = src
	setDir(lead.dir)

	if(user && display_to_chat)
		to_chat(user, span_notice("You hitch [src] to [T]."))

	update_stats()


//detaches the train from whatever is towing it
/obj/vehicle/ridden/train/proc/unattach(mob/user)
	display_to_chat = FALSE
	if(istype(user))
		display_to_chat = TRUE

	if(!lead)
		if(display_to_chat)
			to_chat(user, span_danger("[src] is not hitched to anything."))
		return

	lead.tow = null
	lead.update_stats()

	if(display_to_chat)
		to_chat(user, span_notice("You unhitch [src] from [lead]."))
	lead = null

	update_stats()

/obj/vehicle/ridden/train/proc/latch(obj/vehicle/ridden/train/T, mob/user)
	if(!istype(T) || !Adjacent(T))
		return FALSE

	var/T_dir = get_dir(src, T) //figure out where T is wrt src

	if(dir == T_dir) //if car is ahead
		src.attach_to(T, user)
	else if(turn(dir, 180) == T_dir) //else if car is behind
		T.attach_to(src, user)

//returns TRUE if this is the lead car of the train
/obj/vehicle/ridden/train/proc/is_train_head()
	if(lead)
		return FALSE
	return TRUE

/obj/vehicle/ridden/train/proc/is_engine_active()
	return FALSE

//-------------------------------------------------------
// Stat update procs
//
// Used for updating the stats for how long the train is.
// These are useful for calculating speed based on the
// size of the train, to limit super long trains.
//-------------------------------------------------------
/obj/vehicle/ridden/train/update_stats()
	//first, seek to the end of the train
	var/obj/vehicle/ridden/train/T = src
	while(T.tow)
		//check for cyclic train.
		if(T.tow == src)
			lead.tow = null
			lead.update_stats()

			lead = null
			update_stats()
			return
		T = T.tow

	//now walk back to the front.
	var/active_engines = 0
	var/train_length = 0
	while(T)
		train_length++
		if(T.is_engine_active())
			active_engines++
		T.update_car(train_length, active_engines)
		T = T.lead

/obj/vehicle/ridden/train/proc/update_car(train_length, active_engines)
	src.train_length = train_length
	src.active_engines = active_engines

//-------------------------------------------------------
// Inertia & acceleration riding component for trains
//-------------------------------------------------------
/datum/component/riding/vehicle/train
	ride_check_flags = RIDER_NEEDS_LEGS | RIDER_NEEDS_ARMS | UNBUCKLE_DISABLED_RIDER
	vehicle_move_delay = 2
	/// Current speed factor (0.1 to 1.0, where 1.0 = nominal speed)
	var/current_speed = 0.3
	/// How much speed increases per same-direction move
	var/acceleration_per_move = 0.08
	/// Speed retained when reversing to opposite direction
	var/opposite_dir_inertia = 0.3
	/// Speed retained when moving to perpendicular direction
	var/perpendicular_dir_inertia = 0.6
	/// Minimum speed factor floor
	var/min_speed_factor = 0.1

/datum/component/riding/vehicle/train/driver_move(atom/movable/movable_parent, mob/living/user, direction)
	var/obj/vehicle/ridden/train/train = movable_parent
	if(!istype(train))
		return ..()

	var/dir_change = (direction != train.dir)
	var/opposite = (direction == turn(train.dir, 180))

	if(opposite)
		current_speed = max(current_speed * opposite_dir_inertia, min_speed_factor)
	else if(dir_change)
		current_speed = max(current_speed * perpendicular_dir_inertia, min_speed_factor)
	else
		current_speed = min(current_speed + acceleration_per_move, 1.0)

	var/delay = get_target_delay(train)
	vehicle_move_delay = max(delay / max(current_speed, 0.01), 0.5)
	return ..()

/// Calculates the baseline delay for this train before the inertia factor is applied.
/datum/component/riding/vehicle/train/proc/get_target_delay(obj/vehicle/ridden/train/train)
	. = 2.0
	if(train.train_length > 1)
		. += (train.train_length - 1) * 0.2
