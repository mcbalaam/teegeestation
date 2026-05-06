/**
 * Virus disk
 * Can't hold apps, instead does unique actions.
 */

/datum/disk_payload/virus
	///How many charges the virus has left
	var/charges = 5

/datum/disk_payload/virus/is_hidden(obj/item/disk/disk)
	return !!disk.read_only

/datum/disk_payload/virus/proc/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	if(charges <= 0)
		to_chat(user, span_notice("ERROR: Out of charges."))
		return FALSE
	if(!target)
		to_chat(user, span_notice("ERROR: Could not find device."))
		return FALSE
	return TRUE

/datum/disk_payload/virus/clown

/datum/disk_payload/virus/clown/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	. = ..()
	if(!.)
		return FALSE

	user.show_message(span_notice("Success!"))
	charges--
	target.honkvirus_amount = rand(15, 25)
	return TRUE

/datum/disk_payload/virus/mime

/datum/disk_payload/virus/mime/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	. = ..()
	if(!.)
		return FALSE

	var/datum/computer_file/program/messenger/app = locate() in target.stored_files
	if(!app)
		return FALSE
	user.show_message(span_notice("Success!"))
	charges--
	app.alert_silenced = TRUE
	app.ringtone = ""

/datum/disk_payload/virus/detomatix
	charges = 6

/datum/disk_payload/virus/detomatix/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	. = ..()
	if(!.)
		return FALSE

	var/difficulty = target.get_detomatix_difficulty()
	if(SEND_SIGNAL(target, COMSIG_TABLET_CHECK_DETONATE) & COMPONENT_TABLET_NO_DETONATE || prob(difficulty * 15))
		user.show_message(span_danger("ERROR: Target could not be bombed."), MSG_VISUAL)
		charges--
		return

	var/original_host = source
	var/fakename = sanitize_name(tgui_input_text(user, "Enter a name for the rigged message.", "Forge Message", max_length = MAX_NAME_LEN), allow_numbers = TRUE)
	if(!fakename || source != original_host || !user.can_perform_action(source))
		return
	var/fakejob = sanitize_name(tgui_input_text(user, "Enter a job for the rigged message.", "Forge Message", max_length = MAX_NAME_LEN), allow_numbers = TRUE)
	if(!fakejob || source != original_host || !user.can_perform_action(source))
		return
	var/attach_fake_photo = tgui_alert(user, "Attach a fake photo?", "Forge Message", list("Yes", "No")) == "Yes"

	var/datum/computer_file/program/messenger/app = locate() in source.stored_files
	var/datum/computer_file/program/messenger/target_app = locate() in target.stored_files
	if(!app || charges <= 0 || !app.send_rigged_message(user, message, list(target_app), fakename, fakejob, attach_fake_photo))
		return FALSE
	charges--
	user.show_message(span_notice("Success!"))
	var/reference = REF(src)
	target.add_traits(list(TRAIT_PDA_CAN_EXPLODE, TRAIT_PDA_MESSAGE_MENU_RIGGED), reference)
	addtimer(TRAIT_CALLBACK_REMOVE(target, TRAIT_PDA_MESSAGE_MENU_RIGGED, reference), 10 SECONDS)
	addtimer(TRAIT_CALLBACK_REMOVE(target, TRAIT_PDA_CAN_EXPLODE, reference), 1 MINUTES)
	return TRUE

/datum/disk_payload/virus/frame
	///How many telecrystals the uplink should have
	var/telecrystals = 0
	///How much progression should be shown in the uplink, set on purchase of the item.
	var/current_progression = 0

/datum/disk_payload/virus/frame/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	. = ..()
	if(!.)
		return FALSE

	charges--
	var/unlock_code = "[rand(100,999)] [pick(GLOB.phonetic_alphabet)]"
	to_chat(user, span_notice("Success! The unlock code to the target is: [unlock_code]"))
	var/datum/component/uplink/hidden_uplink = target.GetComponent(/datum/component/uplink)
	if(!hidden_uplink)
		var/datum/mind/target_mind
		var/list/backup_players = list()
		for(var/datum/mind/player as anything in get_crewmember_minds())
			if(player.assigned_role?.title == target.saved_job)
				backup_players += player
			if(player.name == target.saved_identification)
				target_mind = player
				break
		if(!target_mind)
			if(!length(backup_players))
				target_mind = user.mind
			else
				target_mind = pick(backup_players)
		hidden_uplink = target.AddComponent(/datum/component/uplink, target_mind, enabled = TRUE, starting_tc = telecrystals, has_progression = TRUE)
		hidden_uplink.unlock_code = unlock_code
		hidden_uplink.uplink_handler.owner = target_mind
		hidden_uplink.uplink_handler.progression_points = min(SStraitor.current_global_progression, current_progression)
		SStraitor.register_uplink_handler(hidden_uplink.uplink_handler)
	else
		hidden_uplink.uplink_handler.add_telecrystals(telecrystals)
	telecrystals = 0
	hidden_uplink.locked = FALSE
	hidden_uplink.active = TRUE

/obj/item/disk/computer/virus
	name = "\improper generic virus disk"
	max_capacity = 0
	read_only = TRUE

