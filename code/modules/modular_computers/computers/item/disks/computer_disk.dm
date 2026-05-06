/obj/item/disk/computer
	/// Legacy vars are now stored in the disk payload.
	var/max_capacity = 16
	var/used_capacity = 0
	var/list/datum/computer_file/stored_files = list()

	/// List of all programs that the disk should start with
	var/list/datum/computer_file/starting_programs = list()

/obj/item/disk/computer/Initialize(mapload)
	. = ..()
	var/datum/disk_payload/ntos_filesystem/fs = get_payload(/datum/disk_payload/ntos_filesystem)
	if(!fs)
		fs = new
		add_payload(fs)

	fs.max_capacity = max_capacity
	fs.used_capacity = used_capacity
	if(!LAZYLEN(stored_files))
		fs.stored_files = stored_files
	max_capacity = fs.max_capacity
	used_capacity = fs.used_capacity
	stored_files = fs.stored_files

	for(var/programs in starting_programs)
		var/datum/computer_file/program_type = new programs
		add_file(program_type)

/obj/item/disk/computer/Destroy(force)
	. = ..()
	stored_files = null

/obj/item/disk/computer/proc/add_file(datum/computer_file/file)
	var/datum/disk_payload/ntos_filesystem/fs = get_payload(/datum/disk_payload/ntos_filesystem)
	if(!fs)
		return FALSE
	if(!fs.add_file(file, src))
		return FALSE
	used_capacity = fs.used_capacity
	return TRUE

/obj/item/disk/computer/proc/remove_file(datum/computer_file/file)
	var/datum/disk_payload/ntos_filesystem/fs = get_payload(/datum/disk_payload/ntos_filesystem)
	if(!fs)
		return FALSE
	if(!fs.remove_file(file))
		return FALSE
	used_capacity = fs.used_capacity
	return TRUE

/obj/item/disk/computer/advanced
	name = "advanced data disk"
	icon_state = "datadisk5"
	max_capacity = 64

/obj/item/disk/computer/super
	name = "super data disk"
	desc = "Removable disk used to store large amounts of data."
	icon_state = "datadisk3"
	max_capacity = 256
