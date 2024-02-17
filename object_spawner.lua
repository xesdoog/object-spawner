---@diagnostic disable: undefined-global, lowercase-global
object_spawner = gui.get_tab("Object Spawner")

local props = {
    { hash = 1903501406, name = "Barbeque 1"},
    { hash = 286252949, name = "Barbeque 2"},
    { hash = 145818549, name = "Work Light 1"},
    { hash = 2393739772, name = "Work Light 2"},
    { hash = 1792816905, name = "Kino Light (Photography)"},
    { hash = 2174673747, name = "Studio Light (Photography)"},
    { hash = 1918323043, name = "Hobo Skid Trolley"},
    { hash = 2796614321, name = "Patio Lounger"},
    { hash = 3186063286, name = "Camping Chair"}
}

local prop_index = 1

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

object_spawner:add_button("Spawn Selected", function()
    script.run_in_fiber(function()
        local ped = PLAYER.GET_PLAYER_PED(network.get_selected_player())
        local coords = ENTITY.GET_ENTITY_COORDS(ped, false)
        local heading = ENTITY.GET_ENTITY_HEADING(ped)
        local forwardX = ENTITY.GET_ENTITY_FORWARD_X(ped)
        local forwardY = ENTITY.GET_ENTITY_FORWARD_Y(ped)
        local object = filteredItems[prop_index+1]
            if object then
                while not STREAMING.HAS_MODEL_LOADED(object.hash) do
                    STREAMING.REQUEST_MODEL(object.hash)
                    coroutine.yield()
                end
            end
        local prop = OBJECT.CREATE_OBJECT(object.hash, coords.x + (forwardX * 1), coords.y + (forwardY * 1), coords.z, true, true, false)
        ENTITY.SET_ENTITY_HEADING(prop, heading)
        OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(prop)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(prop)
    end)
end)

--object_spawner:add_button("Delete Object", function()
    --script.run_in_fiber(function()
        --if ENTITY.DOES_ENTITY_EXIST(prop) then
            --OBJECT.DELETE_OBJECT(prop)
        --end
    --end)
--end)