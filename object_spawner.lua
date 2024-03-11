---@diagnostic disable: undefined-global, lowercase-global

object_spawner = gui.get_tab("Object Spawner")

props = require ("proplist")

local prop_index = 1
local h_offset = 0
local default_h_offset = 0
local spawnDistance = { x = 0, y = 0, z = 0 }
local defaultSpawnDistance = { x = 0, y = 0, z = 0 }
local edit_mode = false
local activeX = false
local activeY = false
local activeZ = false
local activeH = false
local resetPos = false
local function resetSliders()
    spawnDistance.x = defaultSpawnDistance.x
    spawnDistance.y = defaultSpawnDistance.y
    spawnDistance.z = defaultSpawnDistance.z
    h_offset = default_h_offset
end

object_spawner:add_text("Search:")

local searchQuery = ""

local is_typing = false
script.register_looped("Object Spawner", function()
	if is_typing then
		PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
	end
end)

object_spawner:add_imgui(function()
    searchQuery, used = ImGui.InputText("", searchQuery, 128)
    if ImGui.IsItemActive() then
		is_typing = true
	else
		is_typing = false
	end
    ImGui.PushItemWidth(300)
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

object_spawner:add_imgui(displayFilteredList)

object_spawner:add_imgui(function()
    ped = PLAYER.GET_PLAYER_PED(PLAYER.PLAYER_ID())
    coords = ENTITY.GET_ENTITY_COORDS(ped, false)
    heading = ENTITY.GET_ENTITY_HEADING(ped)
    forwardX = ENTITY.GET_ENTITY_FORWARD_X(ped)
    forwardY = ENTITY.GET_ENTITY_FORWARD_Y(ped)
    local object = filteredItems[prop_index+1]
    if ImGui.Button("   Spawn  ") then
        script.run_in_fiber(function()
            if object then
                while not STREAMING.HAS_MODEL_LOADED(object.hash) do
                    STREAMING.REQUEST_MODEL(object.hash)
                    coroutine.yield()
                end
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(object.hash)
            end
            prop = OBJECT.CREATE_OBJECT(object.hash, coords.x + (forwardX * 1.7), coords.y + (forwardY * 1.7), coords.z, true, true, false)
            ENTITY.SET_ENTITY_HEADING(prop, heading)
            OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(prop)
            while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(prop) do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(prop)
                coroutine:yield()
            end
            if ENTITY.DOES_ENTITY_EXIST(prop) then
                gui.show_message("Object Spawner", "Spawned '"..object.name..".")
            else
                gui.show_error("Object Spawner", "ERORR! '"..object.name.."' failed to load.")
            end
        end)
    end

    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()

    if ImGui.Button("   Delete  ") then
        script.run_in_fiber(function()
            if ENTITY.DOES_ENTITY_EXIST(prop) then
                OBJECT.DELETE_OBJECT(prop)
            else
                gui.show_error("Object Spawner", "There is no ''"..object.name.."'' nearby!")
            end
        end)
    end
end)

object_spawner:add_separator()

defaultSpawnDistance.x = spawnDistance.x
defaultSpawnDistance.y = spawnDistance.y
defaultSpawnDistance.z = spawnDistance.z
default_h_offset = h_offset

object_spawner:add_imgui(function()
    edit_mode, used = ImGui.Checkbox("Edit Mode", edit_mode, true)
    ImGui.SameLine()
    ImGui.TextDisabled("(?)")
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text("Enable to reposition the prop \nafter you spawn it.")
        ImGui.EndTooltip()
    end
    if edit_mode then
        ImGui.Text("Move Object:")
        ImGui.Text("                                    X Axis :")
        spawnDistance.x, _ = ImGui.SliderFloat(" ", spawnDistance.x, -0.1, 0.1)
        activeX = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                                    Y Axis :")
        spawnDistance.y, _ = ImGui.SliderFloat("  ", spawnDistance.y, -0.1, 0.1)
        activeY = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                                    Z Axis :")
        spawnDistance.z, _ = ImGui.SliderFloat("   ", spawnDistance.z, -0.05, 0.05)
        activeZ = ImGui.IsItemActive()
        ImGui.Separator()
        ImGui.Text("                                    Heading :")
        h_offset, _ = ImGui.SliderInt("    ", h_offset, -10, 10)
        activeH = ImGui.IsItemActive()
    end
    if ImGui.Button("   Reset   ") then
        resetSliders()
        ENTITY.SET_ENTITY_COORDS(prop, coords.x + (forwardX * 1.7), coords.y + (forwardY * 1.7), coords.z)
        ENTITY.SET_ENTITY_HEADING(prop, heading)
        OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(prop)
    end
    ImGui.SameLine()
    ImGui.TextDisabled("(?)")
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text("Reset the sliders to zero and teleport\nthe prop in front of you.")
        ImGui.EndTooltip()
    end
end)

script.register_looped("edit mode", function(script)
    if edit_mode then
        script:yield()
        local current_coords = ENTITY.GET_ENTITY_COORDS(prop)
        local current_heading = ENTITY.GET_ENTITY_HEADING(prop)
        if activeX then
            ENTITY.SET_ENTITY_COORDS(prop, current_coords.x + spawnDistance.x, current_coords.y, current_coords.z)
        end
        if activeY then
            ENTITY.SET_ENTITY_COORDS(prop, current_coords.x, current_coords.y + spawnDistance.y, current_coords.z)
        end
        if activeZ then
            ENTITY.SET_ENTITY_COORDS(prop, current_coords.x, current_coords.y, current_coords.z + spawnDistance.z)
        end
        if activeH then
            ENTITY.SET_ENTITY_HEADING(prop, current_heading + h_offset)
        end
    end
end)