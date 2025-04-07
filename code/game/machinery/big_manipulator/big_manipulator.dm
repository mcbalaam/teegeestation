/// The Big Manipulator's core. Main part of the mechanism that carries out the entire process.
/obj/machinery/big_manipulator
	name = "Big Manipulator"
	desc = "Operates different objects. Truly, a groundbreaking innovation..."
	icon = 'icons/obj/machines/big_manipulator_parts/big_manipulator_core.dmi'
	icon_state = "core"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/big_manipulator
	greyscale_colors = "#d8ce13"
	greyscale_config = /datum/greyscale_config/big_manipulator

	/// Min time manipulator can have in delay. Changing on upgrade.
	var/minimal_interaction_multiplier = MIN_DELAY_TIER_1
	/// Time it takes to rotate between adjacent points (45 degrees)
	var/rotation_delay = MIN_DELAY_TIER_1 * 0.5
	/// The interaction time modifier - faster to slower.
	var/interaction_multiplier = STARTING_MULTIPLIER
	/// The time it takes for the manipulator to move from one point to another.
	var/interaction_delay = MIN_DELAY_TIER_1 * STARTING_MULTIPLIER

	/// The status of the manipulator - `IDLE` or `BUSY`.
	var/status = STATUS_IDLE
	/// Is the manipulator turned on?
	var/on = FALSE

	/// Priority settings depending on the manipulator use mode that are available to this manipulator. Filled during Initialize.
	var/list/priority_settings_for_use = list()
	/// What priority settings are available to use at the moment.
	/// We also use this list to sort priorities from ascending to descending.
	var/list/allowed_priority_settings = list()
	/// The object inside the manipulator.
	var/datum/weakref/held_object
	/// The poor monkey that needs to use mode works.
	var/datum/weakref/monkey_worker
	/// weakref to id that locked this manipualtor.
	var/datum/weakref/locked_by_this_id
	/// Is manipulator locked by identity id.
	var/id_locked = FALSE
	/// The manipulator's arm.
	var/obj/effect/big_manipulator_arm/manipulator_arm
	/// Has this manipulator been emagged?
	var/emagged = FALSE

	/// How should the manipulator interact with the object?
	var/interaction_mode = INTERACT_DROP
	/// How should the worker interact with the object?
	var/worker_interaction = WORKER_NORMAL_USE
	/// The distance the thrown object should travel when thrown.
	var/manipulator_throw_range = 1
	/// Overrides the priority selection, only accessing the top priority list element.
	var/override_priority = FALSE
	/// The `type` the manipulator will interact with only.
	var/atom/selected_type
	/// Is the power access wire cut? Disables the power button if `TRUE`.
	var/power_access_wire_cut = FALSE
	/// List where we can set selected type. Taking items by Initialize.
	var/list/type_filters = list(
		/obj/item,
		/obj/structure/closet,
	)

	/// History of accessed pickup points for round-robin tasking.
	var/list/roundrobin_history_pickup = 1
	/// History of accessed dropoff points for round-robin tasking.
	var/list/roundrobin_history_dropoff = 1
	/// Which tasking scenario we use for pickup points?
	var/pickup_tasking = TASKING_ROUND_ROBIN
	/// Which tasking scenario we use for dropoff points?
	var/dropoff_tasking = TASKING_ROUND_ROBIN
	/// List of pickup points.
	var/list/pickup_points = list()
	/// List of dropoff points.
	var/list/dropoff_points = list()

/obj/machinery/big_manipulator/proc/create_new_interaction_point(turf/new_turf, list/new_filters, new_filters_status, new_interaction_mode, transfer_type)
	if(!new_turf)
		stack_trace("Attempting to create a new interaction point, but no valid turf references were passed.")
		return FALSE

	var/datum/interaction_point/new_interaction_point = new(src, new_turf, new_filters, new_filters_status, new_interaction_mode)

	if(QDELETED(new_interaction_point))
		return FALSE

	switch(transfer_type)
		if(TRANSFER_TYPE_PICKUP)
			pickup_points += new_interaction_point
		if(TRANSFER_TYPE_DROPOFF)
			dropoff_points += new_interaction_point

	if(emagged)
		new_interaction_point.type_filters += /mob/living

	return new_interaction_point

