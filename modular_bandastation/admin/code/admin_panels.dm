#define WHERE_FLOOR_BELOW_MOB "Current location"
#define WHERE_SUPPLY_BELOW_MOB "Current location (droppod)"
#define WHERE_MOB_HAND "In own mob's hand"
#define WHERE_MARKED_OBJECT "At a marked object"

#define WHERE_TARGETED_LOCATION "Targeted location"
#define WHERE_TARGETED_LOCATION_POD "Targeted location (droppod)"
#define WHERE_TARGETED_MOB_HAND "In targeted mob's hand"
#define WHERE_TARGETED_MARKED_OBJECT "At a marked object"

#define PRECISE_MODE_OFF "Off"
#define PRECISE_MODE_TARGET "Target"
#define PRECISE_MODE_MARK "Mark"

#define ABSOLUTE_OFFSET "absolute"
#define RELATIVE_OFFSET "relative"

ADMIN_VERB(game_panel, R_ADMIN, "Spawn Panel", "Opens Spawn Panel (TGUI).", ADMIN_CATEGORY_GAME)
	if (!usr.client.holder.gamepanel_tgui)
		usr.client.holder.gamepanel_tgui = new(usr.client)
	usr.client.holder.gamepanel_tgui.ui_interact(usr)
	BLACKBOX_LOG_ADMIN_VERB("Spawn Panel")

/datum/admins
	var/datum/admins/gamepanel/gamepanel_tgui
	var/list/gamepanel_preferences

/datum/admins/New(list/datum/admin_rank/ranks, ckey, force_active = FALSE, protected)
	. = ..()

/datum/admins/Destroy()
	. = ..()
	qdel(gamepanel_tgui)

/datum/admins/gamepanel
	var/client/user_client
	var/where_dropdown_value = WHERE_FLOOR_BELOW_MOB
	var/selected_object = ""
	var/selected_object_icon = null
	var/selected_object_icon_state = null
	var/object_count = 1
	var/object_name
	var/dir = 1
	var/offset = ""
	var/offset_type = "relative"

	// Preferences
	var/hide_icons = FALSE
	var/hide_mappings = FALSE
	var/sort_by = "Objects"
	var/search_text = ""
	var/search_by = "type"
	var/precise_mode = FALSE

/datum/admins/gamepanel/New(user)
	if(istype(user, /client))
		var/client/temp_user_client = user
		user_client = temp_user_client
		if(user_client?.holder?.gamepanel_preferences)
			var/list/prefs = user_client.holder.gamepanel_preferences
			hide_icons = prefs["hide_icons"]
			hide_mappings = prefs["hide_mappings"]
			sort_by = prefs["sort_by"]
			search_by = prefs["search_by"]
			offset_type = prefs["offset_type"]
			offset = prefs["offset"]
			object_count = prefs["object_count"]
			dir = prefs["dir"]
			object_name = prefs["object_name"]
			where_dropdown_value = prefs["where_dropdown_value"]
			selected_object = prefs["selected_object"]
	else
		var/mob/user_mob = user
		user_client = user_mob.client
		if(user_client?.holder?.gamepanel_preferences)
			var/list/prefs = user_client.holder.gamepanel_preferences
			hide_icons = prefs["hide_icons"]
			hide_mappings = prefs["hide_mappings"]
			sort_by = prefs["sort_by"]
			search_by = prefs["search_by"]
			offset_type = prefs["offset_type"]
			offset = prefs["offset"]
			object_count = prefs["object_count"]
			dir = prefs["dir"]
			object_name = prefs["object_name"]
			where_dropdown_value = prefs["where_dropdown_value"]
			selected_object = prefs["selected_object"]

/datum/admins/gamepanel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GamePanel")
		ui.open()

