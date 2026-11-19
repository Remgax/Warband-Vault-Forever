-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
local Data = {}; Vault.SyncData = Data
Data.limit = 750000

-- A bounded data-only format. Received text is never evaluated as Lua.
function Data.Encode(value, stable)
    local nodes, bytes = 0, 0
    local function encode(v, depth)
        nodes = nodes + 1
        assert(nodes <= 80000 and depth <= 12, "Record too large")
        local t, result = type(v)
        if t == "string" then result = "s" .. #v .. ":" .. v
        elseif t == "number" then assert(v == v and math.abs(v) < 1e15); result = "n" .. v .. ";"
        elseif t == "boolean" then result = v and "y" or "z"
        elseif t == "table" then
            local keys = {}
            for k in pairs(v) do
                assert(type(k) == "string" or type(k) == "number")
                if not stable or k ~= "updated" and k ~= "lastSeen" then keys[#keys + 1] = k end
            end
            table.sort(keys, function(a,b) return type(a) == type(b) and a < b or type(a) < type(b) end)
            local parts = {"t" .. #keys .. ":"}
            for _, k in ipairs(keys) do parts[#parts + 1] = encode(k, depth+1); parts[#parts + 1] = encode(v[k], depth+1) end
            return table.concat(parts)
        else error("Unsupported value") end
        bytes = bytes + #result; assert(bytes <= Data.limit, "Record too large")
        return result
    end
    local result = encode(value, 0); assert(#result <= Data.limit, "Record too large"); return result
end

function Data.Decode(text)
    assert(type(text) == "string" and #text <= Data.limit)
    local pos, nodes = 1, 0
    local function read(depth)
        nodes = nodes + 1; assert(nodes <= 80000 and depth <= 12)
        local tag = text:sub(pos,pos); pos = pos+1
        if tag == "y" then return true elseif tag == "z" then return false end
        if tag == "s" or tag == "t" then
            local stop = text:find(":",pos,true); assert(stop and stop-pos <= 7)
            local digits = text:sub(pos,stop-1); assert(digits:match("^%d+$"))
            local count = tonumber(digits); pos = stop+1
            if tag == "s" then
                assert(count <= 2048 and pos+count-1 <= #text)
                local result = text:sub(pos,pos+count-1); pos=pos+count; return result
            end
            assert(count <= 20000); local result = {}
            for _=1,count do
                local key = read(depth+1); assert(type(key)=="number" or type(key)=="string")
                assert(result[key] == nil); result[key] = read(depth+1)
            end
            return result
        elseif tag == "n" then
            local stop = text:find(";",pos,true); assert(stop and stop-pos <= 24)
            local n = tonumber(text:sub(pos,stop-1)); assert(n and n==n and math.abs(n)<1e15)
            pos=stop+1; return n
        end
        error("Invalid record")
    end
    local result = read(0); assert(pos == #text+1); return result
end

local function Str(v, fallback)
    if type(v) ~= "string" then return fallback end
    return v:sub(1,180):gsub("[|%c]", "")
end
local function Num(v, max)
    if type(v)=="number" and v==v and v>=0 and v<=max and v==math.floor(v) then return v end
end
local function Icon(value)
    if type(value)=="string" and #value<200 and value:lower():match("^interface[\\/]icons[\\/][%w_%-]+$") then return value end
    return Num(value,100000000) or 134400
end
local function Stamp(v) return Num(v, time()+300) end
local function Items(snapshot)
    assert(type(snapshot)=="table" and type(snapshot.items)=="table" and #snapshot.items<=5000)
    local result = {updated=assert(Stamp(snapshot.updated)), capacity=Num(snapshot.capacity,100000) or 0,items={}}
    for i,item in ipairs(snapshot.items) do
        assert(type(item)=="table")
        local id, count = assert(Num(item.id,10000000)), assert(Num(item.count,10000000))
        assert(id>0 and count>0)
        local bound = item.bound; if type(bound)~="boolean" then bound=nil end
        result.items[i] = {id=id,count=count, name=Str(item.name), link="item:"..id,
            icon=Icon(item.icon), quality=Num(item.quality,8) or 1,
            kind=Str(item.kind,""),bag=type(item.bag)=="number" and item.bag or 0,
            slot=Num(item.slot,100000) or i,bound=bound,
            expires=Stamp(item.expires),cod=item.cod==true or nil}
    end
    result.partial = snapshot.partial==true or nil; result.money=Num(snapshot.money,1e13)
    return result
end

function Data.Clean(c)
    assert(type(c)=="table" and type(c.key)=="string" and #c.key<100)
    assert(c.key:match("^%d+:Player%-%d+%-%x+$"), "Invalid character ID")
    local classes={WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,DEATHKNIGHT=true,
        SHAMAN=true,MAGE=true,WARLOCK=true,MONK=true,DRUID=true,DEMONHUNTER=true,EVOKER=true}
    assert(classes[c.class] and (c.faction=="Alliance" or c.faction=="Horde" or c.faction=="Neutral"))
    local result={key=c.key,guid=c.key:match("^[^:]+:(.+)$"),name=assert(Str(c.name)),realm=Str(c.realm),
        ruleset=Str(c.ruleset),
        class=c.class,className=Str(c.className,c.class),race=Str(c.race,"Human"),raceName=Str(c.raceName,""),
        sex=c.sex==3 and 3 or 2,level=assert(Num(c.level,1000)),faction=c.faction,
        money=Num(c.money,1e13) or 0,lastSeen=assert(Stamp(c.lastSeen)),snapshots={},professions={}}
    assert(result.race:match("^[%a]+$"))
    if result.ruleset == "" then result.ruleset = nil end
    for _, source in ipairs(Vault.Model.sources) do if c.snapshots and c.snapshots[source] then result.snapshots[source]=Items(c.snapshots[source]) end end
    local skillCount, recipeCount = 0,0
    for name, skill in pairs(c.professions or {}) do
        assert(type(name)=="string" and type(skill)=="table"); skillCount=skillCount+1; assert(skillCount<=20)
        name=Str(name); local clean={name=name,rank=Num(skill.rank,100000),maximum=Num(skill.maximum,100000),
            updated=Stamp(skill.updated),partial=skill.partial==true or nil,id=Num(skill.id,10000000),recipes={}}
        for id, recipe in pairs(skill.recipes or {}) do
            recipeCount=recipeCount+1; assert(recipeCount<=6000 and type(recipe)=="table")
            assert(type(id)=="number" or type(id)=="string")
            local r={id=id,name=Str(recipe.name,"Recipe"),icon=Icon(recipe.icon),
                quantity=Num(recipe.quantity,100000) or 1,outputID=Num(recipe.outputID,10000000),
                incomplete=recipe.incomplete==true or nil,reagents={}}
            if r.outputID then r.link="item:"..r.outputID end
            for i,reagent in ipairs(recipe.reagents or {}) do
                assert(i<=30 and type(reagent)=="table")
                r.reagents[i]={id=Num(reagent.id,10000000),count=Num(reagent.count,100000) or 1,
                    name=Str(reagent.name,"Reagent"),icon=Icon(reagent.icon)}
                if not r.reagents[i].id then r.incomplete=true end
            end
            clean.recipes[id]=r
        end
        result.professions[name]=clean
    end
    return result
end

function Data.Local(character)
    local result={}
    for _,key in ipairs({"key","name","ruleset","class","className","race","raceName","sex","level","faction","money","lastSeen","professions"}) do result[key]=character[key] end
    result.snapshots = {}
    for _,source in ipairs(Vault.Model.sources) do result.snapshots[source] = character.snapshots[source] end
    -- Retain the old wire field for older peers, but never interpret an old
    -- record's surname/realm as an authoritative ruleset on receipt.
    result.realm = character.ruleset or character.realm or ""
    return result
end

function Data.Merge(db, account, character)
    local c=Data.Clean(character); local old=db.characters[c.key]
    -- A linked account can update only its own imports, never local characters.
    if old and old.remoteAccount~=account then return false end
    if old then
        for source,snapshot in pairs(old.snapshots) do
            if not c.snapshots[source] or snapshot.updated>=c.snapshots[source].updated then c.snapshots[source]=snapshot end
        end
        for name,skill in pairs(old.professions or {}) do
            if not c.professions[name] or (skill.updated or 0)>=(c.professions[name].updated or 0) then c.professions[name]=skill end
        end
        if old.lastSeen>c.lastSeen then
            for _,field in ipairs({"name","realm","ruleset","class","className","race","raceName","sex","level","faction","money","lastSeen"}) do c[field]=old[field] end
        end
    end
    c.remoteAccount=account; db.characters[c.key]=c; return true
end
