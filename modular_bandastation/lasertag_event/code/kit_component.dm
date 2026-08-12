/// Lasertag Kit Component
/// Attached to player mob, manages HP, team, scoring, and kit state
/datum/component/lasertag_kit
	/// Current HP of the kit
	var/hp = LASERTAG_KIT_DEFAULT_HP
	/// Maximum HP of the kit
	var/max_hp = LASERTAG_KIT_DEFAULT_HP
	/// Is kit active (can shoot/take damage)
	var/active = TRUE
	/// Team color ("red", "blue", or null for FFA)
	var/team_color
	/// Reference to game controller
	var/datum/lasertag_controller/controller
	/// Player's role (placeholder for future implementation)
	var/role_type
	
	/// Equipment references
	var/obj/item/clothing/suit/armor/vest/lasertag/vest
	var/obj/item/clothing/head/lasertag_band/headband
	var/obj/item/gun/energy/lasertag/blaster
	
	/// Statistics
	var/score = 0
	var/kills = 0
	var/deaths = 0
	var/shots_fired = 0
	var/shots_hit = 0

/datum/component/lasertag_kit/Initialize(datum/lasertag_controller/controller, team_color, max_hp = LASERTAG_KIT_DEFAULT_HP)
	. = ..()
	
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	
	src.controller = controller
	src.team_color = team_color
	src.max_hp = max_hp
	src.hp = max_hp
	
	// Register signals
	RegisterSignal(parent, COMSIG_ATOM_HITBY, PROC_REF(on_hit_by))
	RegisterSignal(parent, COMSIG_MOB_FIRED_GUN, PROC_REF(on_fired_gun))
	
	// Add to controller
	var/mob/living/owner = parent
	controller.add_player(owner.ckey, team_color, src)

/datum/component/lasertag_kit/Destroy(force, silent)
	// Remove from controller
	var/mob/living/owner = parent
	if(owner && controller)
		controller.remove_player(owner.ckey)
	
	vest = null
	headband = null
	blaster = null
	controller = null
	role_type = null
	
	return ..()
