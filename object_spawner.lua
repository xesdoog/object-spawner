---@diagnostic disable: undefined-global, lowercase-global

object_spawner = gui.get_tab("Object Spawner")
props = require ("proplist")
local prop_index = 1
local h_offset = 0
local default_h_offset = 0
local spawnDistance = { x = 0, y = 0, z = 0 }
local defaultSpawnDistance = { x = 0, y = 0, z = 0 }
local spawnRot = { x = 0, y = 0, z = 0 }
local defaultSpawnRot = { x = 0, y = 0, z = 0 }
local edit_mode = false
local activeX = false
local activeY = false
local activeZ = false
local activeH = false
local searchQuery = ""
local is_typing = false
local dev = false
local attached = false
local attachedToSelf = false
local attachedToSessionPlayer = false
local axisMult = 1
local selected_bone = 0
local spawned_props = {}
local pedBones = {
    {name = "Root", ID = 0},
    {name = "Head", ID = 12844},
    {name = "Right Hand", ID = 6286},
    {name = "Left Hand", ID = 18905},
    {name = "Right Foot", ID = 35502},
    {name = "Left Foot", ID = 14201},
}
local function resetSliders()
    spawnDistance.x = defaultSpawnDistance.x
    spawnDistance.y = defaultSpawnDistance.y
    spawnDistance.z = defaultSpawnDistance.z
    h_offset = default_h_offset
    spawnRot.x = defaultSpawnRot.x
    spawnRot.y = defaultSpawnRot.y
    spawnRot.z = defaultSpawnRot.z
end
script.register_looped("Object Spawner", function()
	if is_typing then
		PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
	end
end)
object_spawner:add_imgui(function()
    ImGui.PushItemWidth(280)
    searchQuery, used = ImGui.InputTextWithHint("##searchObjects", "Search", searchQuery, 32)
    ImGui.PopItemWidth()
    if ImGui.IsItemActive() then
		is_typing = true
	else
		is_typing = false
	end
end)
local filteredItems = {}
local function updateFilteredItems()
    filteredItems = {}
    for _, item in ipairs(props) do
        if string.find(string.lower(item.name), string.lower(searchQuery)) then
            table.insert(filteredItems, item)
        end
        table.sort(props, function(a, b)
            return a.name < b.name
        end)
    end