/obj/machinery/big_manipulator/proc/update_all_points_on_emag_act()
	for(var/datum/interaction_point/pickup_point in pickup_points)
		pickup_point.type_filters += /mob/living
	for(var/datum/interaction_point/dropoff_point in dropoff_points)
		dropoff_point.type_filters += /mob/living

/// Calculates the next interaction point the manipulator should transfer the item to. If returns `NONE`, awaits one full cycle.
/obj/machinery/big_manipulator/proc/find_next_point(tasking_type, transfer_type)
	if(!tasking_type)
		tasking_type = TASKING_PREFER_FIRST

	if(!transfer_type)
		return NONE

	var/list/interaction_points = transfer_type == TRANSFER_TYPE_DROPOFF ? dropoff_points : pickup_points
	var/roundrobin_history = transfer_type == TRANSFER_TYPE_DROPOFF ? roundrobin_history_dropoff : roundrobin_history_pickup

	switch(tasking_type)
		if(TASKING_PREFER_FIRST)
			for(var/datum/interaction_point/this_point in interaction_points)
				if(this_point.is_available(transfer_type))
					return this_point

			return NONE

		if(TASKING_ROUND_ROBIN)
			var/datum/interaction_point/this_point = interaction_points[roundrobin_history]
			if(this_point.is_available(transfer_type))
				roundrobin_history += 1
				if(roundrobin_history > length(interaction_points))
					roundrobin_history = 1
				return this_point

			var/initial_index = roundrobin_history
			roundrobin_history += 1
			if(roundrobin_history > length(interaction_points))
				roundrobin_history = 1

			while(roundrobin_history != initial_index)
				this_point = interaction_points[roundrobin_history]
				if(this_point.is_available(transfer_type))
					roundrobin_history += 1
					if(roundrobin_history > length(interaction_points))
						roundrobin_history = 1
					return this_point

				roundrobin_history += 1
				if(roundrobin_history > length(interaction_points))
					roundrobin_history = 1
			return NONE

		if(TASKING_STRICT_ROBIN)
			var/datum/interaction_point/this_point = interaction_points[roundrobin_history]
			if(this_point.is_available(transfer_type))
				roundrobin_history += 1
				if(roundrobin_history > length(interaction_points))
					roundrobin_history = 1
				return this_point

			return NONE

/// Rotates the manipulator arm to face the target point
/obj/machinery/big_manipulator/proc/rotate_to_point(datum/interaction_point/target_point, callback)
	if(!target_point)
		return FALSE

	var/target_dir = get_dir(get_turf(src), target_point.interaction_turf)
	var/current_dir = manipulator_arm.dir
	var/angle_diff = dir2angle(target_dir) - dir2angle(current_dir)

	// normalizing the degree
	if(angle_diff > 180)
		angle_diff -= 360
	if(angle_diff < -180)
		angle_diff += 360

	// calculating the degree
	var/num_rotations = abs(angle_diff) / 45
	var/total_rotation_time = num_rotations * rotation_delay

	// animating the rotation
	animate(manipulator_arm, transform = matrix(angle_diff, MATRIX_ROTATE), time = total_rotation_time)
	manipulator_arm.dir = target_dir

	addtimer(CALLBACK(src, callback, target_point), total_rotation_time)
	return TRUE

/obj/machinery/big_manipulator/proc/try_begin_full_cycle(datum/source, atom/movable/target)
	if(!on)
		return FALSE

	if(!anchored)
		return FALSE

	if(status == STATUS_BUSY)
		return FALSE

	if(!use_energy(active_power_usage, force = FALSE))
		on = FALSE
		balloon_alert("not enough power!")
		return FALSE

	status = STATUS_BUSY
	try_run_full_cycle()

/obj/machinery/big_manipulator/proc/try_run_full_cycle()
	var/origin_point = find_next_point(pickup_tasking, TRANSFER_TYPE_PICKUP)
	if(!origin_point)
		return MOVE_CYCLE_FAIL // cycle failed - couldn't find a next point: no valid pickup points or didn't meet the filter rules

	rotate_to_point(origin_point, PROC_REF(try_interact_with_origin_point))

