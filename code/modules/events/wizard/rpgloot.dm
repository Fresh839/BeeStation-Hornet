/datum/round_event_control/wizard/rpgloot //its time to minmax your shit
	name = "RPG Loot"
	weight = 3
	typepath = /datum/round_event/wizard/rpgloot
	max_occurrences = 1
	earliest_start = 0 MINUTES

/datum/round_event/wizard/rpgloot/start()
	var/upgrade_scroll_chance = 0
	for(var/obj/item/I in world)
		CHECK_TICK

		if(!(I.flags_1 & INITIALIZED_1))
			continue

		if(!istype(I.rpg_loot))
			I.rpg_loot = new(I)

		if(istype(I, /obj/item/storage))
			var/obj/item/storage/S = I
			if(prob(upgrade_scroll_chance) && S.contents.len < I.atom_storage.max_slots && !S.invisibility)
				var/obj/item/upgradescroll/scroll = new(get_turf(S))
				I.atom_storage?.attempt_insert(S, scroll, null, TRUE, TRUE)
				upgrade_scroll_chance = max(0,upgrade_scroll_chance-100)
				if(isturf(scroll.loc))
					qdel(scroll)

			upgrade_scroll_chance += 25

	GLOB.rpg_loot_items = TRUE

/obj/item/upgradescroll
	name = "item fortification scroll"
	desc = "Somehow, this piece of paper can be applied to items to make them \"better\". Apparently there's a risk of losing the item if it's already \"too good\". <i>This all feels so arbitrary...</i>"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "scroll"
	w_class = WEIGHT_CLASS_TINY

	var/upgrade_amount = 1
	var/can_backfire = TRUE
	var/uses = 1

/obj/item/upgradescroll/afterattack(obj/item/target, mob/user , proximity)
	. = ..()
	if(!proximity || !istype(target))
		return

	var/datum/rpg_loot/rpg_loot_datum = target.rpg_loot
	var/turf/T = get_turf(target)

	if(!istype(rpg_loot_datum))
		var/original_name = "[target]"
		target.rpg_loot = rpg_loot_datum = new /datum/rpg_loot(target)

		var/span
		var/effect_description
		if(target.rpg_loot.quality >= 0)
			span = "<span class='notice'>"
			effect_description = span_heavybrass("shimmering golden shield")
		else
			span = "<span class='danger'>"
			effect_description = span_umbraemphasis("mottled black glow")

		T.visible_message("[span][original_name] is covered by a [effect_description] and then transforms into [target]!</span>")

	else
		var/quality = rpg_loot_datum.quality

		if(can_backfire && quality > 9 && prob((quality - 9)*10))
			T.visible_message(span_danger("[target] [span_inathneqlarge("violently glows blue")] for a while, then evaporates."))
			target.burn()
		else
			T.visible_message(span_notice("[target] [span_inathneqsmall("glows blue")] and seems vaguely \"better\"!"))
			rpg_loot_datum.modify(upgrade_amount)

	if(--uses <= 0)
		qdel(src)

/obj/item/upgradescroll/unlimited
	name = "unlimited foolproof item fortification scroll"
	desc = "Somehow, this piece of paper can be applied to items to make them \"better\". This scroll is made from the tongues of dead paper wizards, and can be used an unlimited number of times, with no drawbacks."
	uses = INFINITY
	can_backfire = FALSE

/datum/rpg_loot
	var/positive_prefix = "okay"
	var/negative_prefix = "weak"
	var/suffix = "something profound"
	var/quality = 0

	var/obj/item/attached
	var/original_name

/datum/rpg_loot/New(attached_item=null)
	attached = attached_item

	randomise()

/datum/rpg_loot/Destroy()
	QDEL_NULL(attached)
	return ..()

/datum/rpg_loot/proc/randomise()
	var/static/list/prefixespositive = list("greater", "major", "blessed", "superior", "empowered", "honed", "true", "glorious", "robust")
	var/static/list/prefixesnegative = list("lesser", "minor", "blighted", "inferior", "enfeebled", "rusted", "unsteady", "tragic", "gimped")
	var/static/list/suffixes = list("orc slaying", "elf slaying", "corgi slaying", "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma", "the forest", "the hills", "the plains", "the sea", "the sun", "the moon", "the void", "the world", "the fool", "many secrets", "many tales", "many colors", "rending", "sundering", "the night", "the day")

	var/new_quality = pick(1;15, 2;14, 2;13, 2;12, 3;11, 3;10, 3;9, 4;8, 4;7, 4;6, 5;5, 5;4, 5;3, 6;2, 6;1, 6;0)

	suffix = pick(suffixes)
	positive_prefix = pick(prefixespositive)
	negative_prefix = pick(prefixesnegative)

	if(prob(50))
		new_quality = -new_quality

	modify(new_quality)

/datum/rpg_loot/proc/rename()
	var/obj/item/I = attached
	if(!original_name)
		original_name = I.name
	if(quality < 0)
		I.name = "[negative_prefix] [original_name] of [suffix] [quality]"
	else if(quality == 0)
		I.name = "[original_name] of [suffix]"
	else if(quality > 0)
		I.name = "[positive_prefix] [original_name] of [suffix] +[quality]"

/datum/rpg_loot/proc/modify(quality_mod)
	var/obj/item/I = attached
	quality += quality_mod

	I.force = max(0,I.force + quality_mod)
	I.throwforce = max(0,I.throwforce + quality_mod)

	I.set_armor(I.get_armor().generate_new_with_modifiers(list(ARMOR_ALL = -quality)))

	rename()