/datum/admins/gamepanel/ui_close(mob/user)
	if(user_client?.holder)
		user_client.holder.gamepanel_preferences = list(
			"hide_icons" = hide_icons,
			"hide_mappings" = hide_mappings,
			"sort_by" = sort_by,
			"search_by" = search_by,
			"offset_type" = offset_type,
			"offset" = offset,
			"object_count" = object_count,
			"dir" = dir,
			"object_name" = object_name,
			"where_dropdown_value" = where_dropdown_value,
			"selected_object" = selected_object
		)
	. = ..()

/datum/admins/gamepanel/ui_state(mob/user)
	. = ..()
	return ADMIN_STATE(R_ADMIN)

/datum/admins/gamepanel/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("where-dropdown-changed")
			where_dropdown_value = params?["newWhere"]
		if("set-relative-cords")
			offset_type = RELATIVE_OFFSET
		if("set-absolute-cords")
			offset_type = ABSOLUTE_OFFSET
		if("offset-changed")
			offset = params?["newOffset"]
		if("cycle-offset-type")
			offset_type = offset_type == ABSOLUTE_OFFSET ? RELATIVE_OFFSET : ABSOLUTE_OFFSET
		if("number-changed")
			object_count = params?["newNumber"]
		if("dir-changed")
			dir = params?["newDir"]
		if("cycle_dir")
			switch(dir)
				if(1)
					dir = 2
				if(2)
					dir = 4
				if(4)
					dir = 8
				if(8)
					dir = 1
		if("name-changed")
			object_name = params?["newName"]
		if("selected-object-changed")
			selected_object = params?["newObj"]
			return TRUE
		if("create-object-action")
			spawn_item(list(
				object_list = selected_object,
				object_count = params["object_count"] ? text2num(params["object_count"]) : object_count,
				offset = params["offset"] || offset,
				object_dir = params["dir"] ? text2num(params["dir"]) : dir,
				object_name = params["object_name"] || object_name,
				object_where = params["where_dropdown_value"] ? get_dropdown_value(params["where_dropdown_value"]) : get_dropdown_value(where_dropdown_value),
				offset_type = params["offset_type"] || offset_type,
				)
			)
		if("load-new-icon")
			var/obj/object_path = text2path(selected_object)
			if(!object_path)
				return
			var/temp_object = new object_path()
			var/obj/temp_temp_object = temp_object
			selected_object_icon = temp_temp_object.icon || temp_temp_object.icon_preview
			selected_object_icon_state = temp_temp_object.icon_state || temp_temp_object.icon_state_preview
			qdel(temp_object);
		if("toggle-hide-icons")
			hide_icons = !hide_icons
			return TRUE
		if("toggle-hide-mappings")
			hide_mappings = !hide_mappings
			return TRUE
		if("set-sort-by")
			sort_by = params["new_sort_by"]
			return TRUE
		if("set-search-text")
			search_text = params["new_search_text"]
			return TRUE
		if("toggle-search-by")
			search_by = params["new_search_by"]
			return TRUE
		if("toggle-precise-mode")
			var/precise_type = params["newPreciseType"]
			toggle_precise_mode(precise_type)
			return TRUE

/datum/admins/gamepanel/proc/toggle_precise_mode(precise_type)
	precise_mode = precise_type
	updateCursor()

/datum/admins/gamepanel/proc/updateCursor()
	var/client/admin_client = usr.client
	if (!admin_client)
		return
	if (precise_mode)
		admin_client.mouse_up_icon = 'icons/effects/mouse_pointers/supplypod_pickturf.dmi'
		admin_client.mouse_down_icon = 'icons/effects/mouse_pointers/supplypod_pickturf_down.dmi'
		admin_client.mouse_override_icon = admin_client.mouse_up_icon
		admin_client.mouse_pointer_icon = admin_client.mouse_override_icon
		admin_client.click_intercept = src
	else
		var/mob/holder_mob = admin_client.mob
		admin_client.mouse_up_icon = null
		admin_client.mouse_down_icon = null
		admin_client.mouse_override_icon = null
		admin_client.click_intercept = null
		holder_mob?.update_mouse_pointer()