/obj/machinery/big_manipulator/proc/try_interact_with_destination_point(datum/interaction_point/destination_point, hand_is_empty = FALSE)
	if(!destination_point)
		return FALSE

	if(hand_is_empty)
		addtimer(CALLBACK(src, PROC_REF(use_thing_with_empty_hand)), interaction_delay SECONDS)
		return

	var/atom/target = null

	switch(destination_point.interaction_mode)
		if(INTERACT_DROP)
			addtimer(CALLBACK(src, PROC_REF(try_drop_thing), target), interaction_delay SECONDS)
		if(INTERACT_USE)
			addtimer(CALLBACK(src, PROC_REF(try_use_thing), target), interaction_delay SECONDS)
		if(INTERACT_THROW)
			addtimer(CALLBACK(src, PROC_REF(throw_thing), target), interaction_delay SECONDS)

/obj/machinery/big_manipulator/proc/try_interact_with_origin_point(datum/interaction_point/origin_point, hand_is_empty = FALSE)
	if(!origin_point)
		return FALSE

	var/turf/origin_turf = origin_point.interaction_turf
	for(var/atom/movable/movable_atom in origin_turf.contents)
		if(origin_point.check_filters_for_atom(movable_atom))
			return
			// if(try_pickup_item())
			// 		break


/obj/machinery/big_manipulator/Initialize(mapload)
	. = ..()
	create_manipulator_arm()
	RegisterSignal(manipulator_arm, COMSIG_QDELETING, PROC_REF(on_hand_qdel))
	process_upgrades()
	// set_up_priority_settings() // will be refactored - interaction data is now stored in datums
	selected_type = type_filters[1]
	if(on)
		switch_power_state(null)
	set_wires(new /datum/wires/big_manipulator(src))

	register_context()

/// Checks the component tiers, adjusting the properties of the manipulator.
/obj/machinery/big_manipulator/proc/process_upgrades()
	var/datum/stock_part/servo/locate_servo = locate() in component_parts
	if(!locate_servo)
		return

	var/manipulator_tier = locate_servo.tier
	switch(manipulator_tier)
		if(-INFINITY to 1)
			minimal_interaction_multiplier = interaction_delay = MIN_DELAY_TIER_1
			rotation_delay = MIN_DELAY_TIER_1 * 0.5
			set_greyscale(COLOR_YELLOW)
			manipulator_arm?.set_greyscale(COLOR_YELLOW)
		if(2)
			minimal_interaction_multiplier = interaction_delay = MIN_DELAY_TIER_2
			rotation_delay = MIN_DELAY_TIER_2 * 0.5
			set_greyscale(COLOR_ORANGE)
			manipulator_arm?.set_greyscale(COLOR_ORANGE)
		if(3)
			minimal_interaction_multiplier = interaction_delay = MIN_DELAY_TIER_3
			rotation_delay = MIN_DELAY_TIER_3 * 0.5
			set_greyscale(COLOR_RED)
			manipulator_arm?.set_greyscale(COLOR_RED)
		if(4 to INFINITY)
			minimal_interaction_multiplier = interaction_delay = MIN_DELAY_TIER_4
			rotation_delay = MIN_DELAY_TIER_4 * 0.5
			set_greyscale(COLOR_PURPLE)
			manipulator_arm?.set_greyscale(COLOR_PURPLE)

	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * BASE_POWER_USAGE * manipulator_tier

/obj/machinery/big_manipulator/examine(mob/user)
	. = ..()
	. += "You can change direction with alternative wrench usage."
	var/mob/monkey_resolve = monkey_worker?.resolve()
	if(!isnull(monkey_resolve))
		. += "You can see [monkey_resolve]: [src] manager."

