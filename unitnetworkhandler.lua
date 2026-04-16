function UnitNetworkHandler:camera_rotation(cam_unit, end_yaw, end_pitch, forced, duration, rpc)
	if not alive(cam_unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end

	local peer = self._verify_sender(rpc)
	if not peer:is_host() and cam_unit:base():controlling_peer() ~= peer:id() then
		return
	end

	if not cam_unit:base():can_rotate() then
		return
	end

	local target_yaw = (360 * (end_yaw / 255)) - 180
	local target_pitch = (180 * (end_pitch / 255)) - 90

	cam_unit:base():set_target_rotation(target_yaw, target_pitch, forced == 1, duration)
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

function UnitNetworkHandler:camera_want_control(cam_unit, state, rpc)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end

	local peer = self._verify_sender(rpc)
	if not alive(cam_unit) or not peer then
		return
	end

	cam_unit:base():sync_control_state(state, peer:id())
end

function UnitNetworkHandler:camera_control_state(cam_unit, peer_id, state)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end

	local peer = managers.network:session():peer(peer_id)
	if not alive(cam_unit) or not peer then
		return
	end

	if cam_unit:base():destroyed() then
		return
	end

	managers.player:set_synced_controlled_camera(peer_id, state and cam_unit or nil)
end