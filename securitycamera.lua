local idstr_yaw_obj = Idstring("CameraYaw")

Hooks:PostHook(SecurityCamera, "init", "camerarot_init", function(self)
	self._yaw = 0
	self._pitch = 0
end)

Hooks:PostHook(SecurityCamera, "set_detection_enabled", "camerarot_set_detection_enabled", function(self, state)
	if state and self._yaw_obj then
		self._max_yaw = 60

		self._turn_rate = 9 -- degrees/s
		self._turn_direction = math.random(2) == 1 and 1 or -1

		self:set_target_yaw(self._max_yaw * self._turn_direction)
	end
end)

local update_orig = Hooks:GetFunction(SecurityCamera, "update")
Hooks:OverrideFunction(SecurityCamera, "update", function (self, unit, t, dt, ...)
	self:_update_camera_rotation(unit, t, dt)

	if not self._wants_update then -- vanilla code can crash if we update when it didn't want to
		return
	end

	return update_orig(self, unit, t, dt, ...)
end)

function SecurityCamera:_update_camera_rotation(unit, t, dt)
	if self._stalled_until then
		if t > self._stalled_until then
			self._stalled_until = nil
			self:set_target_yaw(self._max_yaw * self._turn_direction)
		end
	elseif self._target_yaw then
		local new_yaw = math.step(self._yaw, self._target_yaw, self._yaw_difference * (dt / self._turn_duration))

		self:apply_rotations(new_yaw, nil, true)

		if new_yaw ~= self._target_yaw then
			return
		end

		self._target_yaw = nil

		if Network:is_server() then
			self._stalled_until = t + math.rand(1.5, 2.5)
			self._turn_direction = -self._turn_direction
		elseif not self._tape_loop_restarting_t then
			self:set_update_enabled(false)
		end
	end
end

function SecurityCamera:set_target_yaw(yaw, duration)
	self._target_yaw = yaw
	self._yaw_difference = math.abs(self._target_yaw - self._yaw) -- math.step always expects a positive number
	self._turn_duration = duration or self._yaw_difference / self._turn_rate

	if Network:is_server() then
		local sync_yaw = math.round(255 * ((self._target_yaw + 180) / 360))

		managers.network:session():send_to_peers_synched("sync_camera_rotation", self._unit, sync_yaw, self._turn_duration)
	else
		self:set_update_enabled(true)
	end
end

local set_update_enabled_orig = Hooks:GetFunction(SecurityCamera, "set_update_enabled")
Hooks:OverrideFunction(SecurityCamera, "set_update_enabled", function (self, state, ...)
	self._wants_update = state
	return set_update_enabled_orig(self, state or self._target_yaw and true, ...)
end)

Hooks:OverrideFunction(SecurityCamera, "apply_rotations", function (self, yaw, pitch, no_sync)
	local yaw_obj = self._yaw_obj or self._unit:get_object(Idstring("CameraYaw"))
	local original_yaw_rot = yaw_obj:local_rotation()
	local new_yaw_rot = Rotation(180 + yaw, original_yaw_rot:pitch(), original_yaw_rot:roll())

	yaw_obj:set_local_rotation(new_yaw_rot)

	self._yaw = yaw

	if pitch then
		local pitch_obj = self._pitch_obj or self._unit:get_object(Idstring("CameraPitch"))
		local original_pitch_rot = pitch_obj:local_rotation()
		local new_pitch_rot = Rotation(original_pitch_rot:yaw(), pitch, original_pitch_rot:roll())

		pitch_obj:set_local_rotation(new_pitch_rot)

		self._pitch = pitch
	end

	self._look_fwd = nil

	self._unit:set_moving()

	if Network:is_server() and not no_sync then
		local sync_yaw = 255 * (yaw + 180) / 360
		local sync_pitch = 255 * (pitch + 90) / 180

		managers.network:session():send_to_peers_synched("camera_yaw_pitch", self._unit, sync_yaw, sync_pitch)
	end
end)

Hooks:PreHook(SecurityCamera, "generate_cooldown", "camerarot_generate_cooldown", function(self)
	self._target_yaw = nil
	self._stalled_until = nil
end)

Hooks:PostHook(SecurityCamera, "save", "camerarot_save", function(self, data)
	if self._target_yaw then
		data.target_yaw = self._target_yaw

		local rel_progress_left = math.abs((self._target_yaw - self._yaw) / self._yaw_difference)

		data.turn_duration = self._turn_duration * rel_progress_left
	end
end)

Hooks:PostHook(SecurityCamera, "load", "camerarot_load", function(self, data)
	if data.target_yaw then
		self:set_target_yaw(data.target_yaw, data.turn_duration)
	end
end)