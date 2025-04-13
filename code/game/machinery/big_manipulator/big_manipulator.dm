/// The Big Manipulator's core. Main part of the mechanism that carries out the entire process.
/obj/machinery/big_manipulator
	name = "big manipulator"
	desc = "Operates different objects. Truly, a groundbreaking innovation..."
	icon = 'icons/obj/machines/big_manipulator_parts/big_manipulator_core.dmi'
	icon_state = "core"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/big_manipulator
	greyscale_colors = "#d8ce13"
	greyscale_config = /datum/greyscale_config/big_manipulator

	/// Min time manipulator can have in delay. Changing on upgrade.
	var/minimal_interaction_multiplier = MIN_ROTATION_MULTIPLIER_TIER_1
	/// Base interaction delay (between repeating actions and adjacent points)
	var/interaction_delay = BASE_INTERACTION_TIME * STARTING_MULTIPLIER
	/// The interaction time modifier - faster to slower.
	var/interaction_multiplier = STARTING_MULTIPLIER

	/// The status of the manipulator - `IDLE` or `BUSY`.
	var/status = STATUS_IDLE
	/// Is the manipulator turned on?
	var/on = FALSE

	/// Время начала текущей задачи
	var/current_task_start_time = 0
	/// Общее время выполнения текущей задачи
	var/current_task_duration = 0
	/// Тип текущей задачи (для UI)
	var/current_task_type = "idle"

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

/obj/machinery/big_manipulator/proc/find_suitable_turf()
	var/turf/center = get_turf(src)
	if(!center)
		return null

	var/turf/north = get_step(center, NORTH)
	if(north && !isclosedturf(north))
		return north

	var/list/directions = list(EAST, SOUTH, WEST, NORTHWEST, SOUTHWEST, SOUTHEAST, NORTHEAST)
	for(var/dir in directions)
		var/turf/check = get_step(center, dir)
		if(check && !isclosedturf(check))
			return check

	return null

/obj/machinery/big_manipulator/proc/create_new_interaction_point(turf/new_turf, list/new_filters, new_filters_status, new_interaction_mode, transfer_type)
	if(!new_turf)
		new_turf = find_suitable_turf()
		if(!new_turf)
			balloon_alert(usr, "no suitable turfs found!")
			return FALSE

	var/datum/interaction_point/new_interaction_point = new(new_turf, new_filters, new_filters_status, new_interaction_mode)

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
	if(!length(pickup_points) || !length(dropoff_points))
		balloon_alert(usr, "no points!")
		return NONE

	if(!tasking_type)
		tasking_type = TASKING_PREFER_FIRST

	if(!transfer_type)
		return NONE

	var/list/interaction_points = transfer_type == TRANSFER_TYPE_DROPOFF ? dropoff_points : pickup_points
	var/roundrobin_history = transfer_type == TRANSFER_TYPE_DROPOFF ? roundrobin_history_dropoff : roundrobin_history_pickup

	// Проверяем, есть ли хотя бы одна точка с подходящими объектами
	var/has_available_points = FALSE
	for(var/datum/interaction_point/point in interaction_points)
		if(point.is_available(transfer_type))
			has_available_points = TRUE
			break

	if(!has_available_points)
		return NONE

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

			if(status == STATUS_BUSY)
				addtimer(CALLBACK(src, PROC_REF(try_begin_full_cycle)), CYCLE_SKIP_TIMEOUT)
			return NONE

/// Rotates the manipulator arm to face the target point
/obj/machinery/big_manipulator/proc/rotate_to_point(datum/interaction_point/target_point, callback)
	if(!target_point)
		return FALSE

	var/target_dir = get_dir(get_turf(src), target_point.interaction_turf)
	var/current_dir = manipulator_arm.dir
	var/angle_diff = dir2angle(target_dir) - dir2angle(current_dir)

	if(angle_diff > 180)
		angle_diff -= 360
	if(angle_diff < -180)
		angle_diff += 360

	var/num_rotations = abs(angle_diff) / 45
	var/total_rotation_time = num_rotations * interaction_delay

	start_task("rotate", total_rotation_time)
	animate(manipulator_arm, transform = matrix(angle_diff, MATRIX_ROTATE), time = total_rotation_time)
	manipulator_arm.dir = target_dir

	addtimer(CALLBACK(src, PROC_REF(end_task)), total_rotation_time)
	addtimer(CALLBACK(src, callback, target_point), total_rotation_time)
	return TRUE

