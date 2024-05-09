---@diagnostic disable: undefined-global, lowercase-global

object_spawner = gui.get_tab("Object Spawner")
local custom_props     		 = require ("os_proplist")
local gta_objets       		 = require("gta_objects")
local searchQuery          = ""
local showCustomProps      = true
local edit_mode            = false
local activeX          		 = false
local activeY          		 = false
local activeZ          		 = false
local activeH          		 = false
local rotX             		 = false
local rotY              	 = false
local rotZ             		 = false
local is_typing            = false
local attached         		 = false
local attachedToSelf   		 = false
-- local attachedToPlayer 		 = false
local propHash             = 0
local switch               = 0
local default_h_offset     = 0
local prop_index           = 0
local objects_index        = 0
local spawned_index        = 0
local selectedObject       = 0
local h_offset             = 0
local axisMult             = 1
local selected_bone        = 0
local spawned_props        = {}
local spawnedNames         = {}
local spawnDistance        = { x = 0, y = 0, z = 0 }
local defaultSpawnDistance = { x = 0, y = 0, z = 0 }
local spawnRot             = { x = 0, y = 0, z = 0 }
local defaultSpawnRot      = { x = 0, y = 0, z = 0 }
defaultSpawnDistance.x = spawnDistance.x
defaultSpawnDistance.y = spawnDistance.y
defaultSpawnDistance.z = spawnDistance.z
default_h_offset  = h_offset
defaultSpawnRot.x = spawnRot.x
defaultSpawnRot.y = spawnRot.y
defaultSpawnRot.z = spawnRot.z
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
	spawnDistance.x = defaultSpawnDistance.x
	spawnDistance.y = defaultSpawnDistance.y
	spawnDistance.z = defaultSpawnDistance.z
	h_offset   = default_h_offset
	spawnRot.x = defaultSpawnRot.x
	spawnRot.y = defaultSpawnRot.y
	spawnRot.z = defaultSpawnRot.z
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
	for _, prop in ipairs(custom_props) do
		if string.find(string.lower(prop.name), string.lower(searchQuery)) then
			table.insert(filteredProps, prop)
		end
		table.sort(custom_props, function(a, b)
			return a.name < b.name
		end)
	end
end
local function displayFilteredProps()
	updateFilteredProps()
	local propNames = {}
	for _, prop in ipairs(filteredProps) do
		table.insert(propNames, prop.name)
	end
	prop_index, used = ImGui.ListBox("##propList", prop_index, propNames, #filteredProps)
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
object_spawner:add_imgui(function()
	local isChanged = false
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
	local coords   = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
	local heading  = ENTITY.GET_ENTITY_HEADING(self.get_ped())
	local forwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
	local forwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
	ImGui.Spacing()
	ImGui.SameLine()
	if ImGui.Button("   Spawn  ") then
		preview = false
		script.run_in_fiber(function()
			if showCustomProps then
				local prop = filteredProps[prop_index + 1]
				propHash   = prop.hash
				propName   = prop.name
			else
				local prop = filteredObjects[objects_index + 1]
				propHash   = joaat(prop)
				propName   = prop
			end
			while not STREAMING.HAS_MODEL_LOADED(propHash) do
				STREAMING.REQUEST_MODEL(propHash)
				coroutine.yield()
			end
			spawnedObject = OBJECT.CREATE_OBJECT(propHash, coords.x + (forwardX * 2), coords.y + (forwardY * 2), coords.z, true, true, false)
			if ENTITY.DOES_ENTITY_EXIST(spawnedObject) then
				ENTITY.SET_ENTITY_HEADING(spawnedObject, heading)
				OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(spawnedObject)
				table.insert(spawned_props, spawnedObject)
				table.insert(spawnedNames, propName)
			else
				gui.show_error("Object Spawner", "This object is blacklisted by R*.")
			end
		end)
	end
	if spawned_props[1] ~= nil then
		ImGui.Text("Spawned Objects:")
		ImGui.PushItemWidth(180)
		spawned_index, used = ImGui.Combo("##Spawned Objects", spawned_index, spawnedNames, #spawned_props)
		ImGui.PopItemWidth()
		selectedObject = spawned_props[spawned_index + 1]
		ImGui.SameLine()
		if ImGui.Button("   Delete  ") then
			script.run_in_fiber(function(script)
				if ENTITY.DOES_ENTITY_EXIST(selectedObject) then
					ENTITY.SET_ENTITY_AS_MISSION_ENTITY(selectedObject)
					script:sleep(100)
					ENTITY.DELETE_ENTITY(selectedObject)
					table.remove(spawnedNames, spawned_index + 1)
					table.remove(spawned_props, spawned_index + 1)
					spawned_index = 0
					if spawned_index > 1 then
						spawned_index = spawned_index - 1
					end
					attached         = false
					attachedToSelf   = false
					attachedToPlayer = false
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
						OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(attachment)
						-- ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(attachment)
						attached = false
						attachedToSelf = false
						-- attachedToPlayer = false
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
			if attached then
				ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, 1)
			else
				ENTITY.SET_ENTITY_COORDS(selectedObject, coords.x + (forwardX * 2), coords.y + (forwardY * 2), coords.z)
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
script.register_looped("edit mode", function(script)
	if spawned_props[1] ~= nil then
		script:yield()
		if edit_mode and not attached then
			local current_coords = ENTITY.GET_ENTITY_COORDS(selectedObject)
			local current_heading = ENTITY.GET_ENTITY_HEADING(selectedObject)
			if activeX then
				ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x + spawnDistance.x, current_coords.y, current_coords.z)
			end
			if activeY then
				ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x, current_coords.y + spawnDistance.y, current_coords.z)
			end
			if activeZ then
				ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x, current_coords.y, current_coords.z + spawnDistance.z)
			end
			if activeH then
				ENTITY.SET_ENTITY_HEADING(selectedObject, current_heading + h_offset)
			end
		end
		if edit_mode and attached then
			if attachedToSelf then
				plyr = self.get_ped()
			elseif attachedToPlayer then
				plyr = session_player
			end
			local boneCoords = PED.GET_PED_BONE_COORDS(boneData.ID)
			local rotation = ENTITY.GET_ENTITY_ROTATION(selectedObject, 2)
			if activeX then
				ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
			end
			if activeY then
				ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
			end
			if activeZ then
				ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
			end
			if rotX then
				ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
			end
			if rotY then
				ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
			end
			if rotZ then
				ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, plyr, PED.GET_PED_BONE_INDEX(plyr, boneData.ID), boneCoords.x + spawnDistance.x, boneCoords.y + spawnDistance.y, boneCoords.z  + spawnDistance.z, rotation.x + spawnRot.x, rotation.y + spawnRot.y, rotation.z + spawnRot.z, false, false, false, false, 2, true, 1)
			end
		end
  end
end)