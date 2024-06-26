---@diagnostic disable: undefined-global, lowercase-global

object_spawner = gui.get_tab("Object Spawner")
require ("os_data")
local coords               = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
local heading              = ENTITY.GET_ENTITY_HEADING(self.get_ped())
local forwardX             = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
local forwardY             = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
local searchQuery          = ""
local propName             = ""
local invalidType          = ""
local showCustomProps      = true
local edit_mode            = false
local activeX          	   = false
local activeY          	   = false
local activeZ          	   = false
local rotX             	   = false
local rotY                 = false
local rotZ             	   = false
local is_typing            = false
local attached         	   = false
local attachedToSelf   	   = false
local previewStarted       = false
local isChanged            = false
local showInvalidObjText   = false
-- local attachedToPlayer 	   = false
local prop                 = 0
local propHash             = 0
local switch               = 0
local prop_index           = 0
local objects_index        = 0
local spawned_index        = 0
local selectedObject       = 0
local axisMult             = 1
local selected_bone        = 0
local playerIndex          = 0
local previewEntity        = 0
local currentObjectPreview = 0
local zOffset              = 0
local spawned_props        = {}
local spawnedNames         = {}
local filteredSpawnNames   = {}
local spawnDistance        = { x = 0, y = 0, z = 0 }
local spawnRot             = { x = 0, y = 0, z = 0 }
local attachPos            = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0}
local pedBones             = {
	{name = "Root",       ID = 0    },
	{name = "Head",       ID = 12844},
	{name = "Spine 00",   ID = 23553},
	{name = "Spine 01",   ID = 24816},
	{name = "Spine 02",   ID = 24817},
	{name = "Spine 03",   ID = 24818},
	{name = "Right Hand", ID = 6286 },
	{name = "Left Hand",  ID = 18905},
	{name = "Right Foot", ID = 35502},
	{name = "Left Foot",  ID = 14201},
}
local function resetSliders()
	spawnDistance = { x = 0, y = 0, z = 0 }
	spawnRot      = { x = 0, y = 0, z = 0 }
	attachPos     = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0}
