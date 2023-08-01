-- Reuse function of idle logic to make enemies in an area aware of a player entering the area
CopLogicAttack.on_area_safety = CopLogicIdle.on_area_safety

-- Prevent tasers from switching target while tasing
local _chk_request_action_turn_to_enemy_original = CopLogicAttack._chk_request_action_turn_to_enemy
function CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, ...)
	return not my_data.tasing and _chk_request_action_turn_to_enemy_original(data, my_data, ...)
end

-- Compatibility with The Fixes
TheFixesPreventer = TheFixesPreventer or {}
TheFixesPreventer.crash_upd_aim_coplogicattack = true

-- Remove some of the strict conditions for enemies shooting while on the move
-- This will result in enemies opening fire more likely while moving
-- Also greatly simplified the function
function CopLogicAttack._upd_aim(data, my_data)
	local focus_enemy = data.attention_obj
	local verified = focus_enemy and focus_enemy.verified
	local nearly_visible = focus_enemy and focus_enemy.nearly_visible

	local aim, shoot, expected_pos = CopLogicAttack._check_aim_shoot(data, my_data, focus_enemy, verified, nearly_visible)
	
	if focus_enemy and focus_enemy.is_person and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and not data.unit:in_slot(16) and not data.is_converted then
		if focus_enemy.is_local_player then
			local time_since_verify = data.attention_obj.verified_t and data.t - data.attention_obj.verified_t
			local e_movement_state = focus_enemy.unit:movement():current_state()

			if e_movement_state:_is_reloading() and time_since_verify and time_since_verify < 2 then
				if not data.unit:in_slot(16) and data.char_tweak.chatter.reload then
					managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "reload")
				end
			end
		else
			local e_anim_data = focus_enemy.unit:anim_data()
			local time_since_verify = data.attention_obj.verified_t and data.t - data.attention_obj.verified_t

			if e_anim_data.reload and time_since_verify and time_since_verify < 2 then
				if not data.unit:in_slot(16) and data.char_tweak.chatter.reload then
					managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "reload")
				end			
			end
		end
	end

	if aim or shoot then
		if verified or nearly_visible then
			if my_data.attention_unit ~= focus_enemy.u_key then
				CopLogicBase._set_attention(data, focus_enemy)
				my_data.attention_unit = focus_enemy.u_key
			end
		elseif expected_pos then
			if my_data.attention_unit ~= expected_pos then
				CopLogicBase._set_attention_on_pos(data, expected_pos)
				my_data.attention_unit = expected_pos
			end
		end

		if not my_data.shooting and not my_data.spooc_attack and not data.unit:anim_data().reload and not data.unit:movement():chk_action_forbidden("action") then
			my_data.shooting = data.unit:brain():action_request({
				body_part = 3,
				type = "shoot"
			})
		end
	else
		if my_data.shooting then
			local success = data.unit:brain():action_request({
				body_part = 3,
				type = "idle"
			})
			if success then
				my_data.shooting = nil
			end
		end

		if my_data.attention_unit then
			CopLogicBase._reset_attention(data)
			my_data.attention_unit = nil
		end
	end

	CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
end

-- Helper function to reuse in other enemy logic _upd_aim functions
function CopLogicAttack._check_aim_shoot(data, my_data, focus_enemy, verified, nearly_visible)
	if not focus_enemy or focus_enemy.reaction < AIAttentionObject.REACT_AIM then
		return
	end

	local advancing = my_data.advancing and not my_data.advancing:stopping()
	local running = data.unit:anim_data().run or advancing and my_data.advancing._cur_vel and my_data.advancing._cur_vel > 300
	local time_since_verification = focus_enemy.verified_t and data.t - focus_enemy.verified_t or math.huge
	local weapon_range = data.internal_data.weapon_range or { close = 1000, far = 4000 }
	local firing_range = running and weapon_range.close or weapon_range.far

	local aim = not advancing or time_since_verification < math.lerp(4, 1, focus_enemy.verified_dis / firing_range) or focus_enemy.verified_dis < 800 or data.char_tweak.always_face_enemy
	local shoot = aim and my_data.shooting and AIAttentionObject.REACT_SHOOT <= focus_enemy.reaction and time_since_verification < (running and 2 or 4)
	local expected_pos = not shoot and focus_enemy.verified_dis < weapon_range.close and focus_enemy.m_head_pos or focus_enemy.last_verified_pos or focus_enemy.verified_pos

	if verified or nearly_visible then
		if not shoot and AIAttentionObject.REACT_SHOOT <= focus_enemy.reaction then
			local last_sup_t = data.unit:character_damage():last_suppression_t()

			if last_sup_t and data.t - last_sup_t < 7 * (running and 0.5 or 1) * (verified and 1 or 0.5) then
				shoot = true
			elseif verified and focus_enemy.verified_dis < firing_range then
				shoot = true
			elseif verified and focus_enemy.criminal_record and focus_enemy.criminal_record.assault_t and data.t - focus_enemy.criminal_record.assault_t < (running and 2 or 4) then
				shoot = true
			elseif my_data.attitude == "engage" and my_data.firing and time_since_verification < 4 then
				shoot = true
			end
		end

		aim = aim or shoot or focus_enemy.verified_dis < firing_range
	end

	return aim, shoot, expected_pos