/obj/item/disk/computer/virus/proc/ensure_virus_payload(typepath)
	var/datum/disk_payload/virus/existing = get_payload(/datum/disk_payload/virus, include_hidden = TRUE)
	if(existing)
		payloads -= existing
		qdel(existing)
	var/datum/disk_payload/virus/new_payload = new typepath
	add_payload(new_payload)
	return new_payload

/obj/item/disk/computer/virus/proc/ensure_filesystem_payload()
	var/datum/disk_payload/ntos_filesystem/fs = get_payload(/datum/disk_payload/ntos_filesystem, include_hidden = TRUE)
	if(fs)
		return fs
	fs = new
	fs.max_capacity = 16
	add_payload(fs)
	return fs

/obj/item/disk/computer/virus/proc/add_junk_files(datum/disk_payload/ntos_filesystem/fs)
	if(!fs)
		return
	var/list/names = list("dna_backup", "bio_scan", "holopad_cache", "crew_notes", "readme")
	var/list/texts = list(
		"NT-Genetics export incomplete.\nChecksum mismatch.",
		"Hologram preset index rebuilt.\nStatus: OK.",
		"Do not remove.\nProperty of Nanotrasen.",
		"[pick("A", "B", "C")][rand(100,999)]-[pick("X", "Y", "Z")]: archived.",
		"Nothing to see here."
	)
	var/attempts = rand(2, 4)
	for(var/i in 1 to attempts)
		var/datum/computer_file/data/text/T = new
		T.filename = pick(names)
		T.stored_text = pick(texts)
		T.calculate_size()
		if(!fs.add_file(T, src))
			qdel(T)
			break

/obj/item/disk/computer/virus/proc/ensure_blob_payload()
	if(get_payload(/datum/disk_payload/data_blob, include_hidden = TRUE))
		return
	var/datum/disk_payload/data_blob/blob = new("[rand(1000,9999)]-[pick("NT", "BIO", "HLO", "SYS")]", rand(1,5))
	add_payload(blob)

/obj/item/disk/computer/virus/Initialize(mapload)
	. = ..()
	ensure_virus_payload(/datum/disk_payload/virus)

	// disguise as a normal data disk
	icon_state = "datadisk[rand(0, 7)]"
	// randomize disk color/reskin
	if(prob(75))
		var/list/color_states = list("datadisk0", "datadisk1", "datadisk2", "datadisk3", "datadisk4", "datadisk5", "datadisk6", "datadisk7")
		icon_state = pick(color_states)

	if(sticker_icon_state == initial(sticker_icon_state))
		// exclude DNA/holo/medical stickers, and number/letter stickers that look too specific
		var/list/excluded = list("o_dna1", "o_dna2", "o_medical", "o_holo", "o_one", "o_two", "o_three", "o_four", "o_five", "o_six", "o_seven", "o_eight", "o_nine", "o_zero", "o_A", "o_B", "o_C", "o_D", "o_E", "o_F")
		var/list/allowed = list()
		for(var/variant_name in sticker_variants)
			var/icon_state_name = sticker_variants[variant_name]
			if(!(icon_state_name in excluded))
				allowed += icon_state_name
		if(!LAZYLEN(allowed))
			allowed = list("o_text1", "o_text2", "o_text3", "o_code")
		set_sticker_icon_state(pick(allowed))

	var/datum/disk_payload/ntos_filesystem/fs = ensure_filesystem_payload()
	add_junk_files(fs)
	ensure_blob_payload()

/obj/item/disk/computer/virus/clown
	name = "\improper H.O.N.K. disk"

/obj/item/disk/computer/virus/clown/Initialize(mapload)
	. = ..()
	ensure_virus_payload(/datum/disk_payload/virus/clown)

/obj/item/disk/computer/virus/mime
	name = "\improper sound of silence disk"

/obj/item/disk/computer/virus/mime/Initialize(mapload)
	. = ..()
	ensure_virus_payload(/datum/disk_payload/virus/mime)

/obj/item/disk/computer/virus/detomatix
	name = "\improper D.E.T.O.M.A.T.I.X. disk"

/obj/item/disk/computer/virus/detomatix/Initialize(mapload)
	. = ..()
	ensure_virus_payload(/datum/disk_payload/virus/detomatix)

/obj/item/disk/computer/virus/frame
	name = "\improper F.R.A.M.E. disk"

/obj/item/disk/computer/virus/frame/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!istype(attacking_item, /obj/item/stack/telecrystal))
		return
	var/datum/disk_payload/virus/frame/payload = get_payload(/datum/disk_payload/virus/frame, include_hidden = TRUE)
	if(!payload)
		return
	if(!payload.charges)
		to_chat(user, span_notice("[src] is out of charges, it's refusing to accept [attacking_item]."))
		return
	var/obj/item/stack/telecrystal/telecrystal_stack = attacking_item
	payload.telecrystals += telecrystal_stack.amount
	to_chat(user, span_notice("You slot [telecrystal_stack] into [src]. The next time it's used, it will also give telecrystals."))
	telecrystal_stack.use(telecrystal_stack.amount)

/obj/item/disk/computer/virus/frame/Initialize(mapload)
	. = ..()
	ensure_virus_payload(/datum/disk_payload/virus/frame)
