-- Exercise complete addon initialization across separate character sessions.
local root = ...
local function session(saved, guid, first, last, copper, itemID)
    local env = setmetatable({}, {__index=_G})
    local frames, timers = {}, {}
    local state = {money=copper, capacity=16, item=itemID}
    env.WarbandVaultForeverDB = saved
    env.CreateFrame = function()
        local f = {}
        function f:RegisterEvent() end
        function f:SetScript(_, fn) self.handler=fn end
        frames[#frames+1]=f; return f
    end
    env.C_Timer = {After=function(_, fn) timers[#timers+1]=fn end, NewTicker=function() return {} end}
    env.C_ChatInfo = {RegisterAddonMessagePrefix=function() return true end, SendAddonMessage=function() end}
    env.DEFAULT_CHAT_FRAME = {AddMessage=function() end}
    env.SlashCmdList = {}
    env.strtrim = function(s) return s:match("^%s*(.-)%s*$") end
    env.time = function() return 1700000000 end
    env.GetTime = function() return 100 end
    env.UnitGUID = function() return guid end
    env.UnitFullName = function() return first, last end
    env.GetRealmName = function() return "CAMWOW EU4 Realm 2 PvP" end
    env.GetCurrentRegion = function() return 3 end
    env.UnitClass = function() return "Mage", "MAGE" end
    env.UnitRace = function() return "Human", "Human" end
    env.UnitSex = function() return 2 end
    env.UnitLevel = function() return 20 end
    env.UnitFactionGroup = function() return "Alliance" end
    env.GetRealZoneText = function() return "Stormwind" end
    env.GetMoney = function() return state.money end
    env.Enum = {BagIndex={}}
    env.C_Container = {
        GetContainerNumSlots=function(bag) return bag==0 and state.capacity or 0 end,
        GetContainerItemInfo=function(bag, slot)
            if bag==0 and slot==1 and state.item then
                return {itemID=state.item, stackCount=5, isBound=false}
            end
        end,
    }
    env.C_Item = {GetItemInfo=function(id) return "Item "..id, "item:"..id, 1 end}
    local function noop() end
    local v = {UI={Minimap=noop, ActionBar=noop, Refresh=noop, RecordsCleared=noop}}
    for _, file in ipairs({"Model", "Libs/SHA", "SyncData", "Sync", "Scanner", "Core"}) do
        setfenv(assert(loadfile(root.."/WarbandVaultForever/"..file..".lua")),env)("WarbandVaultForever",v)
    end
    local function event(name, ...) frames[1].handler(frames[1],name,...) end
    local function flush()
        while #timers>0 do
            local batch=timers; timers={}
            for _, fn in ipairs(batch) do fn() end
        end
    end
    event("ADDON_LOADED","WarbandVaultForever")
    event("PLAYER_LOGIN"); flush()
    assert(v.db==env.WarbandVaultForeverDB, "The saved global must reference the live database")
    return v, event, flush, state
end

local first, event, flush, state = session(nil,"Player-1-AA","Gareth","Ravenswood",12345,2447)
local firstKey=first.currentKey
assert(first.db.characters[firstKey].name=="Gareth Ravenswood")
first.db.characters[firstKey].professions={Alchemy={name="Alchemy",recipes={[1]={id=1,name="Potion",reagents={}}}}}
first.db.characters[firstKey].snapshots.bank={updated=1699999999,capacity=28,items={{id=2447,count=12}}}
event("BAG_UPDATE_DELAYED")
state.capacity=0; state.item=nil; state.money=0
event("PLAYER_LOGOUT"); flush()
assert(first.db.characters[firstKey].money==12345 and first.db.characters[firstKey].snapshots.bags.items[1].count==5,
    "Logout and pending scans must preserve the last live wallet and bags")

-- A data-only serialization boundary prevents shared Lua tables from masking
-- broken reinitialization, like the SavedVariables load on a new login.
local saved=first.SyncData.Decode(first.SyncData.Encode(first.db))
local second, event2, flush2 = session(saved,"Player-1-BB","Elena","Ashford",67890,765)
local secondKey=second.currentKey
assert(firstKey~=secondKey and second.db.characters[firstKey].snapshots.bank.items[1].count==12)
assert(second.db.characters[firstKey].professions.Alchemy.recipes[1].name=="Potion")
assert(second.db.characters[secondKey].name=="Elena Ashford")
local total,count=second.Model.Totals(second.db)
assert(total==80235 and count==2, "Both characters and their gold survive a fresh session")
assert(second.Model.SameRuleset(second.db.characters[firstKey],second.db.characters[secondKey]),
    "Different surnames share the authoritative server/ruleset label")
local wire=second.SyncData.Clean(second.SyncData.Local(second.db.characters[firstKey]))
assert(wire.name=="Gareth Ravenswood" and wire.ruleset=="CAMWOW EU4 Realm 2 PvP")
assert(#second.Model.Characters(second.db,"name",{query="ravenswood",ruleset=wire.ruleset})==1,
    "Full-name search and ruleset filters combine without mistaking surnames for rulesets")
local legacyGear={updated=1700000000,capacity=19,items={{id=999,count=1}}}
second.db.characters[firstKey].snapshots.equipment=legacyGear
assert(second.SyncData.Local(second.db.characters[firstKey]).snapshots.equipment==nil
    and second.db.characters[firstKey].snapshots.equipment==legacyGear,
    "Legacy equipment is excluded from new sync payloads without erasing the local cache")
local old=second.SyncData.Local(second.db.characters[firstKey]); old.ruleset=nil; old.realm="Ravenswood"
assert(second.SyncData.Clean(old).ruleset==nil, "Legacy surnames must never become rulesets")

event2("PLAYER_LOGOUT"); flush2()
local again=second.SyncData.Decode(second.SyncData.Encode(second.db))
again.characters[firstKey].name="Gareth"
again.characters[firstKey].realm="Ravenswood"
again.characters[firstKey].ruleset=nil
local third,event3,flush3=session(again,"Player-1-AA","Gareth","Ravenswood",12345,2447)
assert(third.db.characters[firstKey].name=="Gareth Ravenswood" and third.db.characters[firstKey].realm==nil
    and third.db.characters[firstKey].snapshots.bank.items[1].count==12,
    "A legacy identity upgrades in place without losing stored inventories")
assert(third.Model.Totals(third.db)==80235, "Returning to the first character retains the second wallet")
assert(third.db.characters[secondKey].snapshots.bags.items[1].id==765)

third.db.settings.scale=0.9; third.db.shoppingList={name="Old cached plan"}
third.Sync.config.key="private-fixture"; third.Sync.config.peerID="abcdefabcdef"
third.Sync.config.enabled=true
third.Sync.active={sender="peer"}; third.Sync.rx={parts={}}; third.Sync.tx={encoded="old"}
event3("PLAYER_ENTERING_WORLD"); event3("BAG_UPDATE_DELAYED")
third.ClearRecords(); flush3()
assert(next(third.db.characters)==nil and third.currentKey==nil and third.db.shoppingList==nil,
    "Clear removes all local and imported records and cancels both delayed login and queued scans")
assert(third.Sync.config.key=="private-fixture" and third.Sync.config.peerID=="abcdefabcdef" and not third.Sync.config.enabled)
assert(third.db.settings.scale==0.9 and not third.Sync.active and not third.Sync.rx and not third.Sync.tx,
    "Clearing preserves preferences and pairing, pauses sync and discards in-flight transfers")
third.Sync.Tick()
assert(next(third.db.characters)==nil, "Paused sync cannot repopulate cleared records")
event3("BAG_UPDATE_DELAYED"); flush3()
assert(third.db.characters[firstKey], "A new live event can deliberately record the current character again")
print("PASS: full-name identity, cross-session bags/gold/recipes, sync metadata and confirmed record clearing")