/datum/admins/gamepanel/proc/InterceptClickOn(user, params, atom/target)
	var/list/modifiers = params2list(params)
	var/left_click = LAZYACCESS(modifiers, LEFT_CLICK)

	if(left_click)
		if(istype(target,/atom/movable/screen))
			return FALSE

		var/turf/clicked_turf = get_turf(target)
		if(!clicked_turf)
			return FALSE

		switch(precise_mode)
			if(PRECISE_MODE_TARGET)
				var/list/spawn_params = list(
					"object_list" = selected_object,
					"object_count" = object_count,
					"offset" = "0,0,0",
					"object_dir" = dir,
					"object_name" = object_name,
					"offset_type" = "absolute"
				)

				spawn_params["object_where"] = get_dropdown_value(where_dropdown_value)

				spawn_params["X"] = clicked_turf.x
				spawn_params["Y"] = clicked_turf.y
				spawn_params["Z"] = clicked_turf.z

				spawn_item(spawn_params)
			if(PRECISE_MODE_MARK)
				usr.client.mark_datum(target)

		return TRUE

/datum/admins/gamepanel/ui_data(mob/user)
	var/data = list()
	data["icon"] = selected_object_icon
	data["iconState"] = selected_object_icon_state
	data["precise_mode"] = precise_mode
	return data;

/datum/admins/gamepanel/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/json/gamepanel),
	)

/datum/admins/gamepanel/proc/get_dropdown_value(dropdown_value)
	switch(dropdown_value)
		if(WHERE_FLOOR_BELOW_MOB)
			return "onfloor"
		if(WHERE_SUPPLY_BELOW_MOB)
			return "frompod"
		if(WHERE_MOB_HAND)
			return "inhand"
		if(WHERE_MARKED_OBJECT)
			return "inmarked"
		if(WHERE_TARGETED_LOCATION)
			return "onfloor"
		if(WHERE_TARGETED_LOCATION_POD)
			return "frompod"
		if(WHERE_TARGETED_MOB_HAND)
			return "inhand"
	return

