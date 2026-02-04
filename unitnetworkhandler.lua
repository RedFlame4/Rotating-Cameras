function UnitNetworkHandler:sync_camera_rotation(cam_unit, end_yaw, duration)
	if not alive(cam_unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end

	local target_yaw = (360 * (end_yaw / 255)) - 180

	cam_unit:base():set_target_yaw(target_yaw, duration)
end

function UnitNetworkHandler:camera_set_attention(cam_unit, target_unit)
	if not alive(cam_unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end

	if not alive(target_unit) then
		cam_unit:base():set_target_attention(nil)
		return
	end

	local handler = target_unit:attention()
		or target_unit:brain() and target_unit:brain().attention_handler and target_unit:brain():attention_handler()
		or target_unit:movement() and target_unit:movement().attention_handler and target_unit:movement():attention_handler()
		or target_unit:base() and target_unit:base().attention_handler and target_unit:base():attention_handler()

	cam_unit:base():set_target_attention({
		unit = target_unit,
		u_key = target_unit:key(),
		handler = handler
	})
end

function UnitNetworkHandler:camera_set_attention_pos(cam_unit, pos)
	if not alive(cam_unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end

	cam_unit:base():set_target_attention({ pos = pos })
end