end

--chatter below
local math_random = math.random

Hooks:PostHook(CopLogicAttack, "_upd_combat_movement", "RR_upd_combat_movement", function(data)
	local chatter = data.char_tweak.chatter
	if data.internal_data.flank_cover and chatter and chatter.look_for_angle and not data.is_converted and not data.unit:sound():speaking(data.t) then
		managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "look_for_angle") -- I'll try and flank 'em!
	end
end)

Hooks:PostHook(CopLogicAttack, "_chk_request_action_walk_to_cover_shoot_pos", "RR_chk_request_action_walk_to_cover_shoot_pos", function(data)
	local chatter = data.char_tweak.chatter
	if chatter and (chatter.push or chatter.go_go) and not data.is_converted and not data.unit:sound():speaking(data.t) and data.internal_data.advancing then
		managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, math_random() > 0.5 and "push" or "go_go") -- Puuuush! / Go, Go!
	end
end)

Hooks:PreHook(CopLogicAttack, "action_complete_clbk", "RR_action_complete_clbk", function(data, action)
	local chatter = data.char_tweak.chatter
	if action:type() == "walk" and data.internal_data.moving_to_cover and action:expired() and chatter and (chatter.inpos or chatter.ready) and not data.is_converted and not data.unit:sound():speaking(TimerManager:game():time()) then -- can't use data.t as this might get called outside an update
		managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, math_random() > 0.5 and "ready" or "inpos") -- Ready! / I'm in position!
	end
end)

function CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data) -- doesn't really work as a posthook
	local focus_enemy = data.attention_obj

	if shoot then
		if not my_data.firing then
			data.unit:movement():set_allow_fire(true)

			my_data.firing = true

			local chatter = data.char_tweak.chatter
			if not data.unit:in_slot(16) and not data.is_converted and chatter and chatter.aggressive then
				if not data.unit:base():has_tag("special") then 
					if data.unit:base():has_tag("law") then
						if data.unit:base()._tweak_table == "gensec" or data.unit:base()._tweak_table == "security" or data.unit:base()._tweak_table == "city_swat_guard" then
							--HE'S GOT A GUN
							data.unit:sound():say("a01", true)
						else
							if managers.groupai:state():chk_assault_active_atm() and chatter.open_fire then
								managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "open_fire")
							else
								managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "aggressive")
							end
						end
					end
				elseif data.unit:base():has_tag("gangster") then
					managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "aggressive")
				elseif not data.unit:base():has_tag("tank") and data.unit:base():has_tag("medic") then
					managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "aggressive")
				elseif data.unit:base():has_tag("shield") and (not my_data.shield_knock_cooldown or my_data.shield_knock_cooldown < data.t) then
					if data.unit:base()._tweak_table == "phalanx_minion" or data.unit:base()._tweak_table == "phalanx_minion_assault" then
						data.unit:sound():play("hos_shield_indication_sound_terminator_style", nil, true) --that's a big ass name
					else
						data.unit:sound():play("shield_identification", nil, true)
					end

					my_data.shield_knock_cooldown = data.t + math_random(12, 24)
				elseif data.unit:base()._tweak_table == "spring" or data.unit:base()._tweak_table == "phalanx_vip" then
					data.unit:sound():say("a05", true)
				else
					managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "contact")
				end
			end
		end
	elseif my_data.firing then
		data.unit:movement():set_allow_fire(false)

		my_data.firing = nil
	end
