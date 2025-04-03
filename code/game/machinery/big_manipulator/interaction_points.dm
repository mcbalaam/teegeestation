#define INTERACT_DROP "drop"
#define INTERACT_USE "use"
#define INTERACT_THROW "throw"

#define TAKE_ITEMS 1
#define TAKE_CLOSETS 2
#define TAKE_HUMANS 3

#define DELAY_STEP 0.1
#define MAX_DELAY 30

#define MIN_DELAY_TIER_1 2
#define MIN_DELAY_TIER_2 1.4
#define MIN_DELAY_TIER_3 0.8
#define MIN_DELAY_TIER_4 0.2

#define STATUS_BUSY TRUE
#define STATUS_IDLE FALSE

#define WORKER_SINGLE_USE "single"
#define WORKER_EMPTY_USE "empty"
#define WORKER_NORMAL_USE "normal"

// #define FILTERS_REQUIRED TRUE
// #define FILTERS_SKIPPED FALSE

// #define TASKING_ROUND_ROBIN "ROUND-ROBIN"
// #define TASKING_STRICT_ROBIN "STRICT R-R"
// #define TASKING_PREFER_FIRST "PREFER FIRST"

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


