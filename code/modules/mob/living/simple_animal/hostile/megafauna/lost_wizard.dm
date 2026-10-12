/mob/living/simple_animal/hostile/megafauna/lost_wizard_phase_1
	name = "Lost Wizard"
	desc = "desc"
	health = 1250
	maxHealth = 1250
	attack_verb_continuous = "rends"
	attack_verb_simple = "rend"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	icon_state = "bubblegum"
	icon_living = "bubblegum"
	icon_dead = ""
	friendly_verb_continuous = "stares down"
	friendly_verb_simple = "stare down"
	icon = 'icons/mob/lavaland/96x96megafauna.dmi'
	speak_emote = list("gurgles")
	armour_penetration = 40
	melee_damage = 40
	speed = 5
	move_to_delay = 5
	retreat_distance = 5
	minimum_distance = 5
	rapid_melee = 8 // every 1/4 second
	melee_queue_distance = 20 // as far as possible really, need this because of blood warp
	ranged = TRUE
	pixel_x = -32
	base_pixel_x = -32
	del_on_death = TRUE
	loot = list(/obj/effect/spawner/random/unsorted/megafaunaore, /obj/structure/closet/crate/necropolis/bubblegum)
	wander = FALSE
	blood_volume = BLOOD_VOLUME_MAXIMUM //BLEED FOR ME
	var/charging = FALSE
	var/enrage_till = 0
	var/enrage_time = 70
	var/revving_charge = FALSE
	gps_name = "Bubbly Signal"
	achievement_type = /datum/award/achievement/boss/bubblegum_kill
	crusher_achievement_type = /datum/award/achievement/boss/bubblegum_crusher
	score_achievement_type = /datum/award/score/bubblegum_score
	death_message = "sinks into a pool of blood, fleeing the battle. You've won, for now... "
	death_sound = 'sound/magic/enter_blood.ogg'
	attack_action_types = list(/datum/action/innate/megafauna_attack/triple_charge,
							   /datum/action/innate/megafauna_attack/hallucination_charge,
							   /datum/action/innate/megafauna_attack/hallucination_surround,
							   /datum/action/innate/megafauna_attack/blood_warp)
	small_sprite_type = /datum/action/small_sprite/megafauna/bubblegum

/mob/living/simple_animal/hostile/megafauna/lost_wizard_phase_1/Initialize(mapload)
	. = ..()
	if(true_spawn)
		for(var/mob/living/simple_animal/hostile/megafauna/lost_wizard_phase_1/B in GLOB.mob_living_list)
			if(B != src)
				return INITIALIZE_HINT_QDEL //There can be only one


/mob/living/simple_animal/hostile/lost_wizard_phase_2
	name = "boss of this gym"
	desc = "Attack the weak point for massive damage."
	health = 500
	maxHealth = 500

	combat_mode = TRUE
	sentience_type = SENTIENCE_BOSS
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	mob_biotypes = MOB_ORGANIC | MOB_SPECIAL
	obj_damage = 400
	light_range = 3
	faction = list(FACTION_MINING, FACTION_BOSS)
	weather_immunities = list(TRAIT_LAVA_IMMUNE, TRAIT_ASHSTORM_IMMUNE)
	is_flying_animal = TRUE
	no_flying_animation = TRUE
	robust_searching = TRUE
	ranged_ignores_vision = TRUE
	stat_attack = HARD_CRIT
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	damage_coeff = list(BRUTE = 1, BURN = 0.5, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	minbodytemp = 0
	maxbodytemp = INFINITY
	vision_range = 5
	aggro_vision_range = 18
	move_force = MOVE_FORCE_OVERPOWERING
	move_resist = MOVE_FORCE_OVERPOWERING
	pull_force = MOVE_FORCE_OVERPOWERING
	mob_size = MOB_SIZE_LARGE
	layer = LARGE_MOB_LAYER //Looks weird with them slipping under mineral walls and cameras and shit otherwise
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	mouse_opacity = MOUSE_OPACITY_OPAQUE // Easier to click on in melee, they're giant targets anyway
	hardattacks = TRUE
	discovery_points = 10000
	var/achievement_type
	var/crusher_achievement_type
	var/score_achievement_type
	var/elimination = 0
	var/anger_modifier = 0
	var/gps_name = null
	var/recovery_time = 0
	var/true_spawn = TRUE // if this is a megafauna that should grant achievements, or have a gps signal
	var/nest_range = 10
	var/chosen_attack = 1 // chosen attack num
	var/list/attack_action_types = list()
	var/small_sprite_type
	/// Determines what a megafauna will say or do to telegraph its next attack. (Currently only used by Colossus). Set to 1 by default so the opening attack will always be the same.
	var/random_attack_num = 1



//spells

/datum/action/spell/cone/fire_lightning
	cone_levels = 3
	respect_density = FALSE

/datum/action/spell/cone/do_mob_cone_effect()
	