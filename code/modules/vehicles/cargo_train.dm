/obj/vehicle/ridden/train/cargo
	var/open = FALSE

/obj/vehicle/ridden/train/cargo/update_icon()
	. = ..()
	if(open)
		icon_state = initial(icon_state) + "_open"
	else
		icon_state = initial(icon_state)

/obj/vehicle/ridden/train/cargo/engine
	name = "cargo train tug"
	desc = "A rideable electric car designed for pulling cargo trolleys."
	icon = 'icons/obj/vehicles/vehicles.dmi'
	icon_state = "cargo_engine"
	key_type = /obj/item/key/cargo_train
	riding_component_type = /datum/component/riding/vehicle/train/cargo

	light_system = OVERLAY_LIGHT
	light_range = 5

	/// Whether the engine is running
	var/on = FALSE
	/// Whether this car is powered
	var/powered = TRUE
	/// How many cars an engine can pull before performance degrades
	var/car_limit = 3
	/// Power cell
	var/obj/item/stock_parts/power_store/cell/cell
	/// Power usage per move
	var/charge_use = 15

/obj/item/key/cargo_train
	name = "key"
	desc = "A keyring with a small steel key, and a yellow fob reading \"Choo Choo!\"."
	icon = 'icons/obj/vehicles/vehicles.dmi'
	icon_state = "train_keys"
	w_class = WEIGHT_CLASS_TINY

/obj/vehicle/ridden/train/cargo/trolley
	name = "cargo train trolley"
	icon = 'icons/obj/vehicles/vehicles.dmi'
	icon_state = "cargo_trailer"
	light_range = 0
	anchored = FALSE
	can_buckle = TRUE
	riding_component_type = /datum/component/riding/vehicle/trolley
	max_occupants = 2
	max_drivers = 1

	/// Currently loaded cargo object sitting on the trolley
	var/obj/cargo = null
	/// Typecache of objects that can be loaded onto the trolley
	var/static/list/allowed_cargo = typecacheof(list(
		/obj/structure/closet/crate,
		/obj/structure/reagent_dispensers,
		/obj/structure/flatpack_cart,
		/obj/machinery,
		/obj/item/kirbyplants,
	))
	/// Image overlay for cargo display
	var/image/cargo_overlay

//-------------------------------------------
// Standard procs
//-------------------------------------------
/obj/vehicle/ridden/train/cargo/engine/Initialize(mapload)
	. = ..()
	cell = new /obj/item/stock_parts/power_store/cell/lead
	inserted_key = new /obj/item/key/cargo_train(src)
	var/image/I = new(icon = 'icons/obj/vehicles/vehicles.dmi', icon_state = "cargo_engine_overlay", layer = src.layer + 0.2) //over mobs
	overlays += I

	if(light_range)
		set_light_on(TRUE)

	turn_off() //so engine verbs are correctly set

/obj/vehicle/ridden/train/cargo/engine/Destroy(force)
	if(!QDELETED(inserted_key))
		QDEL_NULL(inserted_key)
	QDEL_NULL(cell)
	return ..()

/obj/vehicle/ridden/train/cargo/engine/Move(newloc, dir)
	if(on && cell.charge() < charge_use)
		turn_off()
		update_stats()

	if(is_train_head() && !on)
		return FALSE

	return ..()

/obj/vehicle/ridden/train/cargo/engine/relaydrive(mob/user, direction)
	if(is_train_head())
		if(direction == turn(dir, 180) && tow)
			return FALSE
	return ..()

/obj/vehicle/ridden/train/cargo/trolley/insert_cell(obj/item/stock_parts/power_store/cell/C, mob/living/carbon/human/H)
	return

/obj/vehicle/ridden/train/cargo/engine/insert_cell(obj/item/stock_parts/power_store/cell/C, mob/living/carbon/human/H)
	update_stats()

/obj/vehicle/ridden/train/cargo/engine/remove_cell(mob/living/carbon/human/H)
	update_stats()