/obj/machinery/big_manipulator/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(isnull(held_item))
		context[SCREENTIP_CONTEXT_LMB] = panel_open ? "Interact with wires" : "Open UI"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item.tool_behaviour == TOOL_WRENCH)
		context[SCREENTIP_CONTEXT_LMB] = "[anchored ? "Una" : "A"]nchor"
		context[SCREENTIP_CONTEXT_RMB] = "Rotate clockwise"
		return CONTEXTUAL_SCREENTIP_SET
	if(held_item.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Close" : "Open"] panel"
		return CONTEXTUAL_SCREENTIP_SET
	if(held_item.tool_behaviour == TOOL_CROWBAR && panel_open)
		context[SCREENTIP_CONTEXT_LMB] = "Deconstruct"
		return CONTEXTUAL_SCREENTIP_SET
	if(is_wire_tool(held_item) && panel_open)
		context[SCREENTIP_CONTEXT_LMB] = "Interact with wires"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/big_manipulator/Destroy(force)
	. = ..()
	qdel(manipulator_arm)
	if(!isnull(held_object))
		var/obj/containment_resolve = held_object?.resolve()
		containment_resolve?.forceMove(get_turf(containment_resolve))
	var/mob/monkey_resolve = monkey_worker?.resolve()
	if(!isnull(monkey_resolve))
		monkey_resolve.forceMove(get_turf(monkey_resolve))
	locked_by_this_id = null

/obj/machinery/big_manipulator/Exited(atom/movable/gone, direction)
	if(isnull(monkey_worker))
		return
	var/mob/living/carbon/human/species/monkey/poor_monkey = monkey_worker.resolve()
	if(gone != poor_monkey)
		return
	if(!is_type_in_list(poor_monkey, manipulator_arm.vis_contents))
		return
	manipulator_arm.vis_contents -= poor_monkey
	if(interaction_mode == INTERACT_USE)
		change_mode()
	poor_monkey.remove_offsets(type)
	monkey_worker = null

/obj/machinery/big_manipulator/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if(isnull(get_turf(src)))
		qdel(manipulator_arm)
		return
	if(!manipulator_arm)
		create_manipulator_arm()

/obj/machinery/big_manipulator/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	balloon_alert(user, "overloaded functions installed")
	obj_flags |= EMAGGED
	type_filters += /mob/living
	return TRUE

/obj/machinery/big_manipulator/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool, time = 1 SECONDS)
	return ITEM_INTERACT_SUCCESS

// /obj/machinery/big_manipulator/wrench_act_secondary(mob/living/user, obj/item/tool)
// 	. = ..()
// 	if(status == STATUS_BUSY || on)
// 		to_chat(user, span_warning("[src] is activated!"))
// 		return ITEM_INTERACT_BLOCKING
// 	rotate_big_hand()
// 	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
// 	return ITEM_INTERACT_SUCCESS

/obj/machinery/big_manipulator/can_be_unfasten_wrench(mob/user, silent)
	if(status == STATUS_BUSY || on)
		to_chat(user, span_warning("[src] is activated!"))
		return FAILED_UNFASTEN
	return ..()

/obj/machinery/big_manipulator/default_unfasten_wrench(mob/user, obj/item/wrench, time)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		return

/obj/machinery/big_manipulator/screwdriver_act(mob/living/user, obj/item/tool)
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, tool))
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/machinery/big_manipulator/crowbar_act(mob/living/user, obj/item/tool)
	. = ..()
	if(default_deconstruction_crowbar(tool))
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/machinery/big_manipulator/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(user.combat_mode)
		return NONE
	if(!panel_open || !is_wire_tool(tool))
		return NONE
	wires.interact(user)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/big_manipulator/RefreshParts()
	. = ..()
	process_upgrades()

/obj/machinery/big_manipulator/mouse_drop_dragged(atom/drop_point, mob/user, src_location, over_location, params)
	if(isnull(monkey_worker))
		return
	if(status == STATUS_BUSY)
		balloon_alert(user, "turn it off first!")
		return
	var/mob/living/carbon/human/species/monkey/poor_monkey = monkey_worker.resolve()
	if(isnull(poor_monkey))
		return
	balloon_alert(user, "trying unbuckle...")
	if(!do_after(user, 3 SECONDS, src))
		balloon_alert(user, "interrupted")
		return
	balloon_alert(user, "unbuckled")
	poor_monkey.drop_all_held_items()
	poor_monkey.forceMove(drop_point)

