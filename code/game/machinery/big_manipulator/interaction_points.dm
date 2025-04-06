/datum/interaction_point
	var/name = "interaction point"

	/// The turf this interaction point represents.
	var/turf/interaction_turf
	/// Should we check our filters while interacting with this point?
	var/filters_status = FILTERS_SKIPPED
	/// How should this point be interacted with?
	var/interaction_mode = INTERACT_DROP
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

/datum/interaction_point/New(turf/new_turf, list/new_filters, new_filters_status, new_interaction_mode)
	if(!new_turf)
		stack_trace("New manipulator interaction point created with no valid turf references passed.")
		return FALSE

	if(isclosedturf(new_turf))
		return FALSE

	interaction_turf = new_turf

	if(length(new_filters))
		atom_filters = new_filters

	if(new_filters_status)
		filters_status = new_filters_status

	if(new_interaction_mode)
		interaction_mode = new_interaction_mode

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

/datum/interaction_point/proc/is_available()
	if(!is_valid())
		return FALSE

	if(filters_status == FILTERS_SKIPPED)
		return TRUE

	for(var/atom/this_atom in interaction_turf)
		if(this_atom in atom_filters)
			return FALSE

	return TRUE

/datum/interaction_point/proc/is_valid()
	if(!interaction_turf)
		return FALSE

	if(isclosedturf(interaction_turf))
		return FALSE

	return TRUE

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