/datum/admins/gamepanel/proc/spawn_item(list/spawn_params)
	if(!check_rights_for(user_client, R_ADMIN) || !spawn_params)
		return

	if(!spawn_params["object_list"]) //this is the laggiest thing ever
		return

	var/atom/spawn_loc = usr.loc
	var/dirty_paths

	if (istext(spawn_params["object_list"]))
		dirty_paths = list(spawn_params["object_list"])
	else if (istype(spawn_params["object_list"], /list))
		dirty_paths = spawn_params["object_list"]

	var/paths = list()

	for(var/dirty_path in dirty_paths)
		var/path = text2path(dirty_path)
		if(!path)
			continue
		else if(!ispath(path, /obj) && !ispath(path, /turf) && !ispath(path, /mob))
			continue
		paths += path

	if(!paths)
		tgui_alert(usr,"The path list you sent is empty.")
		return

	var/number = clamp(text2num(spawn_params["object_count"]), 1, ADMIN_SPAWN_CAP)
	if(length(paths) * number > ADMIN_SPAWN_CAP)
		tgui_alert(usr,"Select fewer object types!")
		return

	var/offset_raw = spawn_params["offset"]
	var/list/offset = splittext(offset_raw, ",")
	var/X = 0
	var/Y = 0
	var/Z = 0

	if(spawn_params["X"] && spawn_params["Y"] && spawn_params["Z"])
		X = spawn_params["X"]
		Y = spawn_params["Y"]
		Z = spawn_params["Z"]
	else if(offset.len > 0)
		X = text2num(offset[1])
		if(isnull(X))
			X = 0

		if(offset.len > 1)
			Y = text2num(offset[2])
			if(isnull(Y))
				Y = 0

		if(offset.len > 2)
			Z = text2num(offset[3])
			if(isnull(Z))
				Z = 0

	var/obj_dir = text2num(spawn_params["object_dir"])
	if(obj_dir && !(obj_dir in list(1,2,4,8,5,6,9,10)))
		obj_dir = null
	var/obj_name = sanitize(spawn_params["object_name"])

	var/atom/target // Where the object will be spawned
	var/where = spawn_params["object_where"]
	if (!(where in list("onfloor","frompod","inhand","inmarked") ))
		where = "onfloor"

	switch(where)
		if("inhand")
			if (!iscarbon(usr) && !iscyborg(usr))
				to_chat(usr, "Can only spawn in hand when you're a carbon mob or cyborg.", confidential = TRUE)
				where = "onfloor"
			target = usr

		if("onfloor", "frompod")
			switch(spawn_params["offset_type"])
				if(ABSOLUTE_OFFSET)
					if(spawn_params["X"] && spawn_params["Y"] && spawn_params["Z"])
						target = locate(X, Y, Z)
					else
						target = locate(X, Y, Z)
				if(RELATIVE_OFFSET)
					if(!spawn_loc)
						target = locate(1, 1, 1)
					else
						var/turf/T = get_turf(spawn_loc)
						if(!T)
							if(isobserver(usr))
								var/mob/dead/observer/O = usr
								T = get_turf(O.client?.eye) || get_turf(O) || get_turf(GLOB.start_landmarks_list[1])
							else
								target = locate(1, 1, 1)

						if(T)
							target = locate(T.x + X, T.y + Y, T.z + Z)

		if("inmarked")
			if(!marked_datum)
				to_chat(usr, "You don't have any object marked. Abandoning spawn.", confidential = TRUE)
				return
			else if(!istype(marked_datum, /atom))
				to_chat(usr, "The object you have marked cannot be used as a target. Target must be of type /atom. Abandoning spawn.", confidential = TRUE)
				return
			else
				target = marked_datum

	var/obj/structure/closet/supplypod/centcompod/pod

	if(target)
		if(where == "frompod")
			pod = new()

		for(var/path in paths)
			for(var/i = 0; i < number; i++)
				if(path in typesof(/turf))
					var/turf/O = target
					var/turf/N = O.ChangeTurf(path)
					if(N && obj_name)
						N.name = obj_name
				else
					var/atom/O
					if(where == "frompod")
						O = new path(pod)
					else
						O = new path(target)

					if(!QDELETED(O))
						O.flags_1 |= ADMIN_SPAWNED_1
						if(obj_dir)
							O.setDir(obj_dir)
						if(obj_name)
							O.name = obj_name
							if(ismob(O))
								var/mob/M = O
								M.real_name = obj_name
						if(where == "inhand" && isliving(usr) && isitem(O))
							var/mob/living/L = usr
							var/obj/item/I = O
							L.put_in_hands(I)
							if(iscyborg(L))
								var/mob/living/silicon/robot/R = L
								if(R.model)
									R.model.add_module(I, TRUE, TRUE)
									R.activate_module(I)

	if(pod)
		new /obj/effect/pod_landingzone(target, pod)

	if (number == 1)
		log_admin("[key_name(usr)] created an instance of [english_list(paths)]")
		for(var/path in paths)
			if(ispath(path, /mob))
				message_admins("[key_name_admin(usr)] created an instance of [english_list(paths)]")
				break
	else
		log_admin("[key_name(usr)] created [number] instances of [english_list(paths)]")
		for(var/path in paths)
			if(ispath(path, /mob))
				message_admins("[key_name_admin(usr)] created [number] instances of [english_list(paths)]")
				break

#undef WHERE_MARKED_OBJECT
#undef WHERE_MOB_HAND
#undef WHERE_SUPPLY_BELOW_MOB
#undef WHERE_FLOOR_BELOW_MOB
#undef ABSOLUTE_OFFSET
#undef RELATIVE_OFFSET
