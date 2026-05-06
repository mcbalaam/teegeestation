/obj/item/disk/computer
	/// The amount of storage space available on the disk.
	var/filesystem_capacity = 16

	/// List of all programs that the disk should start with
	var/list/datum/computer_file/starting_programs = list()

/obj/item/disk/computer/Initialize(mapload)
	. = ..()
	var/datum/disk_payload/ntos_filesystem/fs = get_payload(/datum/disk_payload/ntos_filesystem, include_hidden = TRUE)
	if(!fs)
		fs = new
		add_payload(fs)

	fs.max_capacity = max(fs.max_capacity, filesystem_capacity)
	for(var/programs in starting_programs)
		var/datum/computer_file/program_type = new programs
		fs.add_file(program_type, src)

/obj/item/disk/computer/advanced
	name = "advanced data disk"
	icon_state = "datadisk5"
	filesystem_capacity = 64

/obj/item/disk/computer/super
	name = "super data disk"
	desc = "Removable disk used to store large amounts of data."
	icon_state = "datadisk3"
	filesystem_capacity = 256