/obj/machinery/big_manipulator/proc/try_begin_full_cycle()
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
	var/datum/interaction_point/origin_point = find_next_point(pickup_tasking, TRANSFER_TYPE_PICKUP)
	if(!origin_point)
		status = STATUS_IDLE
		SStgui.update_uis(src)
		addtimer(CALLBACK(src, PROC_REF(try_begin_full_cycle)), CYCLE_SKIP_TIMEOUT)
		return FALSE

	var/turf/origin_turf = origin_point.interaction_turf
	var/has_suitable_objects = FALSE
	for(var/atom/movable/movable_atom in origin_turf.contents)
		if(origin_point.check_filters_for_atom(movable_atom))
			has_suitable_objects = TRUE
			break

	if(!has_suitable_objects)
		balloon_alert(usr, "skipping one full cycle")
		status = STATUS_IDLE
		SStgui.update_uis(src)
		addtimer(CALLBACK(src, PROC_REF(try_begin_full_cycle)), CYCLE_SKIP_TIMEOUT)
		return FALSE

	rotate_to_point(origin_point, PROC_REF(try_interact_with_origin_point))
	return TRUE

/obj/machinery/big_manipulator/proc/try_interact_with_destination_point(datum/interaction_point/destination_point, hand_is_empty = FALSE)
	if(!destination_point)
		return FALSE

	if(hand_is_empty)
		use_thing_with_empty_hand(destination_point)
		return TRUE

	switch(destination_point.interaction_mode)
		if(INTERACT_DROP)
			try_drop_thing(destination_point)
		if(INTERACT_USE)
			try_use_thing(destination_point)
		if(INTERACT_THROW)
			throw_thing(destination_point)

	// После взаимодействия ищем следующую точку
	var/datum/interaction_point/next_point = find_next_point(pickup_tasking, TRANSFER_TYPE_PICKUP)
	if(next_point)
		rotate_to_point(next_point, PROC_REF(try_interact_with_origin_point))
	else
		status = STATUS_IDLE
	return TRUE

/obj/machinery/big_manipulator/proc/try_interact_with_origin_point(datum/interaction_point/origin_point, hand_is_empty = FALSE)
	if(!origin_point)
		return FALSE

	var/turf/origin_turf = origin_point.interaction_turf
	for(var/atom/movable/movable_atom in origin_turf.contents)
		if(origin_point.check_filters_for_atom(movable_atom))
			start_work(movable_atom, hand_is_empty)
			return TRUE

	// Если не нашли подходящий объект, ждем следующего цикла
	balloon_alert(usr, "skipping one full cycle")
	status = STATUS_IDLE
	addtimer(CALLBACK(src, PROC_REF(try_begin_full_cycle)), CYCLE_SKIP_TIMEOUT)
	return FALSE

/obj/machinery/big_manipulator/Initialize(mapload)
	. = ..()
	create_manipulator_arm()
	RegisterSignal(manipulator_arm, COMSIG_QDELETING, PROC_REF(on_hand_qdel))
	process_upgrades()
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
			minimal_interaction_multiplier = MIN_ROTATION_MULTIPLIER_TIER_1
			interaction_delay = BASE_INTERACTION_TIME * MIN_ROTATION_MULTIPLIER_TIER_1
			set_greyscale(COLOR_YELLOW)
			manipulator_arm?.set_greyscale(COLOR_YELLOW)
		if(2)
			minimal_interaction_multiplier = MIN_ROTATION_MULTIPLIER_TIER_2
			interaction_delay = BASE_INTERACTION_TIME * MIN_ROTATION_MULTIPLIER_TIER_2
			set_greyscale(COLOR_ORANGE)
			manipulator_arm?.set_greyscale(COLOR_ORANGE)
		if(3)
			minimal_interaction_multiplier = MIN_ROTATION_MULTIPLIER_TIER_3
			interaction_delay = BASE_INTERACTION_TIME * MIN_ROTATION_MULTIPLIER_TIER_3
			set_greyscale(COLOR_RED)
			manipulator_arm?.set_greyscale(COLOR_RED)
		if(4 to INFINITY)
			minimal_interaction_multiplier = MIN_ROTATION_MULTIPLIER_TIER_4
			interaction_delay = BASE_INTERACTION_TIME * MIN_ROTATION_MULTIPLIER_TIER_4
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
	try_interact_with_origin_point(target, hand_is_empty)

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