//-------------------------------------------
// Train procs
//-------------------------------------------
/obj/vehicle/ridden/train/cargo/engine/is_engine_active()
	return powered && on

/obj/vehicle/ridden/train/cargo/engine/turn_on()
	if(!inserted_key)
		return
	on = TRUE
	update_stats()

	verbs -= /obj/vehicle/ridden/train/cargo/engine/verb/stop_engine
	verbs -= /obj/vehicle/ridden/train/cargo/engine/verb/start_engine

	if(on)
		verbs += /obj/vehicle/ridden/train/cargo/engine/verb/stop_engine
	else
		verbs += /obj/vehicle/ridden/train/cargo/engine/verb/start_engine

/obj/vehicle/ridden/train/cargo/engine/turn_off()
	on = FALSE
	update_stats()

	verbs -= /obj/vehicle/ridden/train/cargo/engine/verb/stop_engine
	verbs -= /obj/vehicle/ridden/train/cargo/engine/verb/start_engine

	if(!on)
		verbs += /obj/vehicle/ridden/train/cargo/engine/verb/start_engine
	else
		verbs += /obj/vehicle/ridden/train/cargo/engine/verb/stop_engine


//-------------------------------------------
// Interaction procs
//-------------------------------------------
/obj/vehicle/ridden/train/cargo/engine/examine(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	if(get_dist(user, src) <= 1)
		. += "The power light is [on ? "on" : "off"].\nThere[inserted_key ? " are" : " are no"] keys in the ignition."
		. += "The charge meter reads [cell ? round(cell.percent(), 0.01) : 0]%"

/obj/vehicle/ridden/train/cargo/engine/verb/start_engine()
	set name = "Start engine"
	set category = "Object"
	set src in view(1)

	if(!istype(usr, /mob/living/carbon/human))
		return

	if(on)
		to_chat(usr, "The engine is already running.")
		return

	turn_on()
	if(on)
		to_chat(usr, "You start [src]'s engine.")
	else
		if(cell)
			if(cell.charge() < charge_use)
				to_chat(usr, "[src] is out of power.")
			else
				to_chat(usr, "[src]'s engine won't start.")
		else
			to_chat(usr, "[src]'s engine won't start.")

/obj/vehicle/ridden/train/cargo/engine/verb/stop_engine()
	set name = "Stop engine"
	set category = "Object"
	set src in view(1)

	if(!istype(usr, /mob/living/carbon/human))
		return

	if(!on)
		to_chat(usr, "The engine is already stopped.")
		return

	turn_off()
	if(!on)
		to_chat(usr, "You stop [src]'s engine.")

//-------------------------------------------------------
// Stat update procs
//
// Update the trains stats for speed calculations.
// The longer the train, the slower it will go. car_limit
// sets the max number of cars one engine can pull at
// full speed. Adding more cars beyond this will slow the
// train proportionate to the length of the train. Adding
// more engines increases this limit by car_limit per
// engine.
//-------------------------------------------------------
/obj/vehicle/ridden/train/cargo/engine/update_car(train_length, active_engines)
	src.train_length = train_length
	src.active_engines = active_engines //makes cargo trains 10% slower than running when not overweight

/obj/vehicle/ridden/train/cargo/trolley/update_car(train_length, active_engines)
	src.train_length = train_length
	src.active_engines = active_engines

	if(!lead && !tow)
		anchored = FALSE
	else
		anchored = TRUE


//-------------------------------------------
// Cargo loading / unloading
//-------------------------------------------
/obj/vehicle/ridden/train/cargo/trolley/proc/can_load(obj/thing)
	return is_type_in_typecache(thing, allowed_cargo) && !cargo

/obj/vehicle/ridden/train/cargo/trolley/proc/load(obj/to_load)
	if(!to_load || cargo)
		return
	if(to_load.anchored)
		return
	if(to_load.has_buckled_mobs())
		return
	if(istype(to_load, /obj/structure/closet))
		var/obj/structure/closet/crate = to_load
		crate.close()
	to_load.forceMove(src)
	cargo = to_load
	update_cargo_overlay()

/obj/vehicle/ridden/train/cargo/trolley/proc/unload()
	if(!cargo)
		return
	var/list/candidates = list(
		get_step(src, turn(dir, 180)),
		get_step(src, turn(dir, 90)),
		get_step(src, turn(dir, 270)),
	)
	var/atom/dropoff = get_turf(src)
	for(var/atom/turf in candidates)
		if(turf.Enter(cargo, src))
			dropoff = turf
			break
	cargo.forceMove(dropoff)
	cargo = null
	update_cargo_overlay()

/obj/vehicle/ridden/train/cargo/trolley/proc/update_cargo_overlay()
	cut_overlay(cargo_overlay)
	cargo_overlay = null
	if(!cargo)
		return
	cargo_overlay = image(cargo.icon, cargo.icon_state, layer + 0.1)
	cargo_overlay.pixel_z = 11
	add_overlay(cargo_overlay)

/obj/vehicle/ridden/train/cargo/trolley/examine(mob/user)
	. = ..()
	if(cargo)
		. += span_info("It is carrying \the [cargo].")

/obj/vehicle/ridden/train/cargo/trolley/attack_hand(mob/user, list/modifiers)
	if(cargo)
		unload()
		return TRUE
	return ..()

/obj/vehicle/ridden/train/cargo/trolley/crowbar_act(mob/living/user, obj/item/tool)
	if(!cargo)
		return
	tool.play_tool_sound(src, 50)
	unload()
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/ridden/train/cargo/trolley/mouse_drop_receive(atom/dropped, mob/user, params)
	if(!can_load(dropped))
		if(!isliving(dropped) || (has_buckled_mobs() && LAZYLEN(buckled_mobs) >= max_buckled_mobs))
			balloon_alert_to_viewers("blocked!")
			return
		return ..()
	var/obj/dropped_obj = dropped
	return load(dropped_obj)

/obj/vehicle/ridden/train/cargo/trolley/relay_container_resist_act(mob/living/user, obj/container)
	if(!cargo || cargo != container)
		return
	user.visible_message(
		span_danger("[user] tries to escape the [container]!"),
		span_userdanger("You try to escape the [container]!"),
	)
	if(do_after(user, 5 SECONDS, target = src, timed_action_flags = IGNORE_USER_LOC_CHANGE))
		if(!cargo || cargo != container || !(user in cargo))
			return
		unload()
		user.visible_message(
			span_danger("The [container] falls off of [src]!"),
			span_userdanger("You knock the container off [src]!"),
		)


//-------------------------------------------
// Riding components
//-------------------------------------------

// Cargo engine component – adds train‑length slowdown and battery drain
/datum/component/riding/vehicle/train/cargo
	keytype = /obj/item/key/cargo_train
	vehicle_move_delay = 2
	ride_check_flags = RIDER_NEEDS_LEGS | RIDER_NEEDS_ARMS | UNBUCKLE_DISABLED_RIDER

/datum/component/riding/vehicle/train/cargo/get_target_delay(obj/vehicle/ridden/train/train)
	. = ..()
	if(train.active_engines > 0)
		. = max(. - train.active_engines * 0.15, 0.8)

/datum/component/riding/vehicle/train/cargo/handle_ride(mob/user, direction)
	. = ..()
	var/obj/vehicle/ridden/train/cargo/engine/engine = parent
	if(istype(engine) && engine.cell)
		var/charge_to_use = min(engine.charge_use, engine.cell.charge())
		engine.cell.use(charge_to_use)

// Detached trolley component – extremely slow, no inertia or acceleration
/datum/component/riding/vehicle/trolley
	ride_check_flags = RIDER_NEEDS_LEGS | RIDER_NEEDS_ARMS | UNBUCKLE_DISABLED_RIDER
	vehicle_move_delay = 15
