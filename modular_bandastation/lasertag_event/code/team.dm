/// Lasertag Team Datum
/// Manages team members, scoring, and team-specific data
/datum/lasertag_team
	/// Team color identifier ("red", "blue")
	var/team_color
	/// Reference to the game controller
	var/datum/lasertag_controller/controller
	/// Team score
	var/score = 0
	/// List of team members (ckey -> /datum/component/lasertag_kit)
	var/list/members = list()
	/// Team spawner reference (placeholder)
	var/obj/machinery/lasertag_spawner
	/// Team span for colored messages
	var/team_span = ""

/datum/lasertag_team/New(team_color, datum/lasertag_controller/controller)
	. = ..()
	src.team_color = team_color
	src.controller = controller
	
	// Set team span for colored chat
	switch(team_color)
		if("red")
			team_span = "redtext"
		if("blue")
			team_span = "bluetext"

/datum/lasertag_team/Destroy(force)
	members.Cut()
	controller = null
	lasertag_spawner = null
	return ..()

/// Add a member to the team
/datum/lasertag_team/proc/add_member(ckey, datum/component/lasertag_kit/kit)
	members[ckey] = kit
	message_team("[ckey] joined [team_color] team!")

/// Remove a member from the team
/datum/lasertag_team/proc/remove_member(ckey)
	if(!members[ckey])
		return
	members -= ckey
	message_team("[ckey] left [team_color] team.")

/// Add score to team
/datum/lasertag_team/proc/add_score(points)
	score += points

/// Get team size
/datum/lasertag_team/proc/get_size()
	return members.len

/// Message all team members
/datum/lasertag_team/proc/message_team(message)
	for(var/ckey in members)
		var/datum/component/lasertag_kit/kit = members[ckey]
		if(kit && kit.parent)
			var/mob/living/owner = kit.parent
			to_chat(owner, span_notice("[message]"))