/obj/machinery/big_manipulator/mouse_drop_receive(atom/monkey, mob/user, params)
	if(!ismonkey(monkey))
		return
	if(!isnull(monkey_worker))
		return
	if(status == STATUS_BUSY)
		balloon_alert(user, "turn it off first!")
		return
	var/mob/living/carbon/human/species/monkey/poor_monkey = monkey
	if(poor_monkey.mind)
		balloon_alert(user, "too smart!")
		return
	poor_monkey.balloon_alert(user, "trying buckle...")
	if(!do_after(user, 3 SECONDS, poor_monkey))
		poor_monkey.balloon_alert(user, "interrupted")
		return
	balloon_alert(user, "buckled")
	monkey_worker = WEAKREF(poor_monkey)
	poor_monkey.drop_all_held_items()
	poor_monkey.forceMove(src)
	manipulator_arm.vis_contents += poor_monkey
	poor_monkey.dir = manipulator_arm.dir
	poor_monkey.add_offsets(
		type,
		x_add = 32 + manipulator_arm.calculate_item_offset(TRUE, pixels_to_offset = 16),
		y_add = 32 + manipulator_arm.calculate_item_offset(FALSE, pixels_to_offset = 16)
	)

/obj/machinery/big_manipulator/attackby(obj/item/is_card, mob/user, params)
	. = ..()
	if(!isidcard(is_card))
		return
	var/obj/item/card/id/clicked_by_this_id = is_card
	if(!isnull(locked_by_this_id))
		var/obj/item/card/id/resolve_id = locked_by_this_id.resolve()
		if(clicked_by_this_id != resolve_id)
			balloon_alert(user, "locked by another id")
			return
		locked_by_this_id = null
		change_id_locked_status(user)
		return
	locked_by_this_id = WEAKREF(clicked_by_this_id)
	change_id_locked_status(user)

/obj/machinery/big_manipulator/proc/change_id_locked_status(mob/user)
	id_locked = !id_locked
	balloon_alert(user, "successfully [!id_locked ? "un" : ""]locked")

/// Creat manipulator hand effect on manipulator core.
/obj/machinery/big_manipulator/proc/create_manipulator_arm()
	manipulator_arm = new/obj/effect/big_manipulator_arm(src)
	manipulator_arm.dir = NORTH
	vis_contents += manipulator_arm

/// Deliting hand will destroy our manipulator core.
/obj/machinery/big_manipulator/proc/on_hand_qdel()
	SIGNAL_HANDLER

	deconstruct(TRUE)

/// Second take and drop proc from [take and drop procs loop]:
/// Taking our item and start manipulator hand rotate animation.
/obj/machinery/big_manipulator/proc/start_work(atom/movable/target, hand_is_empty = FALSE)
	if(!hand_is_empty)
		target.forceMove(src)
		held_object = WEAKREF(target)
		manipulator_arm.update_claw(held_object)
	status = STATUS_BUSY
	do_rotate_animation(1)
	check_next_move(target, hand_is_empty)

/// Drops the item onto the turf.
/obj/machinery/big_manipulator/proc/try_drop_thing(datum/interaction_point/destination_point)
	var/drop_endpoint = destination_point.find_type_priority(override_priority)
	var/obj/actual_held_object = held_object?.resolve()

	if(isnull(drop_endpoint))
		stack_trace("Interaction point returned no turfs to transfer the item to.")
		return FALSE

	var/atom/drop_target = drop_endpoint
	if(drop_target.atom_storage && (!drop_target.atom_storage.attempt_insert(actual_held_object, override = TRUE, messages = FALSE)))
		actual_held_object.forceMove(drop_target.drop_location())
		return TRUE

	actual_held_object.forceMove(drop_endpoint)
	finish_manipulation()
	return TRUE

