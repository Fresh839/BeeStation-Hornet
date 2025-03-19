//Baseline portable generator. Has all the default handling. Not intended to be used on it's own (since it generates unlimited power).
/obj/machinery/power/port_gen
	name = "portable generator"
	desc = "A portable generator for emergency backup power."
	icon = 'icons/obj/power.dmi'
	icon_state = "portgen0_0"
	density = TRUE
	anchored = FALSE
	use_power = NO_POWER_USE



	var/active = FALSE
	var/power_gen = 5000
	var/power_output = 1
	var/consumption = 0
	var/base_icon = "portgen0"
	var/datum/looping_sound/generator/soundloop

	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT | INTERACT_ATOM_REQUIRES_ANCHORED

/obj/machinery/power/port_gen/Initialize(mapload)
	. = ..()
	soundloop = new(src, active)

/obj/machinery/power/port_gen/Destroy()
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/power/port_gen/connect_to_network()
	if(!anchored)
		return FALSE
	. = ..()

/obj/machinery/power/port_gen/proc/HasFuel() //Placeholder for fuel check.
	return TRUE

/obj/machinery/power/port_gen/proc/UseFuel() //Placeholder for fuel use.
	return

/obj/machinery/power/port_gen/proc/DropFuel()
	return

/obj/machinery/power/port_gen/proc/handleInactive()
	return

/obj/machinery/power/port_gen/proc/TogglePower()
	if(active)
		active = FALSE
		update_icon()
		soundloop.stop()
	else if(HasFuel())
		active = TRUE
		START_PROCESSING(SSmachines, src)
		update_icon()
		soundloop.start()

/obj/machinery/power/port_gen/update_icon()
	icon_state = "[base_icon]_[active]"

/obj/machinery/power/port_gen/process()
	if(active)
		if(!HasFuel() || !anchored)
			TogglePower()
			return
		if(powernet)
			add_avail(power_gen * power_output)
		UseFuel()
	else
		handleInactive()

/obj/machinery/power/port_gen/examine(mob/user)
	. = ..()
	. += "It is[!active?"n't":""] running."

/////////////////
// P.A.C.M.A.N //
/////////////////
/obj/machinery/power/port_gen/pacman
	name = "\improper P.A.C.M.A.N.-type portable generator"
	circuit = /obj/item/circuitboard/machine/pacman
	var/sheets = 0
	var/max_sheets = 100
	var/sheet_name = ""
	var/sheet_path = /obj/item/stack/sheet/mineral/plasma
	var/sheet_left = 0 // How much is left of the sheet
	var/time_per_sheet = 260
	var/current_heat = 0

/obj/machinery/power/port_gen/pacman/Initialize(mapload)
	. = ..()
	if(anchored)
		connect_to_network()

/obj/machinery/power/port_gen/pacman/Initialize(mapload)
	. = ..()

	var/obj/S = sheet_path
	sheet_name = initial(S.name)

/obj/machinery/power/port_gen/pacman/Destroy()
	DropFuel()
	return ..()

/obj/machinery/power/port_gen/pacman/RefreshParts()
	var/temp_rating = 0
	var/consumption_coeff = 0
	for(var/obj/item/stock_parts/SP in component_parts)
		if(istype(SP, /obj/item/stock_parts/matter_bin))
			max_sheets = SP.rating * SP.rating * 50
		else if(istype(SP, /obj/item/stock_parts/capacitor))
			temp_rating += SP.rating
		else
			consumption_coeff += SP.rating
	power_gen = round(initial(power_gen) * temp_rating * 2)
	consumption = consumption_coeff

/obj/machinery/power/port_gen/pacman/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The generator has [sheets] units of [sheet_name] fuel left, producing [display_power(power_gen)] per cycle.</span>"
	if(anchored)
		. += "<span class='notice'>It is anchored to the ground.</span>"
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Fuel efficiency increased by <b>[(consumption*100)-100]%</b>.</span>"

/obj/machinery/power/port_gen/pacman/HasFuel()
	if(sheets >= 1 / (time_per_sheet / power_output) - sheet_left)
		return TRUE
	return FALSE

/obj/machinery/power/port_gen/pacman/DropFuel()
	if(sheets > 0)
		new sheet_path(drop_location(), sheets)
		sheets = 0

/obj/machinery/power/port_gen/pacman/UseFuel()
	var/needed_sheets = 1 / (time_per_sheet * consumption / power_output)
	var/temp = min(needed_sheets, sheet_left)
	needed_sheets -= temp
	sheet_left -= temp
	sheets -= round(needed_sheets)
	needed_sheets -= round(needed_sheets)
	if (sheet_left <= 0 && sheets > 0)
		sheet_left = 1 - needed_sheets
		sheets--

	var/lower_limit = 56 + power_output * 10
	var/upper_limit = 76 + power_output * 10
	var/bias = 0
	if (power_output > 4)
		upper_limit = 400
		bias = power_output - consumption * (4 - consumption)
	if (current_heat < lower_limit)
		current_heat += 4 - consumption
	else
		current_heat += rand(-7 + bias, 7 + bias)
		if (current_heat < lower_limit)
			current_heat = lower_limit
		if (current_heat > upper_limit)
			current_heat = upper_limit

	if (current_heat > 300)
		overheat()
		qdel(src)

