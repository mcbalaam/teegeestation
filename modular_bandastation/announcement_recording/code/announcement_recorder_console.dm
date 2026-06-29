#define MAX_RECORD_DURATION (60 SECONDS)
#define RECORD_RANGE_MIN 1
#define RECORD_RANGE_MAX 5
#define RECORD_RANGE_DEFAULT 3

/datum/announcement_recorder
	var/obj/machinery/parent_console
	var/recording = FALSE
	var/record_range = RECORD_RANGE_DEFAULT
	var/start_time
	var/list/fragments = list()
	var/timer_id
	var/ann_type

/datum/announcement_recorder/New(obj/machinery/console, type)
	parent_console = console
	ann_type = type

/datum/announcement_recorder/Destroy()
	if(recording)
		recording = FALSE
		parent_console?.lose_hearing_sensitivity(REF(src))
		if(timer_id)
			deltimer(timer_id)
			timer_id = null
	parent_console = null
	fragments?.Cut()
	return ..()

/datum/announcement_recorder/proc/get_fragments_ui_data()
	var/list/data = list()
	for(var/datum/announcement_fragment/frag as anything in fragments)
		data += list(list(
			"speaker_name" = frag.speaker_name,
			"text" = frag.text,
		))
	return data

/datum/announcement_recorder/proc/start_recording()
	if(recording)
		return
	recording = TRUE
	fragments.Cut()
	start_time = world.time
	parent_console.become_hearing_sensitive(REF(src))
	timer_id = addtimer(CALLBACK(src, PROC_REF(stop_recording), TRUE), MAX_RECORD_DURATION, TIMER_STOPPABLE)

/datum/announcement_recorder/proc/stop_recording(send_announcement = TRUE)
	if(!recording)
		return
	recording = FALSE
	if(parent_console)
		parent_console.lose_hearing_sensitivity(REF(src))
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	if(send_announcement && length(fragments))
		build_and_send_announcement()

/datum/announcement_recorder/proc/cancel_recording()
	if(!recording)
		return
	recording = FALSE
	if(parent_console)
		parent_console.lose_hearing_sensitivity(REF(src))
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	fragments.Cut()

/datum/announcement_recorder/proc/capture_fragment(atom/movable/speaker, raw_message)
	if(!recording || !parent_console)
		return
	var/dist = get_dist(parent_console, speaker)
	if(dist > record_range)
		return
	fragments += new /datum/announcement_fragment(
		world.time - start_time,
		speaker.get_voice(),
		raw_message,
		speaker.get_tts_seed(),
	)

/datum/announcement_recorder/proc/build_announcement_text()
	var/list/lines = list()
	var/last_speaker = ""
	for(var/datum/announcement_fragment/frag as anything in fragments)
		if(frag.speaker_name != last_speaker)
			if(length(lines))
				lines += ""
			last_speaker = frag.speaker_name
		lines += frag.get_formatted_text()
	return jointext(lines, "\n")

/datum/announcement_recorder/proc/build_and_send_announcement()
	var/text = build_announcement_text()
	if(!length(text))
		return

	if(ann_type == "minor")
		minor_announce(text, title = "[parent_console.name] объявляет",
			html_encode = FALSE,
			sound_override = 'sound/announcer/announcement/announce_dig.ogg')
	else
		priority_announce(text, title = "Записанное оповещение",
			sound = 'sound/announcer/announcement/announce.ogg',
			type = ANNOUNCEMENT_TYPE_CAPTAIN)

	play_fragments_tts()

/datum/announcement_recorder/proc/play_fragments_tts()
	set waitfor = FALSE
	if(!SStts220.is_enabled || !length(fragments))
		return

	var/datum/tts_seed/default_seed
	var/mob/living/silicon/ai/active_ai = DEFAULTPICK(active_ais(TRUE, null), null)
	default_seed = active_ai ? active_ai.get_tts_seed() : /datum/tts_seed/silero/glados

	for(var/i in 1 to length(fragments))
		var/datum/announcement_fragment/frag = fragments[i]
		var/datum/tts_seed/seed_to_use = frag.tts_seed || default_seed

		SStts220.get_tts(
			message = frag.text,
			tts_seed = seed_to_use,
			is_local = FALSE,
			effect_types = list(/datum/singleton/sound_effect/announcement),
			channel_override = CHANNEL_TTS_ANNOUNCEMENT,
		)
		if(i < length(fragments))
			var/datum/announcement_fragment/next_frag = fragments[i + 1]
			if(frag.speaker_name != next_frag.speaker_name)
				sleep(0.3 SECONDS)

// Communications Console overrides — recording as modal inside existing TGUI
#define IMPORTANT_ACTION_COOLDOWN (60 SECONDS)
#define EMERGENCY_ACCESS_COOLDOWN (30 SECONDS)
#define STATE_BUYING_SHUTTLE "buying_shuttle"
#define STATE_CHANGING_STATUS "changing_status"
#define STATE_MAIN "main"
#define STATE_MESSAGES "messages"

/obj/machinery/computer/communications
	var/datum/announcement_recorder/recorder

/obj/machinery/computer/communications/Destroy()
	QDEL_NULL(recorder)
	return ..()