/// Attempts to use the held object on the target atom.
/obj/machinery/big_manipulator/proc/try_use_thing(datum/interaction_point/destination_point, atom/movable/target, hand_is_empty = FALSE)
	var/obj/obj_resolve = held_object?.resolve()
	var/mob/living/carbon/human/species/monkey/monkey_resolve = monkey_worker?.resolve()
	var/destination_turf = destination_point.interaction_turf

	if(!obj_resolve || !monkey_resolve) // if something that's supposed to be here is not here anymore
		finish_manipulation()
		return FALSE

	if(!(obj_resolve.loc == src && obj_resolve.loc == monkey_resolve)) // if we don't hold the said item or the monkey isn't buckled
		finish_manipulation()
		return FALSE

	var/obj/item/held_item = obj_resolve
	var/atom/type_to_use = destination_point.find_type_priority(override_priority)

	if(isnull(type_to_use))
		check_for_cycle_end_drop(destination_point, FALSE)
		return FALSE

	monkey_resolve.put_in_active_hand(held_item)
	if(held_item.GetComponent(/datum/component/two_handed))
		held_item.attack_self(monkey_resolve)

	held_item.melee_attack_chain(monkey_resolve, type_to_use)
	do_attack_animation(destination_turf)
	manipulator_arm.do_attack_animation(destination_turf)

	check_for_cycle_end_drop(destination_point, TRUE)

/// Checks if we should continue using the empty hand after interaction
/obj/machinery/big_manipulator/proc/check_end_of_use_for_use_with_empty_hand(datum/interaction_point/destination_point, item_was_used = TRUE)
	if(!on || (worker_interaction != WORKER_EMPTY_USE && interaction_mode == INTERACT_USE))
		finish_manipulation()
		return

	if(!item_was_used)
		finish_manipulation()
		return

	addtimer(CALLBACK(src, PROC_REF(use_thing_with_empty_hand), destination_point), interaction_delay SECONDS)

/// Uses the empty hand to interact with objects
/obj/machinery/big_manipulator/proc/use_thing_with_empty_hand(datum/interaction_point/destination_point)
	var/mob/living/carbon/human/species/monkey/monkey_resolve = monkey_worker?.resolve()
	if(isnull(monkey_resolve))
		finish_manipulation()
		return

	var/atom/type_to_use = destination_point.find_type_priority(override_priority)
	if(isnull(type_to_use))
		check_end_of_use_for_use_with_empty_hand(destination_point, FALSE)
		return

	// we don't do unarmed attack on items because we will take them
	if(isitem(type_to_use))
		var/obj/item/interact_with_item = type_to_use
		var/resolve_loc = interact_with_item.loc
		monkey_resolve.put_in_active_hand(interact_with_item)
		interact_with_item.attack_self(monkey_resolve)
		interact_with_item.forceMove(resolve_loc)
	else
		monkey_resolve.UnarmedAttack(type_to_use)

	do_attack_animation(destination_point.interaction_turf)
	manipulator_arm.do_attack_animation(destination_point.interaction_turf)
	check_end_of_use_for_use_with_empty_hand(destination_point, TRUE)

/// Checks what should we do with the `held_object` after `USE`-ing it.
/obj/machinery/big_manipulator/proc/check_for_cycle_end_drop(datum/interaction_point/drop_point, item_used = TRUE)
	var/obj/obj_resolve = held_object.resolve()
	var/turf/drop_turf = drop_point.interaction_turf

	if(worker_interaction == WORKER_SINGLE_USE && item_used)
		obj_resolve.forceMove(drop_turf)
		obj_resolve.dir = get_dir(get_turf(obj_resolve), get_turf(src))
		finish_manipulation()
		return

	if(!on || drop_point.interaction_mode != INTERACT_USE)
		finish_manipulation()
		return

	if(item_used)
		addtimer(CALLBACK(src, PROC_REF(try_use_thing), drop_point), interaction_delay SECONDS)
		return

	finish_manipulation()

/// 3.3 take and drop proc from [take and drop procs loop]:
/// Throw item away!!!
/obj/machinery/big_manipulator/proc/throw_thing(atom/movable/target)
	if(!(isitem(target) || isliving(target)))
		target.forceMove(drop_turf)
		target.dir = get_dir(get_turf(target), get_turf(src))
		finish_manipulation()  /// We throw only items and living mobs
		return
	var/obj/item/im_item = target
	im_item.forceMove(drop_turf)
	// im_item.throw_at(get_edge_target_turf(get_turf(src), drop_here), manipulator_throw_range - 1, 2)
	src.do_attack_animation(drop_turf)
	manipulator_arm.do_attack_animation(drop_turf)
	finish_manipulation()