end

-- The big stuff, cops will comment on player equipment

CopLogicAttack._cop_comment_cooldown_t = {}

Hooks:PostHook(CopLogicAttack, "update", "RR_update", function(data)
	CopLogicAttack:inform_law_enforcements(data)	
end)

function CopLogicAttack:start_inform_ene_cooldown(cooldown_t, msg_type)
	local t = TimerManager:game():time()
	self._cop_comment_cooldown_t[msg_type] = self._cop_comment_cooldown_t[msg_type] or {}
	self._cop_comment_cooldown_t[msg_type]._cooldown_t = cooldown_t + t
	self._cooldown_delay_t = t + 5
end

function CopLogicAttack:ene_inform_has_cooldown_met(msg_type)
	local t = TimerManager:game():time()

	if not self._cop_comment_cooldown_t[msg_type] then
		return true
	end

	if self._cooldown_delay_t and self._cooldown_delay_t > t then
		return false
	end

	if self._cop_comment_cooldown_t[msg_type]._cooldown_t < t then
		return true
	end

	return false
end


function CopLogicAttack:_has_deployable_type(unit, deployable)
	local peer_id = managers.criminals:character_peer_id_by_unit(unit)
	if not peer_id then
		return false
	end

	local synced_deployable_equipment = managers.player:get_synced_deployable_equipment(peer_id)

	if synced_deployable_equipment then
		if not synced_deployable_equipment.deployable or synced_deployable_equipment.deployable ~= deployable then
			return false
		end

		--[[if synced_deployable_equipment.amount and synced_deployable_equipment.amount <= 0 then
			return false
		end--]]

		return true
	end

	return false
end

function CopLogicAttack:_next_to_cops(data, amount)
	local close_peers = {}
	local range = 5000
	amount = amount or 4
	for u_key, u_data in pairs(managers.enemy:all_enemies()) do
		if data.key ~= u_key then
			if u_data.unit and alive(u_data.unit) and not u_data.unit:character_damage():dead() then
				local anim_data = u_data.unit:anim_data()
				if not anim_data.surrender and not anim_data.hands_tied and not anim_data.hands_back then
					if mvector3.distance_sq(data.m_pos, u_data.m_pos) < range * range then
						table.insert(close_peers, u_data.unit)
					end
				end
			end
		end
	end
	return #close_peers >= amount
end

function CopLogicAttack:inform_law_enforcements(data)
	if managers.groupai:state()._special_unit_types[data.unit:base()._tweak_table] then
		return
	end
	
	if data.unit:in_slot(16) or not data.char_tweak.chatter then
		return
	end

	local enemy_target = data.attention_obj
	if not enemy_target or not enemy_target.verified or enemy_target.dis > 100000 or not data.unit or self:_next_to_cops(data) then
		return
	end

	local sound_name, cooldown_t, msg_type

	if enemy_target.is_deployable then
		msg_type = "sentry_detected"
		sound_name = "ch2" -- Every voiceset except l5n (unused)
		cooldown_t = 30
	elseif enemy_target.unit:in_slot(managers.slot:get_mask("all_criminals")) then
		local weapon = enemy_target.unit.inventory and enemy_target.unit:inventory():equipped_unit()
		if weapon and weapon:base():is_category("saw") then
			msg_type = "saw_maniac"
			sound_name = "ch4" -- Every voiceset except l5n (unused)
			cooldown_t = 30
		elseif self:_has_deployable_type(enemy_target.unit, "doctor_bag") then
			msg_type = "doc_bag"
			sound_name = "med" -- Why do only l2n, l3n and l4n have this line :/
			cooldown_t = 30
		elseif self:_has_deployable_type(enemy_target.unit, "first_aid_kit") then
			msg_type = "first_aid_kit"
			sound_name = "med" -- Why do only l2n, l3n and l4n have this line :/
			cooldown_t = 30
		elseif self:_has_deployable_type(enemy_target.unit, "ammo_bag") then
			msg_type = "ammo_bag"
			sound_name = "amm" -- All lxn voicesets 
			cooldown_t = 30
		elseif self:_has_deployable_type(enemy_target.unit, "trip_mine") then
			msg_type = "trip_mine"
			sound_name = "ch1" -- Every voiceset except l5n (unused)
			cooldown_t = 30
		end
	end

	if msg_type and self:ene_inform_has_cooldown_met(msg_type) then
		data.unit:sound():say(sound_name, true)
		self:start_inform_ene_cooldown(cooldown_t, msg_type)
	end
