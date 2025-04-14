/datum/asset/json/gamepanel
	name = "gamepanel"

/datum/asset/json/gamepanel/generate()
	var/list/data = list()
	var/list/panels = list("Object", "Turf", "Mob", "Object By Name", "Turf By Name", "Mob By Name")
	for(var/panel in panels)
		switch(panel)
			if("Object")
				data[panel] = list()
				var/list/objects = typesof(/obj)
				for(var/item in objects)
					var/obj/temp = item;
					data[panel][item] = list("icon"=temp?.icon || "none", "icon_state"=temp?.icon_state || "none", "name"=temp.name)
			if("Turf")
				data[panel] = list()
				var/list/turfs = typesof(/turf)
				for(var/item in turfs)
					var/turf/temp = item;
					data[panel][item] = list("icon"=temp?.icon || "noneturf", "icon_state"=temp?.icon_state || "noneturf")
			if("Mob")
				data[panel] = list()
				var/list/mobs = typesof(/mob)
				for(var/item in mobs)
					var/mob/temp = item;
					data[panel][item] = list("icon"=temp?.icon || "nonemob", "icon_state"=temp?.icon_state || "nonemob")
			if("Object By Name")
				data[panel] = list()
				var/list/objects = typesof(/obj)
				for(var/item in objects)
					var/obj/temp = item;
					data[panel][temp.name] = list("icon"=temp?.icon || "none", "icon_state"=temp?.icon_state || "none", "type"=item)
			if("Turf By Name")
				data[panel] = list()
				var/list/turfs = typesof(/turf)
				for(var/item in turfs)
					var/turf/temp = item;
					data[panel][temp.name] = list("icon"=temp?.icon || "noneturf", "icon_state"=temp?.icon_state || "noneturf")
			if("Mob By Name")
				data[panel] = list()
				var/list/mobs = typesof(/mob)
				for(var/item in mobs)
					var/mob/temp = item;
					data[panel][temp.name] = list("icon"=temp?.icon || "nonemob", "icon_state"=temp?.icon_state || "nonemob")
	return data