/// End of thirds take and drop proc from [take and drop procs loop]:
/// Starts manipulator hand backward animation.
/obj/machinery/big_manipulator/proc/finish_manipulation()
	held_object = null
	manipulator_arm.update_claw(null)
	do_rotate_animation(0)
	addtimer(CALLBACK(src, PROC_REF(end_work)), interaction_delay SECONDS)

/// Fourth and last take and drop proc from [take and drop procs loop]:
/// Finishes work and begins to look for a new item for [take and drop procs loop].
/obj/machinery/big_manipulator/proc/end_work()
	status = STATUS_IDLE
	if(!on)
		return

	for(var/datum/interaction_point/pickup_point in pickup_points)
		if(pickup_point.is_available(interaction_mode))
			try_begin_full_cycle()
			return

/// Rotates manipulator hand 90 degrees.
/obj/machinery/big_manipulator/proc/do_rotate_animation(backward)
	animate(manipulator_arm, transform = matrix(90, MATRIX_ROTATE), interaction_delay SECONDS * 0.5)
	addtimer(CALLBACK(src, PROC_REF(finish_rotate_animation), backward), interaction_delay SECONDS * 0.5)

/// Rotates manipulator hand from 90 degrees to 180 or 0 if backward.
/obj/machinery/big_manipulator/proc/finish_rotate_animation(backward)
	animate(manipulator_arm, transform = matrix(180 * backward, MATRIX_ROTATE), interaction_delay SECONDS * 0.5)

/obj/machinery/big_manipulator/proc/check_filter(atom/movable/target)
	if (target.anchored || HAS_TRAIT(target, TRAIT_NODROP))
		return FALSE
	if(!istype(target, selected_type))
		return FALSE
	/// We use filter only on items. closets, humans and etc don't need filter check.
	if(!isitem(target))
		return TRUE
	var/obj/item/target_item = target
	if (target_item.item_flags & (ABSTRACT|DROPDEL))
		return FALSE
	return TRUE

/// Proc called when we changing item interaction mode.
/obj/machinery/big_manipulator/proc/change_mode()
	var/list/available_modes = list(INTERACT_DROP, INTERACT_USE, INTERACT_THROW)

	if(isnull(monkey_worker))
		available_modes = list(INTERACT_DROP, INTERACT_THROW)

	interaction_mode = cycle_value(interaction_mode, available_modes)
	is_ready_to_work()

/obj/machinery/big_manipulator/proc/switch_power_state(mob/user)
	var/new_power_state = !on

	if(!user)
		on = new_power_state
		return

	if(new_power_state)
		if(!powered())
			balloon_alert(user, "no power!")
			return

		if(!anchored)
			balloon_alert(user, "anchor first!")
			return

		validate_all_points()

		for(var/datum/interaction_point/point in pickup_points)
			var/turf/pickup_turf = point.interaction_turf
			RegisterSignal(pickup_turf, COMSIG_ATOM_ENTERED, PROC_REF(try_begin_full_cycle))
			RegisterSignal(pickup_turf, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, PROC_REF(try_begin_full_cycle))

	else
		for(var/datum/interaction_point/point in pickup_points)
			var/turf/pickup_turf = point.interaction_turf
			UnregisterSignal(pickup_turf, COMSIG_ATOM_ENTERED)
			UnregisterSignal(pickup_turf, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON)

		drop_held_object()

	on = new_power_state

/obj/machinery/big_manipulator/proc/validate_all_points()
	for(var/datum/interaction_point/point in pickup_points)
		if(!point.is_valid())
			pickup_points.Remove(point)

	for(var/datum/interaction_point/point in dropoff_points)
		if(!point.is_valid())
			dropoff_points.Remove(point)


/// Proc that check if button not cutted when we press on button.
/obj/machinery/big_manipulator/proc/try_press_on(mob/user)
	if(power_access_wire_cut)
		balloon_alert(user, "unresponsive!")
		return
	switch_power_state(user)

/// Drop item that manipulator is manipulating.
/obj/machinery/big_manipulator/proc/drop_held_object()
	if(isnull(held_object))
		return
	var/obj/obj_resolve = held_object?.resolve()
	obj_resolve?.forceMove(get_turf(obj_resolve))
	finish_manipulation()