/// Throwing the held object in the direction of the drop point.
/obj/machinery/big_manipulator/proc/throw_thing(datum/interaction_point/drop_point, atom/movable/target)
	var/drop_turf = drop_point.interaction_turf
	var/throw_range = drop_point.throw_range

	if((!(isitem(target) || isliving(target))) && !emagged)
		target.forceMove(drop_turf)
		target.dir = get_dir(get_turf(target), get_turf(src))
		finish_manipulation()
		return

	var/obj/object_to_throw = target
	object_to_throw.forceMove(drop_turf)
	object_to_throw.throw_at(get_edge_target_turf(get_turf(src), drop_turf), throw_range, 2)
	do_attack_animation(drop_turf)
	manipulator_arm.do_attack_animation(drop_turf)
	finish_manipulation()

/// Completes the current manipulation action
/obj/machinery/big_manipulator/proc/finish_manipulation()
	held_object = null
	manipulator_arm.update_claw(null)
	addtimer(CALLBACK(src, PROC_REF(end_work)), interaction_delay SECONDS)

/// Completes the work cycle and prepares for the next one
/obj/machinery/big_manipulator/proc/end_work()
	status = STATUS_IDLE
	if(!on)
		return

	for(var/datum/interaction_point/pickup_point in pickup_points)
		if(pickup_point.is_available(interaction_mode))
			try_begin_full_cycle()
			return

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

		on = new_power_state
		SStgui.update_uis(src)
		try_begin_full_cycle()

	else
		for(var/datum/interaction_point/point in pickup_points)
			var/turf/pickup_turf = point.interaction_turf
			UnregisterSignal(pickup_turf, COMSIG_ATOM_ENTERED)
			UnregisterSignal(pickup_turf, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON)

		drop_held_object()
		on = new_power_state
		SStgui.update_uis(src)

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
	if(on)
		balloon_alert(user, "activated")
	else
		balloon_alert(user, "deactivated")

