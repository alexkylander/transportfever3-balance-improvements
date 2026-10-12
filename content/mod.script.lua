local HIGH_SPEED_TRACK = "::/infrastructure/track/high_speed/high_speed.street_template"
local HIGH_SPEED_CAT_TRACK = "::/infrastructure/track/high_speed/high_speed_catenary.street_template"
local STANDARD_TRACK = "::/infrastructure/track/standard/standard.street_template"
local STANDARD_CAT_TRACK = "::/infrastructure/track/standard/standard_catenary.street_template"
local STEEL_BRIDGE = "::/infrastructure/bridge/steel.bridge"
local CONCRETE_BRIDGE = "::/infrastructure/bridge/concrete.bridge"
local AVELIA_LIBERTY = "::/vehicle/train/avelia_liberty/avelia_liberty_front.mdl"
local SB_TARGET_YEAR = 1930
local HS_TARGET_YEAR = 1964
local SB_TARGET_SPEED = 160 / 3.6
local ST_SPEED_LIMIT = 200 / 3.6
local AVELIA_TARGET_SPEED = 300 / 3.6

local function patch(rep, name, ...)
  local id = rep.find(name)
  if id == -1 then
    print("balance_improvements: not found: " .. name)
    return
  end
  local t = rep.getAsTable(id)
  for _, fn in ipairs({...}) do
    fn(t)
  end
  rep.setAsTable(id, t)
end

local function setYear(t, year)
  t.availability = t.availability or {}
  t.availability.yearFrom = year
end

local function setSpeed(t, speed)
  t.speedLimit = speed
end

local function setTrackSpeed(t, speed)
  for _, lane in ipairs(t.laneConfigs or {}) do
    lane.speed = speed
  end
end

local function setVehicleSpeed(t, speed)
  local lv = t.metadata and t.metadata.landVehicle
  if lv and type(lv.topSpeed) == "number" then
    lv.topSpeed = speed
  else
    print("balance_improvements: avelia topSpeed not found, skipping")
  end
end

function data()
  return {
    postRunFn = function(configDict, allModParams)
      -- api reference points
      local streetRep = api.res.streetTemplateRep
      local bridgeRep = api.res.bridgeTypeRep
      local modelRep = api.res.modelRep
      
      -- High speed tracks now unlock in 1964 with the 0 Series Shinkansen
    patch(streetRep, HIGH_SPEED_TRACK, function(t) setYear(t, HS_TARGET_YEAR) end)
    patch(streetRep, HIGH_SPEED_CAT_TRACK, function(t) setYear(t, HS_TARGET_YEAR) end)

      -- Steel bridges unlock in 1930 with standard track and are set at 160 km/h
    patch(bridgeRep, STEEL_BRIDGE, function(t) setYear(t, SB_TARGET_YEAR) end, function(t) setSpeed(t, SB_TARGET_SPEED) end)

      -- Concrete bridges unlock in 1964 with the 0 Series Shinkansen
    patch(bridgeRep, CONCRETE_BRIDGE, function(t) setYear(t, HS_TARGET_YEAR) end)
    
      -- Standard track is now set at 200 km/h
    patch(streetRep, STANDARD_TRACK, function(t) setTrackSpeed(t, ST_SPEED_LIMIT) end)
    patch(streetRep, STANDARD_CAT_TRACK, function(t) setTrackSpeed(t, ST_SPEED_LIMIT) end)

      -- Avelia Liberty now runs at its intended operational speed of 300 km/h
    for _, car in ipairs({ "front", "middle1", "middle2", "middle3" }) do
      patch(modelRep,
        "::/vehicle/train/avelia_liberty/avelia_liberty_" .. car .. ".mdl",
        function(t) setVehicleSpeed(t, AVELIA_TARGET_SPEED) end)
        end
      end,
  }
end