end
local function displayFilteredList()
    updateFilteredItems()
    local itemNames = {}
    for _, item in ipairs(filteredItems) do
        table.insert(itemNames, item.name)
    end
    prop_index, used = ImGui.ListBox("", prop_index, itemNames, #filteredItems)
end
local function updateBones()
    filteredBones = {}
    for _, bone in ipairs(pedBones) do
            table.insert(filteredBones, bone)
    end
end
local function displayBones()
    updateBones()
    local boneNames = {}
    for _, bone in ipairs(filteredBones) do
        table.insert(boneNames, bone.name)
    end
    selected_bone, used = ImGui.Combo("##pedBones", selected_bone, boneNames, #filteredBones)
end
-- script.register_looped("Player", function(player)
--     session_player = PLAYER.GET_PLAYER_PED(network.get_selected_player())
--     if session_player == nil then
--         ped = self.get_ped()
--     else
--         ped = session_player
--     end
-- end)
object_spawner:add_imgui(function()
    ImGui.PushItemWidth(300)
    displayFilteredList()
    ImGui.PopItemWidth()
end)
object_spawner:add_imgui(function()
    ped = PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID())
    session_player = PLAYER.GET_PLAYER_PED(network.get_selected_player())
    coords = ENTITY.GET_ENTITY_COORDS(ped, false)
    heading = ENTITY.GET_ENTITY_HEADING(ped)
    forwardX = ENTITY.GET_ENTITY_FORWARD_X(ped)
    forwardY = ENTITY.GET_ENTITY_FORWARD_Y(ped)
    object = filteredItems[prop_index+1]
    ImGui.Spacing()
    if ImGui.Button("   Spawn  ") then
        script.run_in_fiber(function(script)
            if object then
                while not STREAMING.HAS_MODEL_LOADED(object.hash) do
                    STREAMING.REQUEST_MODEL(object.hash)
                    coroutine.yield()
                end
            end
            prop = OBJECT.CREATE_OBJECT(object.hash, coords.x + (forwardX * 1.7), coords.y + (forwardY * 1.7), coords.z, true, true, false)
            ENTITY.SET_ENTITY_HEADING(prop, heading)
            ENTITY.SET_ENTITY_SHOULD_FREEZE_WAITING_ON_COLLISION(prop, true)
            OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(prop)
            table.insert(spawned_props, prop)
            netID = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(prop)
            local counter = 0
            while not NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID) do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
                counter = counter + 1
                coroutine:yield()
                if counter > 100 then
                    return
                else
                    counter = counter + 1
                end
            end
            if NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID) then
                retval = "True"
            else
                retval = "False" end
            NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID, true)
            NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netID, ped, true)
            NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, false)
            if dev then
                if OBJECT.DOES_OBJECT_OF_TYPE_EXIST_AT_COORDS(coords.x, coords.y, coords.z, 50, object.hash, true) then
                    log.info("Spawned ["..object.name.."] with handle: ["..prop.."] and network ID: ["..tostring(netID).."].")
                    script:sleep(500)
                    log.info("Controlled By Network: "..retval)
                else
                    gui.show_error("Object Spawner", "ERORR! '"..object.name.."' failed to load.")
                end
            end
        end)
    end
    ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine() ImGui.Spacing() ImGui.SameLine()
    if ImGui.Button("   Delete  ") then
        script.run_in_fiber(function(script)
            for k, v in ipairs(spawned_props) do
                if ENTITY.DOES_ENTITY_EXIST(v) then
                    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(v)
                    script:sleep(100)
                    ENTITY.DELETE_ENTITY(v)
                    table.remove(spawned_props, k)
                    attached = false
                    attachedToSelf = false
                    attachedToSessionPlayer = false
                    if dev then
                        log.info("Removed ["..object.name.."] with handle: ["..prop.."] and network ID: ["..tostring(netID).."].")
                        if NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID) then
                            retval = "True"
                        else
                            retval = "False" end
                        script:sleep(500)
                        log.info("Controlled By Network: "..retval)
                    end
                end
            end
        end)
    end
    ImGui.Separator()
    attachTo, used = ImGui.Checkbox("Attach Objects?", attachTo, true)
    ImGui.SameLine() 
    ImGui.Text("[Work In Progress]")
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text("Works fine on yourself... kinda?\nIt's buggy when used on other\nplayers due to lack of testing.")
        ImGui.EndTooltip()
    end
    if attachTo then
        displayBones()
        boneData = filteredBones[selected_bone + 1]
        if ImGui.Button("Attach To Yourself") then
            if spawned_props[1] ~= nil then
                for _, v in ipairs(spawned_props) do
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(v, self.get_ped(), PED.GET_PED_BONE_INDEX(self.get_ped(), boneData.ID), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, 1)
                    attached = true
                    attachedToSelf = true
                end
            else
                gui.show_message("Object Spawner", "There is nothing to attach! Did you spawn an object?")
            end
        end
        ImGui.SameLine()
        if ImGui.Button("Attach To Player") then
            controlledPed = entities.take_control_of(session_player, 350)
            if spawned_props[1] ~= nil then
                for _, v in ipairs(spawned_props) do
                    if session_player ~= nil then
                        if controlledPed then
                            ENTITY.ATTACH_ENTITY_TO_ENTITY(v, session_player, PED.GET_PED_BONE_INDEX(session_player, boneData.ID), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, 1)
                            attached = true
                            attachedToSessionPlayer = true
                        else
                            gui.show_error("Object Spawner", "Failed to take control of the player. Maybe they have protections?")
                        end
                    else
                        gui.show_message("Object Spawner", "Click on a player from YimMenu's player list then come back.")
                    end
                end
            else
                gui.show_error("Object Spawner", "There is nothing to attach! Did you spawn an object?")
            end
        end
        if ImGui.Button("   Detach  ") then
            all_objects = entities.get_all_objects_as_handles()
            for _, v in ipairs(all_objects) do
                script.run_in_fiber(function()
                    modelHash = ENTITY.GET_ENTITY_MODEL(v)
                    attachment = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(session_player, modelHash)
                    if ENTITY.DOES_ENTITY_EXIST(attachment) then
                        ENTITY.DETACH_ENTITY(attachment)
                        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(attachment)
                        attached = false
                        attachedToSelf = false
                        attachedToSessionPlayer = false
                    end
                end)
            end
        end
    end
