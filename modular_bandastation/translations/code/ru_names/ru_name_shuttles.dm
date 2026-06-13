/datum/map_template/shuttle
	var/list/ru_names

/datum/map_template/shuttle/New()
	shuttle_id = "[port_id]_[suffix]"
	mappath = "[prefix][shuttle_id].dmm"
	. = ..()
	ru_names = ru_names_toml(name)

/datum/map_template/shuttle/declent_ru(declent)
	. = name
	if(declent == "gender")
		. = NEUTER
	if(!length(ru_names) || ru_names["base"] != name)
		return .
	return get_declented_value(ru_names, declent, .)