/obj/machinery/computer/communications/Hear(atom/movable/speaker, message_langs, raw_message, radio_freq, radio_freq_name, radio_freq_color, spans, list/message_mods = list(), message_range)
	. = ..()
	if(!QDELETED(recorder) && recorder.recording && !radio_freq)
		recorder.capture_fragment(speaker, raw_message)

/obj/machinery/computer/communications/proc/start_recording_announcement(mob/user, ann_type)
	if(recorder)
		QDEL_NULL(recorder)
	recorder = new /datum/announcement_recorder(src, ann_type)

/obj/machinery/computer/communications/ui_data(mob/user)
	var/list/data = list(
		"authenticated" = FALSE,
		"emagged" = FALSE,
		"syndicate" = syndicate,
	)

	var/ui_state = HAS_SILICON_ACCESS(user) ? cyborg_state : state

	var/has_connection = has_communication()
	data["hasConnection"] = has_connection

	if(!SSjob.assigned_captain && !SSjob.safe_code_requested && SSid_access.spare_id_safe_code && has_connection)
		data["canRequestSafeCode"] = TRUE
		data["safeCodeDeliveryWait"] = 0
	else
		data["canRequestSafeCode"] = FALSE
		if(SSjob.safe_code_timer_id && has_connection)
			data["safeCodeDeliveryWait"] = timeleft(SSjob.safe_code_timer_id)
			data["safeCodeDeliveryArea"] = get_area(SSjob.safe_code_request_loc)
		else
			data["safeCodeDeliveryWait"] = 0
			data["safeCodeDeliveryArea"] = null

	if(authenticated || HAS_SILICON_ACCESS(user))
		data["authenticated"] = TRUE
		data["canLogOut"] = !HAS_SILICON_ACCESS(user)
		data["page"] = ui_state

		if((obj_flags & EMAGGED) || syndicate)
			data["emagged"] = TRUE

		switch(ui_state)
			if(STATE_MAIN)
				data["canBuyShuttles"] = can_buy_shuttles(user)
				data["canMakeAnnouncement"] = FALSE
				data["canMessageAssociates"] = FALSE
				data["canRecallShuttles"] = !HAS_SILICON_ACCESS(user)
				data["canRequestNuke"] = FALSE
				data["canRequestERT"] = FALSE
				data["canSendToSectors"] = FALSE
				data["canSetAlertLevel"] = FALSE
				data["canToggleEmergencyAccess"] = FALSE
				data["importantActionReady"] = COOLDOWN_FINISHED(src, important_action_cooldown)
				data["shuttleCalled"] = FALSE
				data["shuttleLastCalled"] = FALSE
				data["aprilFools"] = check_holidays(APRIL_FOOLS)
				data["alertLevel"] = SSsecurity_level.get_current_level_as_text()
				data["authorizeName"] = authorize_name
				data["canLogOut"] = !HAS_SILICON_ACCESS(user)
				data["shuttleCanEvacOrFailReason"] = SSshuttle.canEvac()
				if(syndicate)
					data["shuttleCanEvacOrFailReason"] = "You cannot summon the shuttle from this console!"

				if(authenticated_as_non_silicon_captain(user))
					data["canMessageAssociates"] = TRUE
					data["canRequestNuke"] = TRUE
					data["canRequestERT"] = TRUE

				if(can_send_messages_to_other_sectors(user))
					data["canSendToSectors"] = TRUE

					var/list/sectors = list()
					var/our_id = CONFIG_GET(string/cross_comms_name)

					for(var/server in CONFIG_GET(keyed_list/cross_server))
						if(server == our_id)
							continue
						sectors += server

					data["sectors"] = sectors

				if(authenticated_as_silicon_or_captain(user))
					data["canToggleEmergencyAccess"] = TRUE
					data["emergencyAccess"] = GLOB.emergency_access

					data["alertLevelTick"] = alert_level_tick
					data["canMakeAnnouncement"] = TRUE
					data["canSetAlertLevel"] = HAS_SILICON_ACCESS(user) ? "NO_SWIPE_NEEDED" : "SWIPE_NEEDED"
				else if(syndicate)
					data["canMakeAnnouncement"] = TRUE

				if(SSshuttle.emergency.mode != SHUTTLE_IDLE && SSshuttle.emergency.mode != SHUTTLE_RECALL)
					data["shuttleCalled"] = TRUE
					data["shuttleRecallable"] = SSshuttle.can_recall(user) || syndicate

				if(SSshuttle.emergencyCallAmount)
					data["shuttleCalledPreviously"] = TRUE
					if(SSshuttle.emergency_last_call_loc)
						data["shuttleLastCalled"] = format_text(SSshuttle.emergency_last_call_loc.name)
			if(STATE_MESSAGES)
				data["messages"] = list()

				if(messages)
					for(var/_message in messages)
						var/datum/comm_message/message = _message
						data["messages"] += list(list(
							"answered" = message.answered,
							"content" = message.content,
							"title" = message.title,
							"possibleAnswers" = message.possible_answers,
						))
			if(STATE_BUYING_SHUTTLE)
				var/datum/bank_account/bank_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
				var/list/shuttles = list()

				for(var/shuttle_id in SSmapping.shuttle_templates)
					var/datum/map_template/shuttle/shuttle_template = SSmapping.shuttle_templates[shuttle_id]

					if(shuttle_template.credit_cost == INFINITY)
						continue

					if(!can_purchase_this_shuttle(shuttle_template))
						continue

					shuttles += list(list(
						"name" = shuttle_template.name,
						"description" = shuttle_template.description,
						"occupancy_limit" = shuttle_template.occupancy_limit,
						"creditCost" = shuttle_template.credit_cost,
						"initial_cost" = initial(shuttle_template.credit_cost),
						"emagOnly" = shuttle_template.emag_only,
						"prerequisites" = shuttle_template.prerequisites,
						"ref" = REF(shuttle_template),
					))

				data["budget"] = bank_account.account_balance
				data["shuttles"] = shuttles
			if(STATE_CHANGING_STATUS)
				data["upperText"] = last_status_display ? last_status_display[1] : ""
				data["lowerText"] = last_status_display ? last_status_display[2] : ""

	// БАНДАСТАНЦИЯ ADDITION START — Announcement Recording
	if(recorder && !QDELETED(recorder))
		data["recorderActive"] = TRUE
		data["recorderData"] = list(
			"recording" = recorder.recording,
			"range" = recorder.record_range,
			"elapsed" = recorder.recording ? round((world.time - recorder.start_time) / 10, 1) : 0,
			"maxDuration" = MAX_RECORD_DURATION / 10,
			"fragments" = recorder.get_fragments_ui_data(),
			"fragmentsCount" = length(recorder.fragments),
		)
	// БАНДАСТАНЦИЯ ADDITION END

	return data