end
script.register_looped("game input", function()
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
local function updateFilteredProps()
	filteredProps = {}
	for _, p in ipairs(custom_props) do
		if string.find(string.lower(p.name), string.lower(searchQuery)) then
			table.insert(filteredProps, p)
		end
		table.sort(custom_props, function(a, b)
			return a.name < b.name
		end)
	end
end
local function displayFilteredProps()
	updateFilteredProps()
	local propNames = {}
	for _, p in ipairs(filteredProps) do
		table.insert(propNames, p.name)
	end
	prop_index, used = ImGui.ListBox("##propList", prop_index, propNames, #filteredProps)
	prop = filteredProps[prop_index + 1]
	if prop ~= nil then
		propHash = prop.hash
		propName = prop.name
	end
end
local function getAllObjects()
	filteredObjects = {}
	for _, object in ipairs(gta_objets) do
		if searchQuery ~= "" then
			if string.find(string.lower(object), string.lower(searchQuery)) then
				table.insert(filteredObjects, object)
			end
		else
			table.insert(filteredObjects, object)
		end
	end
	objects_index, used = ImGui.ListBox("##gtaObjectsList", objects_index, filteredObjects, #filteredObjects)
	prop     = filteredObjects[objects_index + 1]
	propHash = joaat(prop)
	propName = prop
	if gui.is_open() and not showCustomProps then
		for _, b in ipairs(mp_blacklist) do
			if propName == b then
				showInvalidObjText = true
				invalidType = "blacklisted by Rockstar and will not spawn."
				break
			else
				showInvalidObjText = false
			end
			for _, c in ipairs(crash_objects) do
				if propName == c then
					showInvalidObjText = true
					invalidType = "a crash object. Proceed with caution!"
					break
				else
					showInvalidObjText = false
				end
			end
		end
	end
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
local function getNameDupes(table, name)
	local count = 0
	for __, nn in pairs(table) do
		if name == nn then
			count = count + 1
		end
	end
	return count
end
local function updatePlayerList()
	local players = entities.get_all_peds_as_handles()
	filteredPlayers = {}
	for _, ped in ipairs(players) do
	  if PED.IS_PED_A_PLAYER(ped) then
		if NETWORK.NETWORK_IS_PLAYER_ACTIVE(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)) then
		  table.insert(filteredPlayers, ped)
		end
	  end
	end
end
local function displayPlayerList()
	updatePlayerList()
	local playerNames = {}
	for _, player in ipairs(filteredPlayers) do
      local playerName  = PLAYER.GET_PLAYER_NAME(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(player))
      local playerHost  = NETWORK.NETWORK_GET_HOST_PLAYER_INDEX()
      local friendCount = NETWORK.NETWORK_GET_FRIEND_COUNT()
      if NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(player) == PLAYER.PLAYER_ID() then
        playerName = playerName.."  [You]"
      end
      if friendCount > 0 then
        for i = 0, friendCount do
          if playerName == NETWORK.NETWORK_GET_FRIEND_NAME(i) then
            playerName = playerName.."  [Friend]"
          end
        end
      end
      if playerHost == NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(player) then
        playerName = playerName.."  [Host]"
      end
      table.insert(playerNames, playerName)
    end
	playerIndex, used = ImGui.Combo("##playerList", playerIndex, playerNames, #filteredPlayers)
end
local function clearPreviewData()
	pedPreviewModel     = 0
	vehiclePreviewModel = 0
	objectPreviewModel  = 0
end
local function stopPreview()
	if previewStarted then
		previewStarted = false
	end
	clearPreviewData()
end
object_spawner:add_imgui(function()
	switch, isChanged = ImGui.RadioButton("Custom Objects", switch, 0)
	if isChanged then
		showCustomProps = true
	end
	ImGui.SameLine()
	switch, isChanged = ImGui.RadioButton("All Objects", switch, 1)
	if isChanged then
		showCustomProps = false
	end
end)
object_spawner:add_imgui(function()
	if showCustomProps then
		ImGui.PushItemWidth(300)
		displayFilteredProps()
		ImGui.PopItemWidth()
	else
		ImGui.PushItemWidth(300)
		getAllObjects()
		ImGui.PopItemWidth()
	end
	ImGui.Spacing()
	preview, _ = ImGui.Checkbox("Preview", preview, true)
	if preview then
		spawnCoords          = ENTITY.GET_ENTITY_COORDS(previewEntity, false)
		previewLoop          = true
		currentObjectPreview = propHash
		local previewObjectPos = ENTITY.GET_ENTITY_COORDS(previewEntity, false)
		ImGui.Text("Move Front/Back:");ImGui.SameLine();ImGui.Spacing();ImGui.SameLine();ImGui.Text("Move Up/Down:")
		ImGui.Dummy(10, 1);ImGui.SameLine()
		ImGui.ArrowButton("##f2", 2)
		if ImGui.IsItemActive() then
			forwardX = forwardX * 0.1
			forwardY = forwardY * 0.1
			ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x + forwardX, previewObjectPos.y + forwardY, previewObjectPos.z)
		end
		ImGui.SameLine()
		ImGui.ArrowButton("##f3", 3)
		if ImGui.IsItemActive() then
			forwardX = forwardX * 0.1
			forwardY = forwardY * 0.1
			ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x - forwardX, previewObjectPos.y - forwardY, previewObjectPos.z)
		end
		ImGui.SameLine()ImGui.Dummy(60, 1);ImGui.SameLine()
		ImGui.ArrowButton("##z2", 2)
		if ImGui.IsItemActive() then
			zOffset = zOffset + 0.01
			ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x, previewObjectPos.y, previewObjectPos.z + 0.01)
		end
		ImGui.SameLine()
		ImGui.ArrowButton("##z3", 3)
		if ImGui.IsItemActive() then
			zOffset = zOffset - 0.01
			ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x, previewObjectPos.y, previewObjectPos.z - 0.01)
		end
	else
		previewStarted = false
		previewLoop    = false
		zOffset        = 0.0
		forwardX       = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
		forwardY       = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
	end
	if NETWORK.NETWORK_IS_SESSION_ACTIVE() then
		if not preview then
			ImGui.SameLine()
		end
		spawnForPlayer, _ = ImGui.Checkbox("Spawn For a Player", spawnForPlayer, true)
	end
	if spawnForPlayer then
		ImGui.PushItemWidth(200)
		displayPlayerList()
		ImGui.PopItemWidth()
		local selectedPlayer = filteredPlayers[playerIndex + 1]
		coords   = ENTITY.GET_ENTITY_COORDS(selectedPlayer, false)
		heading  = ENTITY.GET_ENTITY_HEADING(selectedPlayer)
		forwardX = ENTITY.GET_ENTITY_FORWARD_X(selectedPlayer)
		forwardY = ENTITY.GET_ENTITY_FORWARD_Y(selectedPlayer)
		ImGui.SameLine()
	else
		coords   = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
		heading  = ENTITY.GET_ENTITY_HEADING(self.get_ped())
		forwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
		forwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
	end
	if ImGui.Button("   Spawn  ") then
		script.run_in_fiber(function()
			while not STREAMING.HAS_MODEL_LOADED(propHash) do
				STREAMING.REQUEST_MODEL(propHash)
				coroutine.yield()
			end
			if preview then
				spawnedObject = OBJECT.CREATE_OBJECT(propHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, false)
			else
				spawnedObject = OBJECT.CREATE_OBJECT(propHash, coords.x + (forwardX * 3), coords.y + (forwardY * 3), coords.z, true, true, false)
			end
			if ENTITY.DOES_ENTITY_EXIST(spawnedObject) then
				ENTITY.SET_ENTITY_HEADING(spawnedObject, heading)
				OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(spawnedObject)
				table.insert(spawned_props, spawnedObject)
				table.insert(spawnedNames, propName)
				local dupes = getNameDupes(spawnedNames, propName)
				if dupes > 1 then
					newPropName = propName.." #"..tostring(dupes)
					table.insert(filteredSpawnNames, newPropName)
				else
					table.insert(filteredSpawnNames, propName)
				end
			else
				gui.show_error("Object Spawner", "This object is blacklisted by R*.")
			end
		end)
	end
	if showInvalidObjText then
		ImGui.PushStyleColor(ImGuiCol.Text, 1, 0.6, 0.4, 1)
		ImGui.TextWrapped("This object is "..invalidType)
		ImGui.PopStyleColor(1)
	end
	if spawned_props[1] ~= nil then
		ImGui.Text("Spawned Objects:")
		ImGui.PushItemWidth(230)
		spawned_index, used = ImGui.Combo("##Spawned Objects", spawned_index, filteredSpawnNames, #spawned_props)
		ImGui.PopItemWidth()
		selectedObject = spawned_props[spawned_index + 1]
		ImGui.SameLine()
		if ImGui.Button("Delete") then
			script.run_in_fiber(function(script)
				if ENTITY.DOES_ENTITY_EXIST(selectedObject) then
					ENTITY.SET_ENTITY_AS_MISSION_ENTITY(selectedObject)
					script:sleep(100)
					ENTITY.DELETE_ENTITY(selectedObject)
					table.remove(spawnedNames, spawned_index + 1)
					table.remove(filteredSpawnNames, spawned_index + 1)
					table.remove(spawned_props, spawned_index + 1)
					spawned_index = 0
					if spawned_index > 1 then
						spawned_index = spawned_index - 1
					end
					if attached then
						attachPos        = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0}
						attached         = false
						attachedToSelf   = false
						attachedToPlayer = false
					end
				end
			end)
		end
		ImGui.Separator()
		attachTo, used = ImGui.Checkbox("Attach Objects", attachTo, true)
		if attachTo then
			displayBones()
			boneData = filteredBones[selected_bone + 1]
			if ImGui.Button("Attach To Yourself") then
				script.run_in_fiber(function()
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, self.get_ped(), PED.GET_PED_BONE_INDEX(self.get_ped(), boneData.ID), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, 1)
					attached = true
					attachedToSelf = true
				end)
			end
			ImGui.SameLine()
			if ImGui.Button("   Detach  ") then
				script.run_in_fiber(function()
					local modelHash  = ENTITY.GET_ENTITY_MODEL(selectedObject)
					local attachment = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(self.get_ped(), modelHash)
					if ENTITY.DOES_ENTITY_EXIST(attachment) then
						ENTITY.DETACH_ENTITY(attachment)
						-- OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(attachment)
						attached = false
						attachedToSelf = false
						-- attachedToPlayer = false
						attachPos = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0}
					end
				end)
			end
		end
		ImGui.Separator()
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
			ImGui.Separator();ImGui.Text("Rotate Object:")
			ImGui.Text("                        X Axis :")
			spawnRot.x, _ = ImGui.SliderFloat("##xRot", spawnRot.x, -0.1 * axisMult, 0.1 * axisMult)
			rotX = ImGui.IsItemActive()
			ImGui.Separator()
			ImGui.Text("                        Y Axis :")
			spawnRot.y, _ = ImGui.SliderFloat("##yRot", spawnRot.y, -0.1 * axisMult, 0.1 * axisMult)
			rotY = ImGui.IsItemActive()
			ImGui.Separator()
			ImGui.Text("                        Z Axis :")
			spawnRot.z, _ = ImGui.SliderFloat("##zRot", spawnRot.z, -0.5 * axisMult, 0.5 * axisMult)
			rotZ = ImGui.IsItemActive()
			ImGui.PopItemWidth()
		else
			if edit_mode and attached then
				ImGui.Text("Move Attached Object:");ImGui.Separator();ImGui.Spacing()
				if attachedToSelf then
					plyr = self.get_ped()
				else
					-- plyr = targetPlayer
				end
				ImGui.Text("Multiply values:")
				ImGui.PushItemWidth(271)
				axisMult, _ = ImGui.InputInt("##AttachMultiplier", axisMult, 1, 2, 0)
				ImGui.PopItemWidth()
				ImGui.Spacing()
				ImGui.Text("X Axis :");ImGui.SameLine();ImGui.Dummy(25, 1);ImGui.SameLine();ImGui.Text("Y Axis :");ImGui.SameLine()ImGui.Dummy(25, 1);ImGui.SameLine();ImGui.Text("Z Axis :")
				ImGui.ArrowButton("##Xleft", 0)
				if ImGui.IsItemActive() then
					attachPos.x = attachPos.x + 0.001
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()
				ImGui.ArrowButton("##XRight", 1)
				if ImGui.IsItemActive() then
					attachPos.x = attachPos.x - 0.001 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()ImGui.Dummy(5, 1);ImGui.SameLine()
				ImGui.ArrowButton("##Yleft", 0)
				if ImGui.IsItemActive() then
					attachPos.y = attachPos.y + 0.001 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()
				ImGui.ArrowButton("##YRight", 1)
				if ImGui.IsItemActive() then
					attachPos.y = attachPos.y - 0.001 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()ImGui.Dummy(5, 1);ImGui.SameLine()
				ImGui.ArrowButton("##zUp", 2)
				if ImGui.IsItemActive() then
					attachPos.z = attachPos.z + 0.001 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()
				ImGui.ArrowButton("##zDown", 3)
				if ImGui.IsItemActive() then
					attachPos.z = attachPos.z - 0.001 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.Text("X Rotation :");ImGui.SameLine();ImGui.Text("Y Rotation :");ImGui.SameLine();ImGui.Text("Z Rotation :")
				ImGui.ArrowButton("##rotXleft", 0)
				if ImGui.IsItemActive() then
					attachPos.rotX = attachPos.rotX + 1 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()
				ImGui.ArrowButton("##rotXright", 1)
				if ImGui.IsItemActive() then
					attachPos.rotX = attachPos.rotX - 1 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()ImGui.Dummy(5, 1);ImGui.SameLine()
				ImGui.ArrowButton("##rotYleft", 0)
				if ImGui.IsItemActive() then
					attachPos.rotY = attachPos.rotY + 1 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()
				ImGui.ArrowButton("##rotYright", 1)
				if ImGui.IsItemActive() then
					attachPos.rotY = attachPos.rotY - 1 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()ImGui.Dummy(5, 1);ImGui.SameLine()
				ImGui.ArrowButton("##rotZup", 2)
				if ImGui.IsItemActive() then
					attachPos.rotZ = attachPos.rotZ + 1 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
				ImGui.SameLine()
				ImGui.ArrowButton("##rotZdown", 3)
				if ImGui.IsItemActive() then
					attachPos.rotZ = attachPos.rotZ - 1 * axisMult
					ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), attachPos.x, attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true, 1)
				end
			end
		end
		if ImGui.Button("   Reset   ") then
			resetSliders()
			if attached then
				ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, 1)
			else
				ENTITY.SET_ENTITY_COORDS(selectedObject, coords.x + (forwardX * 3), coords.y + (forwardY * 3), coords.z)
				ENTITY.SET_ENTITY_HEADING(selectedObject, heading)
				OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(selectedObject)
			end
		end
		ImGui.SameLine()
		ImGui.TextDisabled("(?)")
		if ImGui.IsItemHovered() then
			ImGui.BeginTooltip()
			ImGui.Text("Reset the sliders to zero and the prop position to default.")
			ImGui.EndTooltip()
		end
	end
