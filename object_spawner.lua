---@diagnostic disable: undefined-global, lowercase-global
object_spawner = gui.get_tab("Object Spawner")

local props = {
    { hash = 1903501406, name = "Barbeque 1"},
    { hash = 286252949, name = "Barbeque 2"},
    { hash = 145818549, name = "Work Light 1"},
    { hash = 2393739772, name = "Work Light 2"},
    { hash = 3760607069, name = "Road Cone"},
    { hash = 3186063286, name = "Camping Chair"},
    { hash = 2796614321, name = "Patio Lounger"},
    { hash = 1792816905, name = "Kino Light (Photography)"},
    { hash = 2174673747, name = "Studio Light (Photography)"},
    { hash = 3640564381, name = "Vending Machine"},
    { hash = 1918323043, name = "Hobo Skid Trolley"},
    { hash = 4111834409, name = "Start/Finish Gate (Racing)"},
    { hash = 2544207977, name = "Inflate Arch (Racing)"}
}

local prop_index = 1

local spawnDistance = { x = 0, y = 0, z = -1 }
local defaultSpawnDistance = { x = 0, y = 0, z = -1 }
local function resetDistanceSliders()
    spawnDistance.x = defaultSpawnDistance.x
    spawnDistance.y = defaultSpawnDistance.y
    spawnDistance.z = defaultSpawnDistance.z
end

object_spawner:add_text("Select an Object")

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
end)

local filteredItems = {}
local function updateFilteredItems()
    filteredItems = {}
    for _, item in ipairs(props) do
        if string.find(string.lower(item.name), string.lower(searchQuery)) then
            table.insert(filteredItems, item)
        end
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

object_spawner:add_separator()

object_spawner:add_imgui(function()
    spawnDistance.x, _ = ImGui.SliderFloat("X Axis", spawnDistance.x, -30, 30)
    spawnDistance.y, _ = ImGui.SliderFloat("Y Axis", spawnDistance.y, -30, 30)
    spawnDistance.z, _ = ImGui.SliderFloat("Z Axis", spawnDistance.z, -30, 30)
end)

defaultSpawnDistance.x = spawnDistance.x
defaultSpawnDistance.y = spawnDistance.y
defaultSpawnDistance.z = spawnDistance.z

object_spawner:add_button("Reset Sliders", function()
    resetDistanceSliders()
end)

object_spawner:add_separator()

object_spawner:add_imgui(function()
    local ped = PLAYER.GET_PLAYER_PED(network.get_selected_player())
    local coords = ENTITY.GET_ENTITY_COORDS(ped, false)
    coords.x = coords.x + spawnDistance.x
    coords.y = coords.y + spawnDistance.y
    coords.z = coords.z + spawnDistance.z
    local heading = ENTITY.GET_ENTITY_HEADING(ped)
    local forwardX = ENTITY.GET_ENTITY_FORWARD_X(ped)
    local forwardY = ENTITY.GET_ENTITY_FORWARD_Y(ped)
    local object = filteredItems[prop_index+1]
    if ImGui.Button("Spawn Object") then
        script.run_in_fiber(function()
                if object then
                    while not STREAMING.HAS_MODEL_LOADED(object.hash) do
                        STREAMING.REQUEST_MODEL(object.hash)
                        coroutine.yield()
                    end
                end
            local prop = OBJECT.CREATE_OBJECT(object.hash, coords.x + (forwardX * 1), coords.y + (forwardY * 1), coords.z, true, true, false)
		if prop_index == 10 then
                	ENTITY.SET_ENTITY_HEADING(prop, heading - 180)
                	OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(prop)
            	else
            		ENTITY.SET_ENTITY_HEADING(prop, heading)
            		OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(prop)
		end
        end)
    end

        ImGui.SameLine()

    if ImGui.Button("Delete Object") then
        script.run_in_fiber(function()
            local spawned_prop = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(coords.x + (forwardX * 1), coords.y + (forwardY * 1), coords.z, 50, object.hash, true, false, false)
            if ENTITY.DOES_ENTITY_EXIST(spawned_prop) then
                OBJECT.DELETE_OBJECT(spawned_prop)
	    else
                gui.show_message("Object Spawner", "There is no "..object.name.." nearby")
            end
        end)
    end
end)