/obj/machinery/computer/communications/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/ui_state)
	var/static/list/approved_states = list(STATE_BUYING_SHUTTLE, STATE_CHANGING_STATUS, STATE_MAIN, STATE_MESSAGES)

	. = ..()
	if(.)
		return

	if(!has_communication())
		return

	var/mob/user = ui.user
	. = TRUE

	// БАНДАСТАНЦИЯ ADDITION START — Announcement Recording
	if(action == "makeRecordedAnnouncement")
		if(!authenticated_as_silicon_or_captain(user) && !syndicate)
			return
		start_recording_announcement(user, "priority")
		return TRUE

	if(action == "recorderAct")
		if(!recorder || QDELETED(recorder))
			return
		var/sub = params["sub"]
		switch(sub)
			if("start")
				recorder.start_recording()
			if("stop")
				recorder.stop_recording(send_announcement = TRUE)
				QDEL_NULL(recorder)
			if("cancel")
				recorder.cancel_recording()
				QDEL_NULL(recorder)
			if("setRange")
				if(!recorder.recording)
					recorder.record_range = clamp(text2num(params["range"]), RECORD_RANGE_MIN, RECORD_RANGE_MAX)
		return TRUE
	// БАНДАСТАНЦИЯ ADDITION END

	switch(action)
		if("answerMessage")
			if(!authenticated(user))
				return
			var/answer_index = params["answer"]
			var/message_index = params["message"]

			if(!isnum(answer_index) || !isnum(message_index))
				message_admins("[ADMIN_LOOKUPFLW(user)] provided an invalid index type when replying to a message on [src] [ADMIN_JMP(src)]. This should not happen. Please check with a maintainer and/or consult tgui logs.")
				CRASH("Non-numeric index provided when answering comms console message.")

			if(!answer_index || !message_index || answer_index < 1 || message_index < 1)
				return
			var/datum/comm_message/message = messages[message_index]
			if(message.answered)
				return
			message.answered = answer_index
			message.answer_callback.InvokeAsync()
		if("callShuttle")
			if(!authenticated(user) || syndicate)
				return
			var/reason = trim(params["reason"], MAX_MESSAGE_LEN)
			if(length(reason) < CALL_SHUTTLE_REASON_LENGTH)
				return
			SSshuttle.requestEvac(user, reason)
			post_status("shuttle")
		if("changeSecurityLevel")
			if(!authenticated_as_silicon_or_captain(user))
				return

			if(!HAS_SILICON_ACCESS(user))
				var/obj/item/held_item = user.get_active_held_item()
				var/obj/item/card/id/id_card = held_item?.GetID()
				if(!istype(id_card))
					to_chat(user, span_warning("You need to swipe your ID!"))
					playsound(src, 'sound/machines/terminal/terminal_prompt_deny.ogg', 50, FALSE)
					return
				if(!(ACCESS_CAPTAIN in id_card.access))
					to_chat(user, span_warning("You are not authorized to do this!"))
					playsound(src, 'sound/machines/terminal/terminal_prompt_deny.ogg', 50, FALSE)
					return

			var/new_sec_level = SSsecurity_level.text_level_to_number(params["newSecurityLevel"])
			if(new_sec_level != SEC_LEVEL_GREEN && new_sec_level != SEC_LEVEL_BLUE)
				return
			if(SSsecurity_level.get_current_level_as_number() >= SEC_LEVEL_DELTA)
				to_chat(user, span_warning("Central Command has placed a lock on the alert level due to a doomsday!"))
				return
			if(SSsecurity_level.get_current_level_as_number() >= SEC_LEVEL_GAMMA)
				to_chat(user, span_warning("Центральным командованием установлено военное положение. Изменение кода невозможно."))
				return
			if(SSsecurity_level.get_current_level_as_number() == new_sec_level)
				return

			SSsecurity_level.set_level(new_sec_level)

			to_chat(user, span_notice("Authorization confirmed. Modifying security level."))
			playsound(src, 'sound/machines/terminal/terminal_prompt_confirm.ogg', 50, FALSE)

			user.log_message("changed the security level to [params["newSecurityLevel"]] with [src].", LOG_GAME)
			message_admins("[ADMIN_LOOKUPFLW(user)] has changed the security level to [params["newSecurityLevel"]] with [src] at [AREACOORD(user)].")
			deadchat_broadcast(" has changed the security level to [params["newSecurityLevel"]] with [src] at [span_name("[get_area_name(user, TRUE)]")].", span_name("[user.real_name]"), user, message_type=DEADCHAT_ANNOUNCEMENT)

			alert_level_tick += 1
		if("deleteMessage")
			if(!authenticated(user))
				return
			var/message_index = text2num(params["message"])
			if(!message_index)
				return
			LAZYREMOVE(messages, LAZYACCESS(messages, message_index))
		if("makePriorityAnnouncement")
			if(!authenticated_as_silicon_or_captain(user) && !syndicate)
				return
			make_announcement(user)
		if("messageAssociates")
			if(!authenticated_as_non_silicon_captain(user))
				return
			if(!COOLDOWN_FINISHED(src, important_action_cooldown))
				return

			playsound(src, 'sound/machines/terminal/terminal_prompt_confirm.ogg', 50, FALSE)
			var/message = trim(html_encode(params["message"]), MAX_MESSAGE_LEN)

			var/emagged = obj_flags & EMAGGED
			if(emagged)
				message_syndicate(message, user)
				to_chat(user, span_danger("SYSERR @l(19833)of(transmit.dm): !@$ MESSAGE TRANSMITTED TO SYNDICATE COMMAND."))
			else if(syndicate)
				message_syndicate(message, user)
				to_chat(user, span_danger("Message transmitted to Syndicate Command."))
			else
				message_centcom(message, user)
				to_chat(user, span_notice("Message transmitted to Central Command."))

			var/associates = (emagged || syndicate) ? "the Syndicate": "CentCom"
			user.log_talk(message, LOG_SAY, tag = "message to [associates]")
			deadchat_broadcast(" has messaged [associates], \"[message]\" at [span_name("[get_area_name(user, TRUE)]")].", span_name("[user.real_name]"), user, message_type = DEADCHAT_ANNOUNCEMENT)
			COOLDOWN_START(src, important_action_cooldown, IMPORTANT_ACTION_COOLDOWN)
		if("purchaseShuttle")
			var/can_buy_shuttles_or_fail_reason = can_buy_shuttles(user)
			if(can_buy_shuttles_or_fail_reason != TRUE)
				if(can_buy_shuttles_or_fail_reason != FALSE)
					to_chat(user, span_alert("[can_buy_shuttles_or_fail_reason]"))
				return
			var/list/shuttles = assoc_to_values(SSmapping.shuttle_templates)
			var/datum/map_template/shuttle/shuttle = locate(params["shuttle"]) in shuttles
			if(!istype(shuttle))
				return
			if(!can_purchase_this_shuttle(shuttle))
				return
			if(!shuttle.prerequisites_met())
				to_chat(user, span_alert("You have not met the requirements for purchasing this shuttle."))
				return
			var/datum/bank_account/bank_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
			if(bank_account.account_balance < shuttle.credit_cost)
				return
			SSshuttle.shuttle_purchased = SHUTTLEPURCHASE_PURCHASED
			for(var/datum/round_event_control/shuttle_insurance/insurance_event in SSevents.control)
				insurance_event.weight *= 20
			SSshuttle.unload_preview()
			SSshuttle.existing_shuttle = SSshuttle.emergency
			SSshuttle.action_load(shuttle, replace = TRUE)
			bank_account.adjust_money(-shuttle.credit_cost)

			var/purchaser_name = (obj_flags & EMAGGED) ? scramble_message_replace_chars("AUTHENTICATION FAILURE: CVE-2018-17107", 60) : user.real_name
			minor_announce("[purchaser_name] купил [shuttle.name] за [shuttle.credit_cost][MONEY_NAME].[shuttle.extra_desc ? " [shuttle.extra_desc]" : ""]" , "Покупка шаттла")

			message_admins("[ADMIN_LOOKUPFLW(user)] purchased [shuttle.name].")
			log_shuttle("[key_name(user)] has purchased [shuttle.name].")
			SSblackbox.record_feedback("text", "shuttle_purchase", 1, shuttle.name)
			state = STATE_MAIN
		if("recallShuttle")
			if(!authenticated(user) || HAS_SILICON_ACCESS(user) || syndicate)
				return
			SSshuttle.cancel_evac(user)
		if("requestNukeCodes")
			if(!authenticated_as_non_silicon_captain(user))
				return
			if(!COOLDOWN_FINISHED(src, important_action_cooldown))
				return
			var/reason = trim(html_encode(params["reason"]), MAX_MESSAGE_LEN)
			nuke_request(reason, user)
			to_chat(user, span_notice("Request sent."))
			user.log_message("has requested the nuclear codes from CentCom with reason \"[reason]\"", LOG_SAY)
			priority_announce("[user] запросил коды для запуска механизма ядерного самоуничтожения станции. В ближайшее время будет отправлено уведомление о подтверждении или отклонении данного запроса.", "Запрос кода самоуничтожения станции", SSstation.announcer.get_rand_report_sound())
			playsound(src, 'sound/machines/terminal/terminal_prompt.ogg', 50, FALSE)
			COOLDOWN_START(src, important_action_cooldown, IMPORTANT_ACTION_COOLDOWN)
		if("requestERT")
			if(!authenticated_as_non_silicon_captain(user))
				return
			if(!COOLDOWN_FINISHED(src, important_action_cooldown))
				return
			var/reason = trim(html_encode(params["reason"]), MAX_MESSAGE_LEN)
			var/insert_this = list(list(
				"time" = round_timestamp(),
				"sender_real_name" = "[user.real_name ? user.real_name : user.name]",
				"sender_uid" = REF(user),
				"message" = reason))
			GLOB.ert_request_messages.Insert(1, insert_this)
			ert_request(reason, user)
			to_chat(user, span_notice("ERT request sent."))
			user.log_message("has requested an Emergency Response Team from CentCom with reason \"[reason]\"", LOG_SAY)
			priority_announce("Отправлен запрос ОБР. Инициатор: [user]. Запрос принят к рассмотрению.", "[command_name()]: Служба быстрого реагирования", SSstation.announcer.get_rand_report_sound())
			playsound(src, 'sound/machines/terminal/terminal_prompt.ogg', 50, FALSE)
			COOLDOWN_START(src, important_action_cooldown, IMPORTANT_ACTION_COOLDOWN)
		if("restoreBackupRoutingData")
			if(!authenticated_as_non_silicon_captain(user))
				return
			if(!(obj_flags & EMAGGED))
				return
			to_chat(user, span_notice("Backup routing data restored."))
			playsound(src, 'sound/machines/terminal/terminal_prompt_confirm.ogg', 50, FALSE)
			obj_flags &= ~EMAGGED
		if("sendToOtherSector")
			if(!authenticated_as_non_silicon_captain(user))
				return
			if(!can_send_messages_to_other_sectors(user))
				return
			if(!COOLDOWN_FINISHED(src, important_action_cooldown))
				return

			var/message = trim(html_encode(params["message"]), MAX_MESSAGE_LEN)
			if(!message)
				return

			GLOB.communications_controller.soft_filtering = FALSE
			var/list/hard_filter_result = is_ic_filtered(message)
			if(hard_filter_result)
				tgui_alert(user, "Your message contains: (\"[hard_filter_result[CHAT_FILTER_INDEX_WORD]]\"), which is not allowed on this server.")
				return

			var/list/soft_filter_result = is_soft_ooc_filtered(message)
			if(soft_filter_result)
				if(tgui_alert(user,"Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to use it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
					return
				message_admins("[ADMIN_LOOKUPFLW(user)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". They may be using a disallowed term for a cross-station message. Increasing delay time to reject.\n\n Message: \"[html_encode(message)]\"")
				log_admin_private("[key_name(user)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". They may be using a disallowed term for a cross-station message. Increasing delay time to reject.\n\n Message: \"[message]\"")
				GLOB.communications_controller.soft_filtering = TRUE

			playsound(src, 'sound/machines/terminal/terminal_prompt_confirm.ogg', 50, FALSE)

			var/destination = params["destination"]
			if(!(destination in CONFIG_GET(keyed_list/cross_server)) && destination != "all")
				message_admins("[ADMIN_LOOKUPFLW(user)] has passed an invalid destination into comms console cross-sector message. Message: \"[html_encode(message)]\"")
				return

			user.log_message("is about to send the following message to [destination]: [message]", LOG_GAME)
			to_chat(
				get_holders_with_rights(R_ADMIN),
				span_adminnotice( \
					"<b color='orange'>CROSS-SECTOR MESSAGE (OUTGOING):</b> [ADMIN_LOOKUPFLW(user)] is about to send \
					the following message to <b>[destination]</b> (will autoapprove in [GLOB.communications_controller.soft_filtering ? DisplayTimeText(EXTENDED_CROSS_SECTOR_CANCEL_TIME) : DisplayTimeText(CROSS_SECTOR_CANCEL_TIME)]): \
					<b><a href='byond://?src=[REF(src)];reject_cross_comms_message=1'>REJECT</a></b><br> \
					[html_encode(message)]" \
				)
			)

			send_cross_comms_message_timer = addtimer(CALLBACK(src, PROC_REF(send_cross_comms_message), user, destination, message), GLOB.communications_controller.soft_filtering ? EXTENDED_CROSS_SECTOR_CANCEL_TIME : CROSS_SECTOR_CANCEL_TIME, TIMER_STOPPABLE)

			COOLDOWN_START(src, important_action_cooldown, IMPORTANT_ACTION_COOLDOWN)
		if("setState")
			if(!authenticated(user))
				return
			if(!(params["state"] in approved_states))
				return
			if(state == STATE_BUYING_SHUTTLE && can_buy_shuttles(user) != TRUE)
				return
			set_state(usr, params["state"])
		if("setStatusMessage")
			if(!authenticated(user))
				return
			var/line_one = reject_bad_text(params["upperText"] || "", MAX_STATUS_LINE_LENGTH)
			var/line_two = reject_bad_text(params["lowerText"] || "", MAX_STATUS_LINE_LENGTH)
			post_status("message", line_one, line_two)
			last_status_display = list(line_one, line_two)
		if("setStatusPicture")
			if(!authenticated(user))
				return
			var/picture = params["picture"]
			if(!(picture in GLOB.status_display_approved_pictures))
				return
			if(picture in GLOB.status_display_state_pictures)
				post_status(picture)
			else
				if(picture == "currentalert")
					post_status("alert", SSsecurity_level?.current_security_level?.status_display_icon_state || "greenalert")
				else
					post_status("alert", picture)

		if("toggleAuthentication")
			if(authorize_name)
				authenticated = FALSE
				authorize_access = null
				authorize_name = null
				playsound(src, 'sound/machines/terminal/terminal_off.ogg', 50, FALSE)
				return

			if(obj_flags & EMAGGED)
				authenticated = TRUE
				authorize_access = SSid_access.get_region_access_list(list(REGION_ALL_STATION))
				authorize_name = "Unknown"
				to_chat(user, span_warning("[src] lets out a quiet alarm as its login is overridden."))
				playsound(src, 'sound/machines/terminal/terminal_alert.ogg', 25, FALSE)
			else if(isliving(user))
				var/mob/living/L = user
				var/obj/item/card/id/id_card = L.get_idcard(hand_first = TRUE)
				if(check_access(id_card))
					authenticated = TRUE
					authorize_access = id_card.access.Copy()
					authorize_name = "[id_card.registered_name] - [id_card.assignment]"

			state = STATE_MAIN
			playsound(src, 'sound/machines/terminal/terminal_on.ogg', 50, FALSE)
			imprint_gps("Encrypted Communications Channel")

		if("toggleEmergencyAccess")
			if(emergency_access_cooldown(user))
				return
			if(!authenticated_as_silicon_or_captain(user))
				return
			if(GLOB.emergency_access)
				revoke_maint_all_access()
				user.log_message("disabled emergency maintenance access.", LOG_GAME)
				message_admins("[ADMIN_LOOKUPFLW(user)] disabled emergency maintenance access.")
				deadchat_broadcast(" disabled emergency maintenance access at [span_name("[get_area_name(user, TRUE)]")].", span_name("[user.real_name]"), user, message_type = DEADCHAT_ANNOUNCEMENT)
			else
				make_maint_all_access()
				user.log_message("enabled emergency maintenance access.", LOG_GAME)
				message_admins("[ADMIN_LOOKUPFLW(user)] enabled emergency maintenance access.")
				deadchat_broadcast(" enabled emergency maintenance access at [span_name("[get_area_name(user, TRUE)]")].", span_name("[user.real_name]"), user, message_type = DEADCHAT_ANNOUNCEMENT)
		if("requestSafeCodes")
			if(SSjob.assigned_captain)
				to_chat(user, span_warning("There is already an assigned Captain or Acting Captain on deck!"))
				return

			if(SSjob.safe_code_timer_id)
				to_chat(user, span_warning("The safe code has already been requested and is being delivered to your station!"))
				return

			if(SSjob.safe_code_requested)
				to_chat(user, span_warning("The safe code has already been requested and delivered to your station!"))
				return

			if(!SSid_access.spare_id_safe_code)
				to_chat(user, span_warning("There is no safe code to deliver to your station!"))
				return

			var/turf/pod_location = get_turf(src)

			SSjob.safe_code_request_loc = pod_location
			SSjob.safe_code_requested = TRUE
			SSjob.safe_code_timer_id = addtimer(CALLBACK(SSjob, TYPE_PROC_REF(/datum/controller/subsystem/job, send_spare_id_safe_code), pod_location), 120 SECONDS, TIMER_UNIQUE | TIMER_STOPPABLE)
			minor_announce("Из-за нехватки персонала вашей станции была одобрена доставка кодов доступа к запасной ID карте капитана. Доставка с помощью портала произойдёт в [get_area(pod_location)]. Время ожидания: 120 секунд.")

// Requests Console overrides
#define ANNOUNCEMENT_COOLDOWN_TIME (30 SECONDS)
#define REQ_EMERGENCY_SECURITY "Security"
#define REQ_EMERGENCY_ENGINEERING "Engineering"
#define REQ_EMERGENCY_MEDICAL "Medical"

/obj/machinery/requests_console
	var/datum/announcement_recorder/recorder

/obj/machinery/requests_console/Destroy()
	QDEL_NULL(recorder)
	return ..()

/obj/machinery/requests_console/Hear(atom/movable/speaker, message_langs, raw_message, radio_freq, radio_freq_name, radio_freq_color, spans, list/message_mods = list(), message_range)
	. = ..()
	if(!QDELETED(recorder) && recorder.recording && !radio_freq)
		recorder.capture_fragment(speaker, raw_message)

/obj/machinery/requests_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(action == "open_recorder")
		start_recording_announcement(usr)
		return TRUE

	switch(action)
		if("clear_message_status")
			has_mail_send_error = FALSE
			for(var/obj/machinery/requests_console/console in GLOB.req_console_all)
				if(console.department == department)
					console.new_message_priority = REQ_NO_NEW_MESSAGE
					console.update_appearance()
			return TRUE
		if("clear_authentication")
			message_stamped_by = ""
			message_verified_by = ""
			announcement_authenticated = FALSE
			return TRUE
		if("toggle_silent")
			silent = !silent
			return TRUE
		if("set_emergency")
			if(emergency)
				return

			var/emergency_type = params["emergency"]
			var/origin_dept = reta_get_user_department_by_name(department)
			var/target_dept = null

			switch(emergency_type)
				if(REQ_EMERGENCY_SECURITY)
					target_dept = "Security"
				if(REQ_EMERGENCY_ENGINEERING)
					target_dept = "Engineering"
				if(REQ_EMERGENCY_MEDICAL)
					target_dept = "Medical"

			var/user_dept = reta_get_user_department(usr)
			if(user_dept == target_dept && !isAdminGhostAI(usr))
				to_chat(usr, span_alert("You cannot call your own department for emergency assistance."))
				return

			if(origin_dept && target_dept && reta_on_cooldown(origin_dept, target_dept))
				to_chat(usr, span_alert("Emergency calls to [target_dept] are on cooldown."))
				return

			emergency = emergency_type

			var/caller_info = ""
			if(usr && isliving(usr))
				caller_info = "(Identification not provided)"
				var/mob/living/caller_mob = usr
				var/obj/item/card/id/ID = caller_mob.get_idcard()
				if(ID)
					caller_info = "(Called by [ID.registered_name], [ID.assignment])"
				else if(issilicon(caller_mob))
					caller_info = "(Called by [caller_mob.name], [caller_mob.job])"
					if(iscyborg(caller_mob) && caller_mob?.mind?.assigned_role)
						caller_info = "(Called by [caller_mob.name], [caller_mob.mind.assigned_role.title])"
				else if(message_verified_by)
					caller_info = "(Last authentication: [message_verified_by])"
					message_stamped_by = ""
					message_verified_by = ""

			if(origin_dept && target_dept && CONFIG_GET(flag/reta_enabled))
				var/cooldown_ds = CONFIG_GET(number/reta_dept_cooldown_ds) || 150
				reta_set_cooldown(origin_dept, target_dept, cooldown_ds)

				var/duration_ds = CONFIG_GET(number/reta_duration_ds) || 3000
				var/granted_count = reta_find_and_grant_access(target_dept, origin_dept, duration_ds)

				reta_track_call(origin_dept, target_dept)

				switch(emergency_type)
					if(REQ_EMERGENCY_SECURITY)
						aas_config_announce(/datum/aas_config_entry/rc_emergency, list("LOCATION" = department, "CALLER" = caller_info, "RETARESPONDERS" = granted_count), src, list(RADIO_CHANNEL_SECURITY), "Security")
					if(REQ_EMERGENCY_ENGINEERING)
						aas_config_announce(/datum/aas_config_entry/rc_emergency, list("LOCATION" = department, "CALLER" = caller_info, "RETARESPONDERS" = granted_count), src, list(RADIO_CHANNEL_ENGINEERING), "Engineering")
					if(REQ_EMERGENCY_MEDICAL)
						aas_config_announce(/datum/aas_config_entry/rc_emergency, list("LOCATION" = department, "CALLER" = caller_info, "RETARESPONDERS" = granted_count), src, list(RADIO_CHANNEL_MEDICAL), "Medical")

				var/list/target_channels = list()
				switch(origin_dept)
					if("Security")
						target_channels += RADIO_CHANNEL_SECURITY
					if("Engineering")
						target_channels += RADIO_CHANNEL_ENGINEERING
					if("Medical")
						target_channels += RADIO_CHANNEL_MEDICAL
					if("Science")
						target_channels += RADIO_CHANNEL_SCIENCE
					if("Service")
						target_channels += RADIO_CHANNEL_SERVICE
					if("Command")
						target_channels += RADIO_CHANNEL_COMMAND
					if("Cargo")
						target_channels += RADIO_CHANNEL_SUPPLY
					if("Mining")
						target_channels += RADIO_CHANNEL_SUPPLY

				if(granted_count)
					aas_config_announce(/datum/aas_config_entry/rc_reta_announcement, list("GRANTEE" = target_dept, "CALLER" = caller_info), src, target_channels)

				log_game("RETA: [origin_dept] called [target_dept] emergency, granted access to [granted_count] responder IDs for [duration_ds/10] seconds")
				reta_push_ui_updates(origin_dept, target_dept)
				addtimer(CALLBACK(src, PROC_REF(clear_emergency)), duration_ds)
			else
				switch(emergency_type)
					if(REQ_EMERGENCY_SECURITY)
						aas_config_announce(/datum/aas_config_entry/rc_emergency, list("LOCATION" = department, "CALLER" = caller_info), null, list(RADIO_CHANNEL_SECURITY), "Security")
					if(REQ_EMERGENCY_ENGINEERING)
						aas_config_announce(/datum/aas_config_entry/rc_emergency, list("LOCATION" = department, "CALLER" = caller_info), null, list(RADIO_CHANNEL_ENGINEERING), "Engineering")
					if(REQ_EMERGENCY_MEDICAL)
						aas_config_announce(/datum/aas_config_entry/rc_emergency, list("LOCATION" = department, "CALLER" = caller_info), null, list(RADIO_CHANNEL_MEDICAL), "Medical")
				addtimer(CALLBACK(src, PROC_REF(clear_emergency)), 5 MINUTES)

			update_appearance()
			return TRUE
		if("send_announcement")
			if(!COOLDOWN_FINISHED(src, announcement_cooldown))
				to_chat(usr, span_alert("Intercomms recharging. Please stand by."))
				return
			if(!can_send_announcements)
				return
			if(!(announcement_authenticated || isAdminGhostAI(usr)))
				return

			var/message = reject_bad_text(trim(html_encode(params["message"]), MAX_MESSAGE_LEN), ascii_only = FALSE)
			if(!message)
				to_chat(usr, span_alert("Invalid message."))
				return
			if(isliving(usr))
				var/mob/living/L = usr
				message = L.treat_message(message)["message"]

			minor_announce(message, "[department] объявляет", html_encode = FALSE, sound_override = 'sound/announcer/announcement/announce_dig.ogg', tts_override = usr.GetComponent(/datum/component/tts_component))
			GLOB.news_network.submit_article(message, department, NEWSCASTER_STATION_ANNOUNCEMENTS, null)
			usr.log_talk(message, LOG_SAY, tag="station announcement from [src]")
			message_admins("[ADMIN_LOOKUPFLW(usr)] has made a station announcement from [src] at [AREACOORD(usr)].")
			deadchat_broadcast(" made a station announcement from [span_name("[get_area_name(usr, TRUE)]")].", span_name("[usr.real_name]"), usr, message_type=DEADCHAT_ANNOUNCEMENT)

			COOLDOWN_START(src, announcement_cooldown, ANNOUNCEMENT_COOLDOWN_TIME)
			announcement_authenticated = FALSE
			return TRUE
		if("quick_reply")
			var/recipient = params["reply_recipient"]

			var/reply_message = reject_bad_text(tgui_input_text(usr, "Write a quick reply to [recipient]", "Awaiting Input"), ascii_only = FALSE)
			if(QDELETED(ui) || ui.status != UI_INTERACTIVE)
				return
			if(!reply_message)
				has_mail_send_error = TRUE
				playsound(src, 'sound/machines/buzz/buzz-two.ogg', 50, TRUE)
				return TRUE

			send_message(recipient, reply_message, REQ_NORMAL_MESSAGE_PRIORITY, REPLY_REQUEST)
			return TRUE
		if("send_message")
			var/recipient = params["recipient"]
			if(!recipient)
				return
			var/priority = params["priority"]
			if(!priority)
				return
			var/message = reject_bad_text(trim(html_encode(params["message"]), MAX_MESSAGE_LEN), ascii_only = FALSE)
			if(!message)
				to_chat(usr, span_alert("Invalid message."))
				has_mail_send_error = TRUE
				return TRUE
			var/request_type = params["request_type"]
			if(!request_type)
				return
			send_message(recipient, message, priority, request_type)
			return TRUE

/obj/machinery/requests_console/proc/start_recording_announcement(mob/user)
	if(!can_send_announcements)
		to_chat(user, span_alert("This console is not configured for announcements."))
		return
	if(!(announcement_authenticated || isAdminGhostAI(user)))
		to_chat(user, span_alert("Authentication required for announcements."))
		return
	if(recorder)
		QDEL_NULL(recorder)
	recorder = new /datum/announcement_recorder(src, "minor")
	recorder.ui_interact(user)

/datum/announcement_recorder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AnnouncementRecorder")
		ui.open()

/datum/announcement_recorder/ui_data(mob/user)
	var/list/data = list()
	data["recording"] = recording
	data["range"] = record_range
	data["fragments"] = get_fragments_ui_data()
	data["fragments_count"] = length(fragments)
	data["elapsed"] = recording ? round((world.time - start_time) / 10, 1) : 0
	data["max_duration"] = MAX_RECORD_DURATION / 10
	return data

/datum/announcement_recorder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("start")
			start_recording()
			return TRUE
		if("stop")
			stop_recording(send_announcement = TRUE)
			return TRUE
		if("cancel")
			cancel_recording()
			SStgui.close_uis(src)
			qdel(src)
			return TRUE
		if("set_range")
			if(recording)
				return TRUE
			var/new_range = clamp(text2num(params["range"]), RECORD_RANGE_MIN, RECORD_RANGE_MAX)
			record_range = new_range
			return TRUE
		if("close")
			if(!recording)
				SStgui.close_uis(src)
			return TRUE

/datum/announcement_recorder/ui_close(mob/user)
	if(!recording)
		qdel(src)

#undef MAX_RECORD_DURATION
#undef RECORD_RANGE_MIN
#undef RECORD_RANGE_MAX
#undef RECORD_RANGE_DEFAULT
#undef IMPORTANT_ACTION_COOLDOWN
#undef EMERGENCY_ACCESS_COOLDOWN
#undef STATE_BUYING_SHUTTLE
#undef STATE_CHANGING_STATUS
#undef STATE_MAIN
#undef STATE_MESSAGES
#undef ANNOUNCEMENT_COOLDOWN_TIME
#undef REQ_EMERGENCY_SECURITY
#undef REQ_EMERGENCY_ENGINEERING
#undef REQ_EMERGENCY_MEDICAL
