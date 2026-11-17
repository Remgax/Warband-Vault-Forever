-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
Vault.Model = {}
local Model = Vault.Model
local sources = {"bags", "bank", "equipment", "mail"}
Model.sources = sources
Model.schema = 1

function Model.Open(db)
    db = db or {}
    if db.schema and db.schema > Model.schema then
        return nil, "Your saved data needs a newer version of Warband Vault Forever."
    end
    db.schema = Model.schema
    db.characters = db.characters or {}
    db.settings = db.settings or {scale = 1, minimap = true}
    return db
end

function Model.Character(db, key, details)
    local character = db.characters[key] or {key = key, snapshots = {}}
    db.characters[key] = character
    for field, value in pairs(details) do character[field] = value end
    return character
end

function Model.Save(character, source, items, capacity, timestamp)
    character.snapshots[source] = {
        items = items, capacity = capacity, updated = timestamp,
    }
end

function Model.Characters(db, sort)
    local result = {}
    for _, character in pairs(db.characters) do result[#result + 1] = character end
    table.sort(result, function(a, b)
        if sort == "gold" and (a.money or 0) ~= (b.money or 0) then
            return (a.money or 0) > (b.money or 0)
        end
        if a.name == b.name then return a.key < b.key end
        return (a.name or "") < (b.name or "")
    end)
    return result
end

function Model.Totals(db)
    local gold, characters, stacks = 0, 0, 0
    for _, character in pairs(db.characters) do
        gold = gold + (character.money or 0)
        characters = characters + 1
        for _, source in ipairs(sources) do
            local snapshot = character.snapshots[source]
            stacks = stacks + (snapshot and #snapshot.items or 0)
        end
    end
    return gold, characters, stacks
end

function Model.Find(db, key, source, query, quality)
    local results = {}
    query = (query or ""):lower()
    for _, character in pairs(db.characters) do
        if not key or key == character.key then
            for _, location in ipairs(sources) do
                if source == "all" or source == location then
                    local snapshot = character.snapshots[location]
                    for _, item in ipairs(snapshot and snapshot.items or {}) do
                        local text = ((item.name or "") .. " " .. (item.link or "") .. " " ..
                            tostring(item.id or "") .. " " .. (character.name or "") .. " " ..
                            (character.realm or "") .. " " .. (item.kind or "")):lower()
                        if text:find(query, 1, true) and (not quality or item.quality == quality) then
                            results[#results + 1] = {item = item, character = character,
                                source = location, updated = snapshot.updated}
                        end
                    end
                end
            end
        end
    end
    table.sort(results, function(a, b)
        if (a.item.quality or 0) ~= (b.item.quality or 0) then
            return (a.item.quality or 0) > (b.item.quality or 0)
        end
        if (a.item.name or "") ~= (b.item.name or "") then
            return (a.item.name or "") < (b.item.name or "")
        end
        if a.character.key ~= b.character.key then return a.character.key < b.character.key end
        if a.source ~= b.source then return a.source < b.source end
        if (a.item.bag or 0) ~= (b.item.bag or 0) then return (a.item.bag or 0) < (b.item.bag or 0) end
        return (a.item.slot or 0) < (b.item.slot or 0)
    end)
    return results
end

function Model.Owners(db, itemID)
    local owners = {}
    for _, character in ipairs(Model.Characters(db)) do
        local total = 0
        for _, source in ipairs(sources) do
            local snapshot = character.snapshots[source]
            for _, item in ipairs(snapshot and snapshot.items or {}) do
                if item.id == itemID then total = total + item.count end
            end
        end
        if total > 0 then owners[#owners + 1] = {character = character, count = total} end
    end
    return owners
end

function Model.Money(copper)
    copper = math.floor(copper or 0)
    return string.format("|cffffd36b%dg|r |cffc7cdd6%02ds|r |cffce926b%02dc|r",
        math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end

function Model.Age(timestamp, now)
    if not timestamp then return "Not recorded" end
    local age = math.max(0, now - timestamp)
    if age < 60 then return "Just now" end
    if age < 3600 then return math.floor(age / 60) .. "m ago" end
    if age < 86400 then return math.floor(age / 3600) .. "h ago" end
    return math.floor(age / 86400) .. "d ago"
end
