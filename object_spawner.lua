---@diagnostic disable: undefined-global, lowercase-global
object_spawner = gui.get_tab("Object Spawner")

local props = {
    { hash = 1524959858,	name = "Microphone"},
    { hash = 2473946431,	name = "TV Camera"},
    { hash = 1903501406,	name = "Barbeque 1"},
    { hash = 286252949,		name = "Barbeque 2"},
    { hash = 145818549,		name = "Work Light 1"},
    { hash = 2393739772,	name = "Work Light 2"},
    { hash = 1792816905,	name = "Kino Light (Photography)"},
    { hash = 2174673747,	name = "Studio Light (Photography)"},
    { hash = 2796614321,	name = "Patio Lounger"},
    { hash = 3186063286,	name = "Camping Chair"},
    { hash = 3121651431,	name = "Office Chair"},
    { hash = 2229511919,	name = "Armchair"},
    { hash = 1737474779,	name = "Wheelchair"},
    { hash = 468818960,		name = "Gazebo"},
    { hash = 1526269963,	name = "Michael's Sofa"},
    { hash = 3010776095,	name = "Michael's Bed"},
    { hash = 118627012,		name = "XMAS Tree (Outdoor)"},
    { hash = 238789712,		name = "XMAS Tree (Indoor)"},
    { hash = 3640564381,	name = "Snacks Vending Machine"},
    { hash = 690372739,		name = "Coffee Vending Machine"},
    { hash = 4111834409,	name = "Start/Finish Gate (Racing)"},
    { hash = 2544207977,	name = "Inflate Arch (Racing)"},
    { hash = 2156563864,	name = "Race Start/Finish Platform"},
    { hash = 812376260,		name = "Tire Stack"},
    { hash = 3760607069,	name = "Road Cone"},
    { hash = 528555233,		name = "Drug Package 1"},
    { hash = 525896218,		name = "Drug Package 2"},
    { hash = 1049338225,	name = "Drug Suitase"},
    { hash = 1452661060, 	name = "Money Suitcase"},
    { hash = 4186550941, 	name = "Cash Trolley"},
    { hash = 1910485680, 	name = "Gold Trolley"},
    { hash = 3695421292, 	name = "Gold Bar"},
    { hash = 3015194288, 	name = "Oak Tree"},
    { hash = 4139096503, 	name = "Olive Tree"},
    { hash = 3446302258, 	name = "Joshua Tree"},
    { hash = 3802829770, 	name = "Cactus"},
    { hash = 11906616, 		name = "Large Bush (You can use it to hide)"},
    { hash = 2475986526, 	name = "Small Ramp"},
    { hash = 1842594658, 	name = "HUGE Loop Ramp (It's very big!)"},
    { hash = 1768956181, 	name = "HUGER Loop Ramp (It's even bigger!)"},
    { hash = 1083683517, 	name = "Jetski Trailer"},
    { hash = 3229200997, 	name = "Beach fire"},
    { hash = 3246457862, 	name = "Rose"},
    { hash = 2088900873, 	name = "Stripper Pole"},
    { hash = 3962399788, 	name = "NSFW Ragdoll"}
}
local prop_index = 1
local h_offset = 0
local default_h_offset = 0
local spawnDistance = { x = 0, y = 0, z = -1 }
local defaultSpawnDistance = { x = 0, y = 0, z = -1 }
local function resetSliders()
    spawnDistance.x = defaultSpawnDistance.x
    spawnDistance.y = defaultSpawnDistance.y
    spawnDistance.z = defaultSpawnDistance.z
    h_offset = default_h_offset
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
    ImGui.PushItemWidth(400)
end
object_spawner:add_imgui(displayFilteredList)

object_spawner:add_separator()

object_spawner:add_text("Adjust Distance or Keep Default :")

object_spawner:add_imgui(function()
    spawnDistance.x, _ = ImGui.SliderFloat("X Axis", spawnDistance.x, -10, 10)
    spawnDistance.y, _ = ImGui.SliderFloat("Y Axis", spawnDistance.y, -10, 10)
    spawnDistance.z, _ = ImGui.SliderFloat("Z Axis", spawnDistance.z, -10, 10)
end)

object_spawner:add_separator()

object_spawner:add_text("Adjust Direction or Keep Default :")

object_spawner:add_imgui(function()
h_offset, _ = ImGui.SliderFloat("Heading Offset", h_offset, 0, 360)
end)

defaultSpawnDistance.x = spawnDistance.x
defaultSpawnDistance.y = spawnDistance.y
defaultSpawnDistance.z = spawnDistance.z
default_h_offset = h_offset

object_spawner:add_button("Reset Sliders", function()
    resetSliders()
end)

object_spawner:add_separator()

object_spawner:add_imgui(function()
local ped = PLAYER.GET_PLAYER_PED(network.get_selected_player())
local player_name = PLAYER.GET_PLAYER_NAME(network.get_selected_player())
local coords = ENTITY.GET_ENTITY_COORDS(ped, false)
coords.x = coords.x + spawnDistance.x
coords.y = coords.y + spawnDistance.y
coords.z = coords.z + spawnDistance.z
local heading = ENTITY.GET_ENTITY_HEADING(ped)
heading = heading + h_offset
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
            local prop = OBJECT.CREATE_OBJECT(object.hash, coords.x + (forwardX * 1), coords.y + (forwardY * 1), coords.z, true, false, false)
            ENTITY.SET_ENTITY_HEADING(prop, heading)
            OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(prop)
            local netID = NETWORK.OBJ_TO_NET(prop)
            NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID, true)
                if ENTITY.DOES_ENTITY_EXIST(prop) then
                    gui.show_message("Object Spawner", "Spawned '"..object.name.."' in front of ["..player_name.."].")
                else
                    gui.show_message("Object Spawner", "ERORR! '"..object.name.."' failed to load.")
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
                gui.show_message("Object Spawner", "There is no ''"..object.name.."'' nearby!")
            end
        end)
    end
end)