end

-- Only return retreat pos if its different from current pos (to fix spamming of walk actions)
local _find_retreat_position_original = CopLogicAttack._find_retreat_position
function CopLogicAttack._find_retreat_position(from_pos, ...)
	local pos = _find_retreat_position_original(from_pos, ...)
	if pos and mvector3.not_equal(from_pos, pos) then
		return pos
	end
end

-- Make moving back during combat depend on weapon range
function CopLogicAttack._chk_start_action_move_back(data, my_data, focus_enemy, engage)
	local weapon_range = my_data.weapon_range or { close = 500 }
	local close_range = weapon_range.close * 0.5
	if focus_enemy and focus_enemy.nav_tracker and focus_enemy.verified and focus_enemy.dis < close_range and CopLogicAttack._can_move(data) then
		local from_pos = mvector3.copy(data.m_pos)
		local threat_tracker = focus_enemy.nav_tracker
		local threat_head_pos = focus_enemy.m_head_pos
		local retreat_to = CopLogicAttack._find_retreat_position(from_pos, focus_enemy.m_pos, threat_head_pos, threat_tracker, 400, engage)

		if retreat_to then
			CopLogicAttack._cancel_cover_pathing(data, my_data)

			my_data.advancing = data.unit:brain():action_request({
				type = "walk",
				variant = "walk",
				body_part = 2,
				nav_path = {
					from_pos,
					retreat_to
				}
			})

			if my_data.advancing then
				my_data.surprised = true
				return true
			end
		end
	end
end

-- Fix reinforce groups relocating due to using covers outside of their nav segments
local _update_cover_original = CopLogicAttack._update_cover
function CopLogicAttack._update_cover(data, ...)
	if not data.objective or not data.objective.grp_objective or data.objective.grp_objective.type ~= "reenforce_area" then
		return _update_cover_original(data, ...)
	end

	local my_data = data.internal_data
	local best_cover = my_data.best_cover

	my_data.flank_cover = nil

	if not data.attention_obj or data.attention_obj.reaction < AIAttentionObject.REACT_COMBAT then
		if best_cover and mvector3.distance_sq(best_cover[1][1], data.m_pos) > 10000 then
			CopLogicAttack._set_best_cover(data, my_data, nil)
		end
		return
	end

	local taking_cover = not my_data.moving_to_cover and not my_data.walking_to_cover_shoot_pos and not my_data.surprised
	local can_take_cover = not my_data.surprised and not my_data.processing_cover_path and not my_data.charge_path_search_id
	if not taking_cover and can_take_cover then
		local threat_pos = data.attention_obj.m_pos
		if not best_cover or not CopLogicAttack._verify_cover(best_cover[1], threat_pos, nil, nil) then
			local dir = threat_pos - data.m_pos
			mvector3.normalize(dir)
			local found_cover = managers.navigation:find_cover_in_nav_seg_2(data.objective.area.nav_segs, data.m_pos, dir)
			if found_cover and (not best_cover or CopLogicAttack._verify_cover(found_cover, threat_pos, nil, nil)) then
				local better_cover = {
					found_cover
				}

				CopLogicAttack._set_best_cover(data, my_data, better_cover)

				local offset_pos, yaw = CopLogicAttack._get_cover_offset_pos(data, better_cover, threat_pos)
				if offset_pos then
					better_cover[5] = offset_pos
					better_cover[6] = yaw
				end
			end
		end
	end

	local in_cover = my_data.in_cover
	if in_cover then
		local threat_pos = data.attention_obj.verified_pos
		in_cover[3], in_cover[4] = CopLogicAttack._chk_covered(data, data.m_pos, threat_pos, data.visibility_slotmask)
	end
end