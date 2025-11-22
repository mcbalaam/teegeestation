#define SPEED_MOD 5
#define PX_OFFSET 16 //half of total px size of sprite
//Cars that drift with inertia physics
//By Fermi!

/obj/vehicle/ridden/atv/vectorcraft
	name = "all-terrain hovercraft"
	desc = "An all-terrain vehicle built for traversing rough terrain with ease. One of the few old-Earth technologies that are still relevant on most planet-bound outposts."
	icon_state = "atv"
	max_integrity = 100

	var/vector = list("x" = 0, "y" = 0) //vector math
	var/tile_loc = list("x" = 0, "y" = 0) //x y offset of tile
	var/max_acceleration = 5.25
	var/accel_step = 0.3
	var/acceleration = 0.4
	var/max_deceleration = 2
	var/max_velocity = 110
/obj/vehicle/ridden/atv/vectorcraft/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/atv)

/obj/vehicle/ridden/atv/vectorcraft/post_buckle_mob(mob/living/M)
	start_engine()
	to_chat(M, "<span class='big notice'>How to drive:</span> \n<span class='notice'><i>Hold wasd to gain speed in a direction, c to enable/disable the clutch, 1 2 3 4 to change gears while holding a direction (make sure the clutch is enabled when you change gears, you should hear a sound when you've successfully changed gears), r to toggle handbrake, hold alt for brake and press shift for boost (the machine will beep when the boost is recharged)! If you hear an ebbing sound like \"brbrbrbrbr\" you need to gear down, the whining sound means you need to gear up. Hearing a pleasant \"whumwhumwhum\" is optimal gearage! It can be a lil slow to start, so make sure you're in the 1st gear.\n</i></span>")
	return ..()

/obj/vehicle/ridden/atv/vectorcraft/post_unbuckle_mob(mob/living/M)
	if(!has_buckled_mobs())
		stop_engine()

	return ..()

/// Override Move to disable standard movement - we use custom inertia physics only
/obj/vehicle/ridden/atv/vectorcraft/Move(destination, direction = NONE, continuous_move = FALSE)
	return FALSE // Don't allow standard movement


//////////////////////////////////////////////////////////////
//					Main driving checks				    	//
//////////////////////////////////////////////////////////////

/obj/vehicle/ridden/atv/vectorcraft/proc/start_engine()
	if(!has_buckled_mobs())
		return
	START_PROCESSING(SSvectorcraft, src)

/obj/vehicle/ridden/atv/vectorcraft/proc/stop_engine()
	STOP_PROCESSING(SSvectorcraft, src)
	vector = list("x" = 0, "y" = 0)
	acceleration = initial(acceleration)

//Passive hover drift and position update
/obj/vehicle/ridden/atv/vectorcraft/proc/hover_loop()
	if(!has_buckled_mobs())
		return
	var/mob/living/driver = buckled_mobs[1]

	// Apply deceleration based on movement intent
	if(driver.move_intent == MOVE_INTENT_WALK)
		var/deceleration = max_deceleration
		if(driver.throw_mode)
			deceleration *= 1.5
		friction(deceleration, TRUE)
	else if(driver.throw_mode)
		friction(max_deceleration*1.2, TRUE)
	else
		// Apply passive drift friction only when not actively braking
		friction(max_deceleration/4)

	// Update position based on current vector
	update_position()

//Process loop for inertia
/obj/vehicle/ridden/atv/vectorcraft/process(seconds_per_tick)
	if(!has_buckled_mobs())
		stop_engine()
		return PROCESS_KILL

	var/mob/living/driver = buckled_mobs[1]
	if(!driver || driver.stat == DEAD)
		return

	// Apply acceleration in the direction the driver is facing
	if(driver.dir)
		calc_acceleration(driver)
		calc_vector(driver.dir, driver)

	// Apply friction from not moving
	hover_loop()

//////////////////////////////////////////////////////////////
//					Movement procs						   	//
//////////////////////////////////////////////////////////////

