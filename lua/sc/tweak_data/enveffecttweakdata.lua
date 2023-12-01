function EnvEffectTweakData:molotov_fire()
	local params = {
		sound_event = "molotov_impact",
		damage = 6,
		player_damage = 3,
		range = 75,
		curve_pow = 3,
		burn_tick_period = 0.5,
		burn_duration = 10,
		sound_event_burning = "burn_loop_gen",
		sound_event_burning_stop = "burn_loop_gen_stop_fade",
		sound_event_impact_duration = 4,
		is_molotov = true,
		alert_radius = 15000,
		fire_alert_radius = 15000,
		dot_data_name = "proj_molotov_groundfire",
		effect_name = "effects/payday2/particles/explosions/molotov_grenade"
	}
	return params
end

function EnvEffectTweakData:hatman_molotov_fire()
	local params = {
		damage = 3,
		player_damage = 3,
		fire_dot_data = {
			dot_damage = 1,
			dot_trigger_max_distance = 3000,
			dot_trigger_chance = 50,
			dot_length = 3.1,
			dot_tick_period = 0.5
		},
		range = 75,
		burn_duration = 10,
		burn_tick_period = 0.5,
		curve_pow = 3,
		sound_event = "white_explosion",
		sound_event_burning = "burn_loop_gen",
		sound_event_impact_duration = 4,
		alert_radius = 15000,
		fire_alert_radius = 15000,
		effect_name = "effects/payday2/particles/explosions/grenade_incendiary_explosion_sc"
	}
	return params
end

function EnvEffectTweakData:snowman_boss_aoe_fire()
	local params = {
		sound_event = "snowmolo_impact",
		range = 100,
		curve_pow = 1,
		no_fire_alert = true,
		sound_event_burning = "no_sound",
		sound_event_burning_stop = "snowmolo_burn_loop_stop",
		damage = 1.5,
		player_damage = 1.5,
		sound_event_impact_duration = 0,
		burn_tick_period = 0.2,
		burn_duration = 1,
		effect_name = "effects/payday2/particles/character/snowman_molotov"
	}

	return params
end

function EnvEffectTweakData:triad_boss_aoe_fire()
	local params = {
		sound_event = "PENT_Boss_Molotov_Drop",
		range = 100,
		curve_pow = 1,
		no_fire_alert = true,
		sound_event_burning = "no_sound",
		damage = 3,
		player_damage = 3,
		sound_event_impact_duration = 1.5,
		burn_tick_period = 0.5,
		burn_duration = 10,
		effect_name = "effects/payday2/particles/explosions/molotov_grenade_pent_boss",
		fire_dot_data = {
			dot_damage = 1,
			dot_trigger_max_distance = 3000,
			dot_trigger_chance = 50,
			dot_length = 3.1,
			dot_tick_period = 0.5
		}
	}

	return params
end

function EnvEffectTweakData:incendiary_burst_fire()
	local params = {
		sound_event = "white_explosion",
		damage = 6,
		player_damage = 3,
		range = 75,
		burn_duration = 12,
		burn_tick_period = 0.5,
		curve_pow = 3,
		sound_event_burning = "burn_loop_gen",
		sound_event_burning_stop = "burn_loop_gen_stop_fade",
		sound_event_impact_duration = 4,
		alert_radius = 15000,
		fire_alert_radius = 15000,
		dot_data_name = "proj_incendiary_groundfire",
		effect_name = "effects/payday2/particles/explosions/grenade_incendiary_explosion_sc"
	}
	return params
end	

function EnvEffectTweakData:ray_fire()
	local params = {
		sound_event = "gl_explode",
		damage = 6,
		player_damage = 3,
		range = 75,
		burn_duration = 12,
		burn_tick_period = 0.5,
		curve_pow = 3,
		sound_event_burning = "burn_loop_gen",
		sound_event_burning_stop = "burn_loop_gen_stop_fade",
		sound_event_impact_duration = 4,
		alert_radius = 15000,
		fire_alert_radius = 15000,
		dot_data_name = "proj_ray_groundfire",
		effect_name = "effects/payday2/particles/explosions/grenade_incendiary_explosion_sc"
	}
	return params
end

function EnvEffectTweakData:trip_mine_fire()
	local params = {
		damage = 6,
		player_damage = 0,
		fire_dot_data = {
			dot_damage = 1,
			dot_trigger_max_distance = 3000,
			dot_trigger_chance = 50,
			dot_length = 3.1,
			dot_tick_period = 0.5
		},
		range = 75,
		burn_duration = 10,
		burn_tick_period = 0.5,
		curve_pow = 3,
		sound_event = "molotov_impact",
		sound_event_burning = "burn_loop_gen",
		sound_event_impact_duration = 4,
		alert_radius = 15000,
		fire_alert_radius = 15000,
		effect_name = "effects/payday2/particles/explosions/molotov_grenade"
	}
	return params
end


function EnvEffectTweakData:incendiary_fire_arbiter()
	local params = {
		damage = 4,
		player_damage = 2,
		fire_dot_data = {
			dot_damage = 1,
			dot_trigger_max_distance = 3000,
			dot_trigger_chance = 50,
			dot_length = 3.1,
			dot_tick_period = 0.5
		},
		range = 75,
		burn_duration = 5,
		burn_tick_period = 0.5,
		curve_pow = 3,
		sound_event = "gl_explode",
		sound_event_burning = "burn_loop_gen",
		sound_event_impact_duration = 4,
		alert_radius = 1500,
		fire_alert_radius = 1500,
		effect_name = "effects/payday2/particles/explosions/molotov_grenade"
	}
	return params
end