/obj/machinery/power/port_gen/pacman/handleInactive()
	current_heat = max(current_heat - 2, 0)
	if(current_heat == 0)
		STOP_PROCESSING(SSmachines, src)

/obj/machinery/power/port_gen/pacman/proc/overheat()
	explosion(src.loc, 2, 5, 2, -1)

/obj/machinery/power/port_gen/pacman/set_anchored(anchorvalue)
	. = ..()
	if(isnull(.))
		return //no need to process if we didn't change anything.
	if(anchorvalue)
		connect_to_network()
	else
		disconnect_from_network()

/obj/machinery/power/port_gen/pacman/attackby(obj/item/O, mob/user, params)
	if(istype(O, sheet_path))
		var/obj/item/stack/addstack = O
		var/amount = min((max_sheets - sheets), addstack.amount)
		if(amount < 1)
			to_chat(user, "<span class='notice'>The [src.name] is full!</span>")
			return
		to_chat(user, "<span class='notice'>You add [amount] sheets to the [src.name].</span>")
		sheets += amount
		addstack.use(amount)
		return
	else if(!active)
		if(O.tool_behaviour == TOOL_WRENCH)
			if(!anchored && !isinspace())
				set_anchored(TRUE)
				to_chat(user, "<span class='notice'>You secure the generator to the floor.</span>")
			else if(anchored)
				set_anchored(FALSE)
				to_chat(user, "<span class='notice'>You unsecure the generator from the floor.</span>")

			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			return
		else if(O.tool_behaviour == TOOL_SCREWDRIVER)
			panel_open = !panel_open
			O.play_tool_sound(src)
			if(panel_open)
				to_chat(user, "<span class='notice'>You open the access panel.</span>")
			else
				to_chat(user, "<span class='notice'>You close the access panel.</span>")
			return
		else if(default_deconstruction_crowbar(O))
			return
	return ..()

/obj/machinery/power/port_gen/pacman/on_emag(mob/user)
	..()
	emp_act(EMP_HEAVY)

/obj/machinery/power/port_gen/pacman/attack_ai(mob/user)
	interact(user)

/obj/machinery/power/port_gen/pacman/attack_paw(mob/user)
	interact(user)


/obj/machinery/power/port_gen/pacman/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/power/port_gen/pacman/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PortableGenerator")
		ui.open()
		ui.set_autoupdate(TRUE) // Fuel left, power generated, power in powernet, current heat(?)

/obj/machinery/power/port_gen/pacman/ui_data()
	var/data = list()

	data["active"] = active
	data["sheet_name"] = capitalize(sheet_name)
	data["sheets"] = sheets
	data["stack_percent"] = round(sheet_left * 100, 0.1)

	data["anchored"] = anchored
	data["connected"] = (powernet == null ? 0 : 1)
	data["ready_to_boot"] = anchored && HasFuel()
	data["power_generated"] = display_power(power_gen)
	data["power_output"] = display_power(power_gen * power_output)
	data["power_available"] = (powernet == null ? 0 : display_power(avail()))
	data["current_heat"] = current_heat
	. =  data

/obj/machinery/power/port_gen/pacman/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("toggle_power")
			TogglePower()
			. = TRUE

		if("eject")
			if(!active)
				DropFuel()
				. = TRUE

		if("lower_power")
			if (power_output > 1)
				power_output--
				. = TRUE

		if("higher_power")
			if (power_output < 4 || (obj_flags & EMAGGED))
				power_output++
				. = TRUE

/obj/machinery/power/port_gen/pacman/super
	name = "\improper S.U.P.E.R.P.A.C.M.A.N.-type portable generator"
	icon_state = "portgen1_0"
	base_icon = "portgen1"
	circuit = /obj/item/circuitboard/machine/pacman/super
	sheet_path = /obj/item/stack/sheet/mineral/uranium
	power_gen = 15000
	time_per_sheet = 85

/obj/machinery/power/port_gen/pacman/super/overheat()
	explosion(src.loc, 3, 3, 3, -1)

/obj/machinery/power/port_gen/pacman/mrs
	name = "\improper M.R.S.P.A.C.M.A.N.-type portable generator"
	base_icon = "portgen2"
	icon_state = "portgen2_0"
	circuit = /obj/item/circuitboard/machine/pacman/mrs
	sheet_path = /obj/item/stack/sheet/mineral/diamond
	power_gen = 40000
	time_per_sheet = 80

/obj/machinery/power/port_gen/pacman/mrs/overheat()
	explosion(src.loc, 4, 4, 4, -1)


// Fluid power generator

/obj/machinery/power/port_gen/fluid_power_generator
	name = "\improper Fluid-type portable generator"
	circuit = /obj/item/circuitboard/machine/fluid_power_generator
	power_gen = 100
	var/fluid_current_amount = 0
	var/fluid_max_amount = 1000
	var/fluid_name = ""
	var/fluid_path = /datum/reagent/consumable/milk
	var/time_per_fluid_liter = 10

