function UnitNetworkHandler:sync_camera_rotation(cam_unit, end_yaw, duration)
	if not alive(cam_unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end

	local target_yaw = (360 * (end_yaw / 255))

	cam_unit:base():set_target_yaw(target_yaw, duration)
end