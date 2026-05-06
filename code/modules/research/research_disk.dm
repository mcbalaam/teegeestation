/obj/item/disk/data/tech_disk
	name = "technology disk"
	desc = "A disk for storing technology data for further research."
	icon_state = "datadisk0"
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass=SMALL_MATERIAL_AMOUNT)

/datum/disk_payload/research_techweb
	var/datum/techweb/stored_research

/obj/item/disk/data/tech_disk/Initialize(mapload)
	. = ..()
	var/datum/disk_payload/research_techweb/payload = get_payload(/datum/disk_payload/research_techweb)
	if(!payload)
		payload = new
		add_payload(payload)
	if(!payload.stored_research)
		payload.stored_research = new /datum/techweb/disk
	pixel_x = base_pixel_x + rand(-5, 5)
	pixel_y = base_pixel_y + rand(-5, 5)

/obj/item/disk/data/tech_disk/debug
	name = "\improper CentCom technology disk"
	desc = "A debug item for research"
	custom_materials = null

/obj/item/disk/data/tech_disk/debug/Initialize(mapload)
	var/datum/disk_payload/research_techweb/payload = get_payload(/datum/disk_payload/research_techweb)
	if(!payload)
		payload = new
		add_payload(payload)
	payload.stored_research = locate(/datum/techweb/admin) in SSresearch.techwebs
	return ..()

// Legacy path for maps/refs.
/obj/item/disk/tech_disk
	parent_type = /obj/item/disk/data/tech_disk

/obj/item/disk/tech_disk/debug
	parent_type = /obj/item/disk/data/tech_disk/debug