/obj/vehicle/ridden/atv/vectorcraft/proc/update_position()
	var/cached_tile = tile_loc
	tile_loc["x"] += vector["x"]/SPEED_MOD
	tile_loc["y"] += vector["y"]/SPEED_MOD
	//range = -16 to 16
	var/x_move = 0
	if(tile_loc["x"] > PX_OFFSET)
		x_move = round((tile_loc["x"]+PX_OFFSET) / (PX_OFFSET*2), 1)
		tile_loc["x"] = ((tile_loc["x"]+PX_OFFSET) % (PX_OFFSET*2))-PX_OFFSET
	else if(tile_loc["x"] < -PX_OFFSET)
		x_move = round((tile_loc["x"]-PX_OFFSET) / (PX_OFFSET*2), 1)
		tile_loc["x"] = ((tile_loc["x"]-PX_OFFSET) % -(PX_OFFSET*2))+PX_OFFSET



	var/y_move = 0
	if(tile_loc["y"] > PX_OFFSET)
		y_move = round((tile_loc["y"]+PX_OFFSET) / (PX_OFFSET*2), 1)
		tile_loc["y"] = ((tile_loc["y"]+PX_OFFSET) % (PX_OFFSET*2))-PX_OFFSET
	else if(tile_loc["y"] < -PX_OFFSET)
		y_move = round((tile_loc["y"]-PX_OFFSET) / (PX_OFFSET*2), 1)
		tile_loc["y"] = ((tile_loc["y"]-PX_OFFSET) % -(PX_OFFSET*2))+PX_OFFSET

	if(!(x_move == 0 && y_move == 0))
		var/turf/T = get_offset_target_turf(src, x_move, y_move)
		for(var/atom/A in T.contents)
			Bump(A)
			if(A.density)
				ricochet()
				tile_loc = cached_tile
				return FALSE
		if(T.density)
			ricochet()
			tile_loc = cached_tile
			return FALSE

	x += x_move
	y += y_move
	pixel_x = round(tile_loc["x"], 1)
	pixel_y = round(tile_loc["y"], 1)

	// Notify riding component about the movement
	if(x_move || y_move)
		SEND_SIGNAL(src, COMSIG_MOVABLE_MOVED, x - x_move, y - y_move, null, TRUE)

	if(buckled_mobs.len)
		for(var/mob/living/buckled_mob in buckled_mobs)
			if(buckled_mob.client)
				buckled_mob.client.pixel_x = pixel_x
				buckled_mob.client.pixel_y = pixel_y

	if(x_move == 0 && y_move == 0)
		return FALSE

	//var/direction = calc_step_angle(x_move, y_move)
	//if(direction) //If the movement is greater than 2
	//	step(src, direction)
	//	after_move(direction)




	return TRUE

//////////////////////////////////////////////////////////////
//					Check procs						    	//
//////////////////////////////////////////////////////////////

//Bounce the car off a wall
/obj/vehicle/ridden/atv/vectorcraft/proc/bounce()
	vector["x"] = -vector["x"]/2
	vector["y"] = -vector["y"]/2
	acceleration /= 2

/obj/vehicle/ridden/atv/vectorcraft/proc/ricochet(x_move, y_move)
	var/speed = calc_speed()
	apply_damage(speed/10)
	bounce()

//////////////////////////////////////////////////////////////
//					Damage procs							//
//////////////////////////////////////////////////////////////
//Repairing
/obj/vehicle/ridden/atv/vectorcraft/attackby(obj/item/O, mob/living/carbon/human/user, params)
	. = ..()
	if(istype(O, /obj/item/weldingtool) && !user.combat_mode)
		if(atom_integrity < max_integrity)
			if(!O.tool_start_check(user, amount=0))
				return
			user.visible_message("[user] begins repairing [src].", span_notice("Вы начинаете чинить [src]..."), span_hear("You hear welding."))
			if(O.use_tool(src, user, 40, volume=50))
				to_chat(user, span_notice("Вы починили [src]."))
				apply_damage(-max_integrity)
		else
			to_chat(user, span_notice("[src] does not need repairs."))


/obj/vehicle/ridden/atv/vectorcraft/attack_hand(mob/user)
	if(buckled_mobs.len)
		unbuckle_all_mobs()
	..()

//Heals/damages the car
/obj/vehicle/ridden/atv/vectorcraft/proc/apply_damage(damage)
	atom_integrity -= damage
	var/healthratio = ((atom_integrity/max_integrity)/4) + 0.75
	max_acceleration = initial(max_acceleration) * healthratio
	max_deceleration = initial(max_deceleration) * healthratio

	if(atom_integrity <= 0)
		explosion(src, devastation_range = -1, light_impact_range = 2, flame_range = 3, flash_range = 4)
		visible_message("The [src] explodes from taking too much damage!")
		qdel(src)
	if(atom_integrity > max_integrity)
		atom_integrity = max_integrity

//Collision handling
/obj/vehicle/ridden/atv/vectorcraft/Bump(atom/M)
	var/speed = calc_speed()
	if(isliving(M))
		var/mob/living/C = M
		if(!C.anchored)
			var/atom/throw_target = get_edge_target_turf(C, calc_angle())
			C.throw_at(throw_target, 10, 14)
		to_chat(C, "<span class='warning'><b>You are hit by the [src]!</b></span>")
		if(buckled_mobs.len)
			var/mob/living/driver = buckled_mobs[1]
			to_chat(driver, "<span class='warning'><b>You just ran into [C] you crazy lunatic!</b></span>")
		C.adjustBruteLoss(speed/10)
		return
	if(istype(M, /obj/vehicle/ridden/atv/vectorcraft))
		var/obj/vehicle/ridden/atv/vectorcraft/Vc = M
		Vc.apply_damage(speed/5)
		Vc.vector["x"] += vector["x"]/2
		Vc.vector["y"] += vector["y"]/2
		apply_damage(speed/10)
		bounce()
		return
	// Bounce off dense objects
	if(ismovable(M) && M.density)
		ricochet()
		return
	return ..()