end)
object_spawner:add_separator()
defaultSpawnDistance.x = spawnDistance.x
defaultSpawnDistance.y = spawnDistance.y
defaultSpawnDistance.z = spawnDistance.z
default_h_offset = h_offset
defaultSpawnRot.x = spawnRot.x
defaultSpawnRot.y = spawnRot.y
defaultSpawnRot.z = spawnRot.z
object_spawner:add_imgui(function()
    edit_mode, used = ImGui.Checkbox("Edit Mode", edit_mode, true)
    ImGui.SameLine()
    ImGui.TextDisabled("(?)")
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text("Enable to reposition the prop \nafter you spawn it.")
        ImGui.EndTooltip()
    end
    if edit_mode and not attached then
        ImGui.Text("Multiply X, Y, and Z values:")
        ImGui.PushItemWidth(280)
        axisMult, _ = ImGui.InputInt("##multiplier", axisMult, 1, 2, 0)
        ImGui.Text("Move Object:")
        ImGui.Text("                        X Axis :")
        spawnDistance.x, _ = ImGui.SliderFloat(" ", spawnDistance.x, -0.1 * axisMult, 0.1 * axisMult)
        activeX = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                        Y Axis :")
        spawnDistance.y, _ = ImGui.SliderFloat("  ", spawnDistance.y, -0.1 * axisMult, 0.1 * axisMult)
        activeY = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                        Z Axis :")
        spawnDistance.z, _ = ImGui.SliderFloat("   ", spawnDistance.z, -0.05 * axisMult, 0.05 * axisMult)
        activeZ = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                        Heading :")
        h_offset, _ = ImGui.SliderInt("    ", h_offset, -10, 10)
        activeH = ImGui.IsItemActive()
        ImGui.PopItemWidth()
    end
    if edit_mode and attached then
        ImGui.Text("Multiply X, Y, and Z values:")
        axisMult, _ = ImGui.InputInt("##multiplier", axisMult, 1, 2, 0)
        ImGui.Text("Move Attached Object:")
        ImGui.Text("                        X Axis :")
        ImGui.PushItemWidth(280)
        spawnDistance.x, _ = ImGui.SliderFloat("##X", spawnDistance.x, -0.1 * axisMult, 0.1 * axisMult)
        activeX = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                        Y Axis :")
        spawnDistance.y, _ = ImGui.SliderFloat("##Y", spawnDistance.y, -0.1 * axisMult, 0.1 * axisMult)
        activeY = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                        Z Axis :")
        spawnDistance.z, _ = ImGui.SliderFloat("##Z", spawnDistance.z, -0.1 * axisMult, 0.1 * axisMult)
        activeZ = ImGui.IsItemActive()
        ImGui.Text("                        X Rotation :")
        spawnRot.x, _ = ImGui.SliderFloat("##rotX", spawnRot.x, -180, 180)
        rotX = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                        Y Rotation :")
        spawnRot.y, _ = ImGui.SliderFloat("##rotY", spawnRot.y, -180, 180)
        rotY = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                        Z Rotation :")
        spawnRot.z, _ = ImGui.SliderFloat("##rotZ", spawnRot.z, -180, 180)
        rotZ = ImGui.IsItemActive()
        ImGui.PopItemWidth()
    end
    if ImGui.Button("   Reset   ") then
        resetSliders()
        for _, v in ipairs(spawned_props) do
            if attached then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(v, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, 1)
            else
                ENTITY.SET_ENTITY_COORDS(v, coords.x + (forwardX * 1.7), coords.y + (forwardY * 1.7), coords.z)
                ENTITY.SET_ENTITY_HEADING(v, heading)
                OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(v)
            end
        end
    end
    ImGui.SameLine()
    ImGui.TextDisabled("(?)")
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text("Reset the sliders to zero and the prop position to default.")
        ImGui.EndTooltip()
    end
    ImGui.Spacing(); ImGui.Spacing(); ImGui.Spacing(); ImGui.Spacing(); ImGui.Separator()
    dev, checked = ImGui.Checkbox("Dev Debug", dev, true)
    if dev then
        if ImGui.Button("Debug Table") then
            for k, v in ipairs(spawned_props) do
                log.info("DEBUG | Index "..tostring(k)..": network ID = "..tostring(v)..", network control = "..retval.." Attached?: "..tostring(attached))
            end
            local ped = self.get_ped()
            local session_player = PLAYER.GET_PLAYER_PED(network.get_selected_player())
            log.info("You: "..tostring(ped).." | Selected Player: "..tostring(session_player))
        end
    end
end)
script.register_looped("edit mode", function(script)
    if edit_mode and not attached then
        script:yield()
        for _, v in ipairs(spawned_props) do
            local current_coords = ENTITY.GET_ENTITY_COORDS(v)
            local current_heading = ENTITY.GET_ENTITY_HEADING(v)
            if activeX then
                ENTITY.SET_ENTITY_COORDS(v, current_coords.x + spawnDistance.x, current_coords.y, current_coords.z)
            end
            if activeY then
                ENTITY.SET_ENTITY_COORDS(v, current_coords.x, current_coords.y + spawnDistance.y, current_coords.z)
            end
            if activeZ then
                ENTITY.SET_ENTITY_COORDS(v, current_coords.x, current_coords.y, current_coords.z + spawnDistance.z)
            end
            if activeH then
                ENTITY.SET_ENTITY_HEADING(v, current_heading + h_offset)
            end
        end
    end
    if edit_mode and attached then
        script:yield()
        if attachedToSelf then
            plyr = self.get_ped()
        elseif attachedToSessionPlayer then
            plyr = session_player
        end
        local boneCoords = PED.GET_PED_BONE_COORDS(boneData.ID)
        local rotation = ENTITY.GET_ENTITY_ROTATION(v, 2)
        for _, v in ipairs(spawned_props) do
            if activeX then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(v, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
            end
            if activeY then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(v, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
            end
            if activeZ then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(v, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
            end
            if rotX then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(v, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
            end
            if rotY then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(v, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
            end
            if rotZ then
                ENTITY.ATTACH_ENTITY_TO_ENTITY(v, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
            end
        end
    end
end)