/datum/announcement_fragment
	var/timestamp
	var/speaker_name
	var/text
	var/tts_seed

/datum/announcement_fragment/New(timestamp, speaker_name, text, tts_seed)
	src.timestamp = timestamp
	src.speaker_name = speaker_name
	src.text = text
	src.tts_seed = tts_seed

/datum/announcement_fragment/proc/get_formatted_text()
	return "[speaker_name]: [text]"