end)
script.register_looped("Preview", function(preview)
	if previewLoop and gui.is_open() then
		local currentHeading = ENTITY.GET_ENTITY_HEADING(previewEntity)
		if currentObjectPreview ~= previewEntity then
			ENTITY.DELETE_ENTITY(previewEntity)
			previewStarted = false
		end
		if isChanged then
			ENTITY.DELETE_ENTITY(previewEntity)
			previewStarted = false
		end
		if not ENTITY.IS_ENTITY_DEAD(self.get_ped()) then
			while not STREAMING.HAS_MODEL_LOADED(propHash) do
				STREAMING.REQUEST_MODEL(propHash)
				coroutine.yield()
			end
			if not previewStarted then
				previewEntity = OBJECT.CREATE_OBJECT(propHash, coords.x + forwardX * 5, coords.y + forwardY * 5, coords.z, currentHeading, false, false, false)
				ENTITY.SET_ENTITY_ALPHA(previewEntity, 200.0, false)
				ENTITY.SET_ENTITY_COLLISION(previewEntity, false, false)
				ENTITY.SET_ENTITY_CAN_BE_DAMAGED(previewEntity, false)
				ENTITY.SET_ENTITY_PROOFS(previewEntity, true, true, true, true, true, true, true, true)
				ENTITY.SET_CAN_CLIMB_ON_ENTITY(previewEntity, false)
				OBJECT.SET_OBJECT_ALLOW_LOW_LOD_BUOYANCY(previewEntity, false)
				currentObjectPreview = ENTITY.GET_ENTITY_MODEL(previewEntity)
				previewStarted = true
			end
			if PED.IS_PED_STOPPED(self.get_ped()) then
				while true do
					preview:yield()
					if gui.is_open() then
						currentHeading = currentHeading + 1
						ENTITY.SET_ENTITY_HEADING(previewEntity, currentHeading)
						preview:sleep(10)
						if currentObjectPreview ~= ENTITY.GET_ENTITY_MODEL(previewEntity) then
							ENTITY.DELETE_ENTITY(previewEntity)
							previewStarted = false
						end
						if not PED.IS_PED_STOPPED(self.get_ped()) or not previewStarted then
							previewStarted = false
							break
						end
					else
						ENTITY.DELETE_ENTITY(previewEntity)
						previewStarted = false
					end
				end
			else
				return
			end
		end
	else
		ENTITY.DELETE_ENTITY(previewEntity)
		stopPreview()
	end
end)
script.register_looped("edit mode", function()
	if spawned_props[1] ~= nil then
		if edit_mode and not attached then
			local current_coords = ENTITY.GET_ENTITY_COORDS(selectedObject)
			local current_rotation = ENTITY.GET_ENTITY_ROTATION(selectedObject, 2)
			if activeX then
				ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x + spawnDistance.x, current_coords.y, current_coords.z)
			end
			if activeY then
				ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x, current_coords.y + spawnDistance.y, current_coords.z)
			end
			if activeZ then
				ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x, current_coords.y, current_coords.z + spawnDistance.z)
			end
			if rotX then
				ENTITY.SET_ENTITY_ROTATION(selectedObject, current_rotation.x + spawnRot.x, current_rotation.y, current_rotation.z, 2, true)
			end
			if rotY then
				ENTITY.SET_ENTITY_ROTATION(selectedObject, current_rotation.x, current_rotation.y + spawnRot.y, current_rotation.z, 2, true)
			end
			if rotZ then
				ENTITY.SET_ENTITY_ROTATION(selectedObject, current_rotation.x, current_rotation.y, current_rotation.z + spawnRot.z, 2, true)
			end
		end
		for k, v in ipairs(spawned_props) do
			if not ENTITY.DOES_ENTITY_EXIST(v) then
				table.remove(spawned_props, k)
			end
		end
    end
end)