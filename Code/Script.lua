local orig_print = print
if Mods.mrudat_TestingMods then
  print = orig_print
else
  print = empty_func
end

local CurrentModId = rawget(_G, 'CurrentModId') or rawget(_G, 'CurrentModId_X')
local CurrentModDef = rawget(_G, 'CurrentModDef') or rawget(_G, 'CurrentModDef_X')
if not CurrentModId then

  -- copied shamelessly from Expanded Cheat Menu
  local Mods, rawset = Mods, rawset
  for id, mod in pairs(Mods) do
    rawset(mod.env, "CurrentModId_X", id)
    rawset(mod.env, "CurrentModDef_X", mod)
  end

  CurrentModId = CurrentModId_X
  CurrentModDef = CurrentModDef_X
end

orig_print("loading", CurrentModId, "-", CurrentModDef.title)

local function find_method(class_name, method_name)
  local class = _G[class_name]
  local method = class[method_name]
  if method then return method end
  for _, parent_class_name in ipairs(class.__parents) do
    method = find_method(parent_class_name, method_name)
    if method then return method end
  end
  return false
end

local function wrap_method(class_name, method_name, wrapper)
  local orig_method = find_method(class_name, method_name)
  _G[class_name][method_name] = function(self, ...)
    return wrapper(self, orig_method, ...)
  end
end

local function AddBuildingToTech(building_id, tech_id, hide_building)
  local requirements = BuildingTechRequirements[building_id] or {}
  BuildingTechRequirements[building_id] = requirements
  for _, requirement in ipairs(requirements) do
    if requirement.tech == tech_id then
      requirement.hide = hide_building
      return
    end
  end
  requirements[#requirements + 1] = { tech = tech_id, hide = hide_building }
end

AddBuildingToTech("Indoor_PolymerPlant", "LowGHydrosynthsis")

wrap_method('City', 'AddPrefabs', function(self, orig_method, building_id, amount, refresh)
  if building_id == 'PolymerPlant' then
    local available_prefabs = UICity.available_prefabs
    local PolymerPlant_prefabs = (available_prefabs['PolymerPlant'] or 0) + amount
    available_prefabs['Indoor_PolymerPlant'] = PolymerPlant_prefabs // 2
    orig_method(self, 'PolymerPlant', amount, refresh)
  elseif building_id == 'Indoor_PolymerPlant' then
    orig_method(self, 'PolymerPlant', amount * 2)
    orig_method(self, 'Indoor_PolymerPlant', amount, refresh)
  else
    orig_method(self, building_id, amount, refresh)
  end
end)

function OnMsg.LoadGame()
  local available_prefabs = UICity.available_prefabs
  available_prefabs['Indoor_PolymerPlant'] = (available_prefabs['PolymerPlant'] or 0) // 2
end

orig_print("loaded", CurrentModId, "-", CurrentModDef.title)
