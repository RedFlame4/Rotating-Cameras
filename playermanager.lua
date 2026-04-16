Hooks:PostHook(PlayerManager, "_setup", "camerarot_setup", function(self)
    self._global.sync_controlled_cameras = {}
end)

function PlayerManager:set_synced_controlled_camera(peer_id, cam_unit)
    local controlled_cameras = self._global.sync_controlled_cameras
    local prev_camera = controlled_cameras[peer_id]
    if alive(prev_camera) then
        prev_camera:base():player_control_state(peer_id, false)
    end

    controlled_cameras[peer_id] = cam_unit

    if cam_unit then
        cam_unit:base():player_control_state(peer_id, true)
    end
end

Hooks:PostHook(PlayerManager, "peer_dropped_out", "camerarot_peer_dropped_out", function(self, peer)
    self:set_synced_controlled_camera(peer:id(), nil)
end)