//////////////////////////////////////////////////////////////
//					Calc procs						    	//
//////////////////////////////////////////////////////////////
/*Calc_step_angle calculates angle based off pixel x,y movement (x,y in)
Calc angle calcus angle based off vectors
calc_speed() returns the highest var of x or y relative
calc accel calculates the acceleration to be added to vector
calc vector updates the internal vector
friction reduces the vector by an ammount to both axis*/

//How fast the car is going atm (Depreciated - kept for reference)
/obj/vehicle/ridden/atv/vectorcraft/proc/calc_velocity()
	var/speed = calc_speed()
	return speed

/obj/vehicle/ridden/atv/vectorcraft/proc/calc_step_angle(x, y)
	if((sqrt(x**2))>1 || (sqrt(y**2))>1) //Too large a movement for a step
		return FALSE
	if(x == 1)
		if (y == 1)
			return NORTHEAST
		else if (y == -1)
			return SOUTHEAST
		else if (y == 0)
			return EAST
		else
			message_admins("something went wrong; y = [y]")
	else if (x == -1)
		if (y == 1)
			return NORTHWEST
		else if (y == -1)
			return SOUTHWEST
		else if (y == 0)
			return WEST
		else
			message_admins("something went wrong; y = [y]")
	else if (x != 0)
		message_admins("something went wrong; x = [x]")

	if (y == 1)
		return NORTH
	else if (y == -1)
		return SOUTH
	else if (x != 0)
		message_admins("something went wrong; y = [y]")
	return FALSE

//Returns the angle to move towards
/obj/vehicle/ridden/atv/vectorcraft/proc/calc_angle()
	var/x = round(vector["x"], 1)
	var/y = round(vector["y"], 1)
	if(y == 0)
		if(x > 0)
			return EAST
		else if(x < 0)
			return WEST
	if(x == 0)
		if(y > 0)
			return NORTH
		else if(y < 0)
			return SOUTH
	if(x == 0 || y == 0)
		return FALSE
	var/angle = (ATAN2(x,y))
	//if(angle < 0)
	//	angle += 360
	//message_admins("x:[x], y: [y], angle:[angle]")

	//I WISH I HAD RADIANSSSSSSSSSS
	if(angle > 0)
		switch(angle)
			if(0 to 22)
				return EAST
			if(22 to 67)
				return NORTHEAST
			if(67 to 112)
				return NORTH
			if(112 to 157)
				return NORTHWEST
			if(157 to 180)
				return WEST
	else
		switch(angle)
			if(-22 to 0)
				return EAST
			if(-67 to -22)
				return SOUTHEAST
			if(-112 to -67)
				return SOUTH
			if(-157 to -112)
				return SOUTHWEST
			if(-180 to -157)
				return WEST


//updates the internal speed of the car (used for crashing)
/obj/vehicle/ridden/atv/vectorcraft/proc/calc_speed()
	var/speed = max(sqrt((vector["x"]**2)), sqrt((vector["y"]**2)))
	return speed

//Calculates the acceleration
/obj/vehicle/ridden/atv/vectorcraft/proc/calc_acceleration(mob/living/driver)
	acceleration += accel_step
	acceleration = clamp(acceleration, initial(acceleration), max_acceleration)

//calulate the vector change
/obj/vehicle/ridden/atv/vectorcraft/proc/calc_vector(direction, mob/living/driver)
	var/new_x = vector["x"]
	var/new_y = vector["y"]

	switch(direction)
		if(NORTH)
			new_y += acceleration
		if(NORTHEAST)
			new_x += acceleration/1.4
			new_y += acceleration/1.4
		if(EAST)
			new_x += acceleration
		if(SOUTHEAST)
			new_x += acceleration/1.4
			new_y -= acceleration/1.4
		if(SOUTH)
			new_y -= acceleration
		if(SOUTHWEST)
			new_x -= acceleration/1.4
			new_y -= acceleration/1.4
		if(WEST)
			new_x -= acceleration
		if(NORTHWEST)
			new_y += acceleration/1.4
			new_x -= acceleration/1.4

	new_x = clamp(new_x, -max_velocity, max_velocity)
	new_y = clamp(new_y, -max_velocity, max_velocity)

	vector["x"] = new_x
	vector["y"] = new_y

	return

//Reduces speed smoothly
/obj/vehicle/ridden/atv/vectorcraft/proc/friction(change, sfx = FALSE)
	if(vector["x"] == 0 && vector["y"] == 0)
		return

	// Apply friction proportionally to current velocity
	var/magnitude = sqrt((vector["x"]**2) + (vector["y"]**2))
	if(magnitude <= change)
		vector["x"] = 0
		vector["y"] = 0
	else
		// Normalize and reduce
		var/reduction = 1 - (change / magnitude)
		vector["x"] *= reduction
		vector["y"] *= reduction

