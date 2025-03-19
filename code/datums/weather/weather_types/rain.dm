/datum/weather/rain
	name = "rain"
	desc = "The planet's thunderstorms are by nature acidic, and will incinerate anyone standing beneath them without protection."

	telegraph_duration = 400
	telegraph_message = "<span class='boldwarning'>Thunder rumbles far above. You hear droplets drumming against the canopy. Seek shelter.</span>"
	telegraph_sound = 'sound/ambience/acidrain_start.ogg'

	weather_message = "<span class='boldwarning'>Rain pours down around you!</span>"
	weather_overlay = "acid_rain"
	weather_duration_lower = 600
	weather_duration_upper = 1200
	weather_sound = 'sound/ambience/acidrain_mid.ogg'

	end_duration = 100
	end_message = "<span class='boldannounce'>The downpour gradually slows to a light shower.</span>"
	end_sound = 'sound/ambience/acidrain_end.ogg'

	area_type = /area
	protect_indoors = FALSE
	target_trait = ZTRAIT_RAIN

	probability = 0

	barometer_predictable = TRUE

	var/list/rain_start_sounds_list = list()
	var/list/rain_mid_sounds_list = list()
	var/list/rain_end_sounds_list = list()
// This is for the sounds;

/datum/weather/rain/telegraph()
	var/list/eligible_areas = list()
	for (var/z in impacted_z_levels)
		eligible_areas += SSmapping.areas_in_z["[z]"]
	for(var/i in 1 to eligible_areas.len)
		var/area/place = eligible_areas[i]
		rain_start_sounds_list[place] = /datum/looping_sound/rain_start
		rain_mid_sounds_list[place] = /datum/looping_sound/rain_mid
		rain_end_sounds_list[place] = /datum/looping_sound/rain_end
		CHECK_TICK

	GLOB.rain_sounds += rain_start_sounds_list
	return ..()

/datum/weather/rain/start()
	GLOB.rain_sounds -= rain_start_sounds_list
	GLOB.rain_sounds += rain_mid_sounds_list
	return ..()
/datum/weather/rain/wind_down()
	GLOB.rain_sounds -= rain_mid_sounds_list
	GLOB.rain_sounds += rain_end_sounds_list
	return ..()
/datum/weather/rain/end()
	GLOB.rain_sounds -= rain_end_sounds_list
	return ..()