/// Changes manipulator working speed time.
/obj/machinery/big_manipulator/proc/change_delay(new_delay)
	interaction_delay = round(clamp(new_delay, minimal_interaction_multiplier, MAX_DELAY), DELAY_STEP)

/obj/machinery/big_manipulator/ui_interact(mob/user, datum/tgui/ui)
	if(id_locked)
		to_chat(user, span_warning("[src] is locked behind id authentication!"))
		ui?.close()
		return
	if(!anchored)
		to_chat(user, span_warning("[src] isn't attached to the ground!"))
		ui?.close()
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BigManipulator")
		ui.open()

/obj/machinery/big_manipulator/ui_data(mob/user)
	var/list/data = list()
	data["active"] = on
	data["selected_type"] = selected_type.name
	data["interaction_mode"] = interaction_mode
	data["worker_interaction"] = worker_interaction
	data["highest_priority"] = override_priority
	data["throw_range"] = manipulator_throw_range
	var/list/priority_list = list()
	data["settings_list"] = list()
	for(var/datum/interaction_point/point in pickup_points)
		for(var/datum/manipulator_priority/priority in point.get_sorted_priorities())
			var/list/priority_data = list()
			priority_data["name"] = priority.name
			priority_data["priority_width"] = priority.number
			priority_list += list(priority_data)
	data["settings_list"] = priority_list
	data["min_delay"] = minimal_interaction_multiplier
	data["interaction_delay"] = interaction_delay
	return data

/obj/machinery/big_manipulator/ui_static_data(mob/user)
	var/list/data = list()
	data["delay_step"] = DELAY_STEP
	data["max_delay"] = MAX_DELAY
	return data

/obj/machinery/big_manipulator/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	switch(action)
		if("on")
			try_press_on(ui.user)
			return TRUE
		if("drop")
			drop_held_object()
			return TRUE
		if("change_take_item_type")
			cycle_pickup_type()
			return TRUE
		if("change_mode")
			change_mode()
			return TRUE
		if("highest_priority_change")
			override_priority = !override_priority
			return TRUE
		if("worker_interaction_change")
			cycle_worker_interaction()
			return TRUE
		if("change_priority")
			var/new_priority_number = params["priority"]
			for(var/datum/interaction_point/point in pickup_points)
				for(var/datum/manipulator_priority/priority in point.interaction_priorities)
					if(priority.number == new_priority_number)
						point.update_priority(priority, new_priority_number - 1)
						break
			return TRUE
		if("cycle_throw_range")
			cycle_throw_range()
			return TRUE
		if("changeDelay")
			change_delay(text2num(params["new_delay"]))
			return TRUE

/// Using on change_priority: looks for a setting with the same number that we set earlier and reduce it.
/obj/machinery/big_manipulator/proc/check_similarities(number_we_minus)
	for(var/datum/manipulator_priority/similarities as anything in allowed_priority_settings)
		if(similarities.number != number_we_minus)
			continue
		similarities.number++
		break

/// Cycles the given value in the given list. Retuns the next value in the list, or the first one if the list isn't long enough.
/obj/machinery/big_manipulator/proc/cycle_value(current_value, list/possible_values)
	var/current_index = possible_values.Find(current_value)
	if(current_index == null)
		return possible_values[1]

	var/next_index = (current_index % possible_values.len) + 1
	return possible_values[next_index]

/obj/machinery/big_manipulator/proc/cycle_worker_interaction()
	var/list/worker_modes = list(WORKER_NORMAL_USE, WORKER_SINGLE_USE, WORKER_EMPTY_USE)
	worker_interaction = cycle_value(worker_interaction, worker_modes)

/obj/machinery/big_manipulator/proc/cycle_throw_range()
	var/list/possible_ranges = list(1, 2, 3, 4, 5, 6, 7)
	manipulator_throw_range = cycle_value(manipulator_throw_range, possible_ranges)

/obj/machinery/big_manipulator/proc/cycle_pickup_type()
	selected_type = cycle_value(selected_type, type_filters)
	is_ready_to_work()