/obj/machinery/power/port_gen/fluid_power_generator/Initialize(mapload)
	. = ..()
	if(anchored)
		connect_to_network()

/obj/machinery/power/port_gen/fluid_power_generator/Initialize(mapload)
	. = ..()

	var/obj/S = fluid_path
	fluid_name = initial(S.name)

/obj/machinery/power/port_gen/fluid_power_generator/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The generator has [fluid_current_amount] units of [fluid_name] fuel left, producing [display_power(power_gen)] per cycle.</span>"
	if(anchored)
		. += "<span class='notice'>It is anchored to the ground.</span>"

/obj/machinery/power/port_gen/fluid_power_generator/HasFuel()
	if(fluid_current_amount > 0)
		return TRUE
	return FALSE

/obj/machinery/power/port_gen/fluid_power_generator/UseFuel()
	var/needed_fuel = 1 / time_per_fluid_liter
	fluid_current_amount -= needed_fuel

/obj/machinery/power/port_gen/fluid_power_generator/set_anchored(anchorvalue)
	. = ..()
	if(isnull(.))
		return //no need to process if we didn't change anything.
	if(anchorvalue)
		connect_to_network()
	else
		disconnect_from_network()

/obj/machinery/power/port_gen/fluid_power_generator/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/reagent_containers))

		var/obj/item/reagent_containers/container = O
		if(O.reagents.total_volume < 0)
			to_chat(user, "<span class='warning'>[src] is empty!</span>")
			return

		if(fluid_current_amount == fluid_max_amount)
			to_chat(user, "<span class='warning'> Generator is full.</span>")
			return

		var/transfer = 0
		if(container.reagents.total_volume > 0)
			if(container.reagents.total_volume >= container.amount_per_transfer_from_this) // Transfer is smaller than what's stored in the container
				transfer = container.amount_per_transfer_from_this
			else //Transfer is bigger than what's stored in the container => Reduce transfer amount
				transfer = (container.amount_per_transfer_from_this - O.reagents.total_volume)
				transfer = (container.amount_per_transfer_from_this - transfer)

			if((fluid_current_amount + transfer) < fluid_max_amount ) //Transfer is smaller than max of generator
				fluid_current_amount += transfer
				container.reagents.total_volume -= transfer
				to_chat(user, "<span class='notice'>You add [transfer] [fluid_name] to the [src.name].</span>")
			else	//Transfer is bigger than max of generator => Reduce transfer amount
				var/transfer_overfill = (fluid_current_amount + transfer) - fluid_max_amount
				transfer -= transfer_overfill
				fluid_current_amount += transfer
				O.reagents.total_volume -= transfer
				to_chat(user, "<span class='notice'>You add [transfer] [fluid_name] to the [src.name].</span>")
		return

	else if(!active)
		if(O.tool_behaviour == TOOL_WRENCH)
			if(!anchored && !isinspace())
				set_anchored(TRUE)
				to_chat(user, "<span class='notice'>You secure the generator to the floor.</span>")
			else if(anchored)
				set_anchored(FALSE)
				to_chat(user, "<span class='notice'>You unsecure the generator from the floor.</span>")

			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			return
		else if(O.tool_behaviour == TOOL_SCREWDRIVER)
			panel_open = !panel_open
			O.play_tool_sound(src)
			if(panel_open)
				to_chat(user, "<span class='notice'>You open the access panel.</span>")
			else
				to_chat(user, "<span class='notice'>You close the access panel.</span>")
			return
		else if(default_deconstruction_crowbar(O))
			return
	return ..()

/obj/machinery/power/port_gen/fluid_power_generator/on_emag(mob/user)
	..()
	emp_act(EMP_HEAVY)

/obj/machinery/power/port_gen/fluid_power_generator/attack_ai(mob/user)
	interact(user)

/obj/machinery/power/port_gen/fluid_power_generator/attack_paw(mob/user)
	interact(user)


/obj/machinery/power/port_gen/fluid_power_generator/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/power/port_gen/fluid_power_generator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PortableFluidGenerator")
		ui.open()
		ui.set_autoupdate(TRUE) // Fuel left, power generated, power in powernet, current heat(?)

/obj/machinery/power/port_gen/fluid_power_generator/ui_data()
	var/data = list()

	data["active"] = active
	data["sheet_name"] = capitalize(fluid_name)
	data["sheets"] = fluid_current_amount
	data["stack_percent"] = round(fluid_current_amount/fluid_max_amount*100, 0.1)

	data["anchored"] = anchored
	data["connected"] = (powernet == null ? 0 : 1)
	data["ready_to_boot"] = anchored && HasFuel()
	data["power_generated"] = display_power(power_gen)
	data["power_output"] = display_power(power_gen * power_output)
	data["power_available"] = (powernet == null ? 0 : display_power(avail()))
	data["current_heat"] = 0
	. =  data

/obj/machinery/power/port_gen/fluid_power_generator/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("toggle_power")
			TogglePower()
			. = TRUE

		if("lower_power")
			if (power_output > 1)
				power_output--
				. = TRUE

		if("higher_power")
			if (power_output < 4 || (obj_flags & EMAGGED))
				power_output++
				. = TRUE
