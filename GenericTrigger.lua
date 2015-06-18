--[[ GenericTrigger.lua
This file contains the generic trigger system. That is every trigger except the aura triggers

It registers the GenericTrigger table for the trigger types "status", "event" and "custom".
The GenericTrigger has the following API:

Modernize(data)
  Modernizes all generic triggers in data
]]
-- Lua APIs
local tinsert, tconcat, tremove, wipe = table.insert, table.concat, table.remove, wipe
local tostring, select, pairs, next, type, unpack = tostring, select, pairs, next, type, unpack
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable = setmetatable, getmetatable

local WeakAuras = WeakAuras;
local L = WeakAuras.L;
local GenericTrigger = {};

local event_prototypes = WeakAuras.event_prototypes;

local timer = WeakAuras.timer;
local debug = WeakAuras.debug;


function GenericTrigger.Modernize(data)
  -- Convert any references to "COMBAT_LOG_EVENT_UNFILTERED_CUSTOM" to "COMBAT_LOG_EVENT_UNFILTERED"
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end
    if(trigger and trigger.custom) then
      trigger.custom = trigger.custom:gsub("COMBAT_LOG_EVENT_UNFILTERED_CUSTOM", "COMBAT_LOG_EVENT_UNFILTERED");
    end
    if(untrigger and untrigger.custom) then
      untrigger.custom = untrigger.custom:gsub("COMBAT_LOG_EVENT_UNFILTERED_CUSTOM", "COMBAT_LOG_EVENT_UNFILTERED");
    end
  end

  -- Rename ["event"] = "Cooldown (Spell)" to ["event"] = "Cooldown Progress (Spell)"
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;

    if(triggernum == 0) then
      trigger = data.trigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
    end

    if trigger and trigger["event"] and trigger["event"] == "Cooldown (Spell)" then
      trigger["event"] = "Cooldown Progress (Spell)";
    end
  end

  -- Add status/event information to triggers
  for triggernum=0,(data.numTriggers or 9) do
    local trigger, untrigger;
    if(triggernum == 0) then
      trigger = data.trigger;
      untrigger = data.untrigger;
    elseif(data.additional_triggers and data.additional_triggers[triggernum]) then
      trigger = data.additional_triggers[triggernum].trigger;
      untrigger = data.additional_triggers[triggernum].untrigger;
    end
    -- Add status/event information to triggers
    if(trigger and trigger.event and (trigger.type == "status" or trigger.type == "event")) then
      local prototype = event_prototypes[trigger.event];
      if(prototype) then
        trigger.type = prototype.type;
      end
    end
    -- Convert ember trigger
    local fixEmberTrigger = function(trigger)
      if (trigger.power and not trigger.ember) then
        trigger.ember = tostring(tonumber(trigger.power) * 10);
        trigger.use_ember = trigger.use_power
        trigger.ember_operator = trigger.power_operator;
        trigger.power = nil;
        trigger.use_power = nil;
        trigger.power_operator = nil;
      end
    end

    if (trigger and trigger.type and trigger.event and trigger.type == "status" and trigger.event == "Burning Embers") then
      fixEmberTrigger(trigger);
      fixEmberTrigger(untrigger);
    end

    if (trigger and trigger.type and trigger.event and trigger.type == "status" and trigger.event == "Cooldown Progress (Spell)") then
        if (not trigger.showOn) then
            if (trigger.use_inverse) then
                trigger.showOn = "showOnReady"
            else
                trigger.showOn = "showOnCooldown"
            end
            trigger.use_inverse = nil
        end
    end
  end
end

WeakAuras.RegisterTriggerSystem({"event", "status", "custom"}, GenericTrigger);