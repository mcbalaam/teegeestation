/datum/interaction_point
	var/name = "interaction point"

	/// The turf this interaction point represents.
	var/turf/interaction_turf
	/// Should we check our filters while interacting with this point?
	var/filters_status = FILTERS_SKIPPED
	/// How should this point be interacted with?
	var/interaction_mode = INTERACT_DROP
	/// How far should the manipulator throw the object?
	var/throw_range = 1
	/***
	Which items are supposed to be picked up from `interaction_turf` if this is a pickup point \
	or looked for in the `interaction_turf` if this is a dropoff point.
	***/
	var/list/atom_filters = list()
	/***
	If this is a dropoff point, influences which interaction endpoints are preferred over which
	by the manipulator.
	***/
	var/list/interaction_priorities = list()
	/// Which object category should the filters be looking out for.
	var/filtering_mode = TAKE_ITEMS
	/// List of types that can be picked up from this point
	var/list/type_filters = list(
		/obj/item,
		/obj/structure/closet,
	)

/datum/interaction_point/New(turf/new_turf, list/new_filters, new_filters_status, new_interaction_mode, new_allowed_types)
	if(!new_turf)
		stack_trace("New manipulator interaction point created with no valid turf references passed.")
		qdel(src)
		return

	if(isclosedturf(new_turf))
		qdel(src)
		return

	interaction_turf = new_turf

	if(length(new_filters))
		atom_filters = new_filters

	if(new_filters_status)
		filters_status = new_filters_status

	if(new_interaction_mode)
		interaction_mode = new_interaction_mode

	if(new_allowed_types)
		type_filters = new_allowed_types

	interaction_priorities = fill_priority_list()

/datum/interaction_point/proc/find_type_priority(override = FALSE)
	var/lazy_counter = 1
	for(var/datum/manipulator_priority/take_type in interaction_priorities)
		if(lazy_counter > 1 && override)
			return null

		if(take_type.what_type == /turf)
			return interaction_turf

		lazy_counter++

		for(var/type_in_priority in interaction_turf.contents)
			if(!istype(type_in_priority, take_type.what_type))
				continue
			return type_in_priority

/// Checks if the interaction point is available - if it has items that can be interacted with.
/datum/interaction_point/proc/is_available(interaction_mode)
	if(!is_valid())
		return FALSE

	if(filters_status == FILTERS_SKIPPED)
		return TRUE

	for(var/atom/this_atom in interaction_turf)
		if(this_atom in atom_filters)
			return interaction_mode == INTERACT_DROP ? FALSE : TRUE

	return TRUE

/// Checks if the interaction point is valid.
/datum/interaction_point/proc/is_valid()
	if(!interaction_turf)
		return FALSE

	if(isclosedturf(interaction_turf))
		return FALSE

	return TRUE

/// Checks if the passed movable `atom` fits the filters.
/datum/interaction_point/proc/check_filters_for_atom(atom/movable/target)
	if(!target || target.anchored || HAS_TRAIT(target, TRAIT_NODROP))
		return FALSE

	switch(filtering_mode)
		if(TAKE_CLOSETS)
			return iscloset(target)

		if(TAKE_HUMANS)
			return ishuman(target)

		if(TAKE_ITEMS)
			return target in atom_filters

	return FALSE

/// Fills the interaction endpoint priority list for the current interaction mode.
/datum/interaction_point/proc/fill_priority_list()
	var/list/priorities_to_set = list()
	switch(interaction_mode)
		if(INTERACT_DROP)
			priorities_to_set = list(
				/datum/manipulator_priority/for_drop/on_floor,
				/datum/manipulator_priority/for_drop/in_storage,
				)
		if(INTERACT_USE)
			priorities_to_set = list(
				/datum/manipulator_priority/for_use/on_living,
				/datum/manipulator_priority/for_use/on_structure,
				/datum/manipulator_priority/for_use/on_machinery,
				/datum/manipulator_priority/for_use/on_items,
				)

	return length(priorities_to_set) ? priorities_to_set : list()

/// Updates priority of a specific setting and adjusts other priorities accordingly
/datum/interaction_point/proc/update_priority(datum/manipulator_priority/target_priority, new_priority)
	if(!target_priority || !(target_priority in interaction_priorities))
		return FALSE

	var/old_priority = target_priority.number
	target_priority.number = new_priority

	// adjusting other priorities to avoid conflicts
	for(var/datum/manipulator_priority/other_priority in interaction_priorities)
		if(other_priority == target_priority)
			continue
		if(other_priority.number == new_priority)
			other_priority.number = old_priority
			break

	return TRUE

/// Gets the current priority list sorted by priority number
/datum/interaction_point/proc/get_sorted_priorities()
	var/list/sorted = interaction_priorities.Copy()
	sortTim(sorted, GLOBAL_PROC_REF(cmp_numeric_asc))
	return sorted