/// Drop item that manipulator is manipulating.
/obj/machinery/big_manipulator/proc/drop_held_object()
	if(isnull(held_object))
		return
	var/obj/obj_resolve = held_object?.resolve()
	obj_resolve?.forceMove(get_turf(obj_resolve))
	finish_manipulation()

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
	data["selected_type"] = selected_type
	data["interaction_mode"] = interaction_mode
	data["worker_interaction"] = worker_interaction
	data["highest_priority"] = override_priority
	data["throw_range"] = manipulator_throw_range
	data["current_task_type"] = current_task_type
	data["current_task_duration"] = current_task_duration
	data["min_delay"] = minimal_interaction_multiplier
	data["manipulator_position"] = "[x],[y]"

	var/list/pickup_points_data = list()
	for(var/datum/interaction_point/point in pickup_points)
		var/list/point_data = list()
		point_data["name"] = point.name
		point_data["turf"] = "[point.interaction_turf.x],[point.interaction_turf.y]"
		point_data["mode"] = "PICK"
		point_data["filters"] = point.type_filters
		point_data["item_filters"] = point.atom_filters
		pickup_points_data += list(point_data)
	data["pickup_points"] = pickup_points_data

	var/list/dropoff_points_data = list()
	for(var/datum/interaction_point/point in dropoff_points)
		var/list/point_data = list()
		point_data["name"] = point.name
		point_data["turf"] = "[point.interaction_turf.x],[point.interaction_turf.y]"
		point_data["mode"] = point.interaction_mode
		point_data["filters"] = point.type_filters
		point_data["item_filters"] = point.atom_filters
		dropoff_points_data += list(point_data)
	data["dropoff_points"] = dropoff_points_data

	var/list/priority_list = list()
	for(var/datum/interaction_point/point in pickup_points)
		for(var/datum/manipulator_priority/priority in point.get_sorted_priorities())
			var/list/priority_data = list()
			priority_data["name"] = priority.name
			priority_data["priority_width"] = priority.number
			priority_list += list(priority_data)
	data["settings_list"] = priority_list

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
			SStgui.update_uis(src)
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
		if("change_throw_range")
			cycle_throw_range()
			return TRUE
		if("create_pickup_point")
			create_new_interaction_point(null, null, null, null, TRANSFER_TYPE_PICKUP)
			return TRUE
		if("create_dropoff_point")
			create_new_interaction_point(null, null, null, null, TRANSFER_TYPE_DROPOFF)
			return TRUE
		if("move_point")
			var/index = params["index"]
			var/dx = text2num(params["dx"])
			var/dy = text2num(params["dy"])

			var/list/all_points = pickup_points + dropoff_points
			if(index < 1 || index > length(all_points))
				return FALSE

			var/datum/interaction_point/point = all_points[index]
			var/turf/new_turf = locate(x + dx, y + dy, z)

			if(!new_turf || isclosedturf(new_turf))
				message_admins("Failed to move: new turf is [new_turf ? "closed" : "null"]")
				return FALSE

			point.interaction_turf = new_turf
			message_admins("Moved point to [new_turf.x],[new_turf.y]")
			return TRUE
		if("change_pickup_type")
			var/index = params["index"]
			if(index < 1 || index > length(pickup_points))
				return FALSE
			var/datum/interaction_point/point = pickup_points[index]
			point.filtering_mode = cycle_value(point.filtering_mode, list(TAKE_ITEMS, TAKE_CLOSETS, TAKE_HUMANS))
			return TRUE
		if("toggle_item_filter")
			var/index = params["index"]
			var/list/all_points = pickup_points + dropoff_points
			if(index < 1 || index > length(all_points))
				return FALSE
			var/datum/interaction_point/point = all_points[index]
			point.atom_filters = list()
			return TRUE
		if("toggle_filters_skip")
			var/index = params["index"]
			if(index < 1 || index > length(pickup_points))
				return FALSE
			var/datum/interaction_point/point = pickup_points[index]
			point.filters_status = !point.filters_status
			return TRUE
		if("change_dropoff_mode")
			var/index = params["index"]
			if(index < 1 || index > length(dropoff_points))
				return FALSE
			var/datum/interaction_point/point = dropoff_points[index]
			point.interaction_mode = cycle_value(point.interaction_mode, list(INTERACT_DROP, INTERACT_USE, INTERACT_THROW))
			return TRUE
		if("toggle_overflow")
			var/index = params["index"]
			if(index < 1 || index > length(dropoff_points))
				return FALSE
			var/datum/interaction_point/point = dropoff_points[index]
			// Здесь можно добавить логику для переполнения, если она нужна
			return TRUE
		if("toggle_dropoff_filters")
			var/index = params["index"]
			if(index < 1 || index > length(dropoff_points))
				return FALSE
			var/datum/interaction_point/point = dropoff_points[index]
			point.atom_filters = list()
			return TRUE

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
	SStgui.update_uis(src)

/// Начинает новую задачу с указанной длительностью
/obj/machinery/big_manipulator/proc/start_task(task_type, duration)
	current_task_start_time = world.time
	current_task_duration = duration
	current_task_type = task_type

/// Завершает текущую задачу
/obj/machinery/big_manipulator/proc/end_task()
	current_task_start_time = 0
	current_task_duration = 0
	current_task_type = "idle"
