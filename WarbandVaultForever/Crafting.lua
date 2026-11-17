-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
Vault.Crafting = {}
local Crafting = Vault.Crafting

function Crafting.Recipes(db, key, profession, query, allowed)
    local results = {}
    query = (query or ""):lower()
    for _, character in ipairs(Vault.Model.Characters(db)) do
        if (not key or character.key == key) and (not allowed or allowed[character.key]) then
            for name, skill in pairs(character.professions or {}) do
                if not profession or name == profession then
                    for _, recipe in pairs(skill.recipes or {}) do
                        local text = ((recipe.name or "") .. " " .. name .. " " .. character.name):lower()
                        if text:find(query, 1, true) then
                            results[#results + 1] = {character = character, profession = skill, recipe = recipe}
                        end
                    end
                end
            end
        end
    end
    table.sort(results, function(a, b)
        if a.profession.name ~= b.profession.name then return a.profession.name < b.profession.name end
        if a.recipe.name ~= b.recipe.name then return a.recipe.name < b.recipe.name end
        return a.character.key < b.character.key
    end)
    return results
end

function Crafting.Inventory(db, now, includeMail)
    local index = {}
    for _, character in ipairs(Vault.Model.Characters(db)) do
        for _, location in ipairs({"bags", "bank", "mail"}) do
            local snapshot = character.snapshots[location]
            for _, item in ipairs(snapshot and snapshot.items or {}) do
                if (location ~= "mail" or includeMail ~= false) and not item.cod and (not item.expires or item.expires > now) then
                    index[item.id] = index[item.id] or {}
                    local owners = index[item.id]
                    local owner = owners[character.key] or {character = character, bags = 0, bank = 0, mail = 0,
                        transferable = 0, bound = 0, unknown = 0, updated = {}}
                    owners[character.key] = owner
                    owner[location] = owner[location] + item.count
                    owner.updated[location] = snapshot.updated
                    if item.bound then owner.bound = owner.bound + item.count
                    else owner.transferable = owner.transferable + item.count end
                    if item.bound == nil and location ~= "mail" then owner.unknown = owner.unknown + item.count end
                end
            end
        end
    end
    return index
end

local function SameMailRoute(a, b)
    return a.realm == b.realm and a.faction == b.faction
        and a.key:match("^([^:]+)") == b.key:match("^([^:]+)")
end

function Crafting.Plan(index, character, recipe)
    local plan = {requirements = {}, bags = math.huge, personal = math.huge, account = math.huge,
        incomplete = recipe.incomplete or false, uncertain = false}
    local demands = {}
    for _, reagent in ipairs(recipe.reagents or {}) do
        if reagent.id then
            local demand = demands[reagent.id]
            if demand then demand.required = demand.required + reagent.count
            else
                demand = {id = reagent.id, name = reagent.name, icon = reagent.icon, required = reagent.count, owners = {}}
                demands[reagent.id] = demand
                plan.requirements[#plan.requirements + 1] = demand
            end
        else
            plan.incomplete = true
            plan.requirements[#plan.requirements + 1] = {name = reagent.name or "Reagent choice",
                required = reagent.count, choices = reagent.choices, owners = {}, unresolved = true}
        end
    end
    for _, demand in ipairs(plan.requirements) do
        local bags, bank, total, mail = 0, 0, 0, 0
        local owners = index[demand.id] or {}
        for _, owner in pairs(owners) do
            local own = owner.character.key == character.key
            local route = own or SameMailRoute(owner.character, character)
            local available = own and (owner.bags + owner.bank + owner.mail) or route and owner.transferable or 0
            demand.owners[#demand.owners + 1] = {record = owner, available = available,
                otherRealm = owner.character.realm ~= character.realm,
                otherFaction = owner.character.faction ~= character.faction}
            total = total + available
            if route and not own and owner.unknown > 0 then plan.uncertain = true end
            if own then bags, bank, mail = owner.bags, owner.bank, owner.mail end
        end
        table.sort(demand.owners, function(a, b)
            if a.available ~= b.available then return a.available > b.available end
            return a.record.character.name < b.record.character.name
        end)
        demand.bags, demand.bank, demand.mail, demand.total = bags, bank, mail, total
        demand.missing = math.max(0, demand.required - bags - bank)
        demand.accountMissing = math.max(0, demand.required - total)
        if not demand.unresolved and demand.required > 0 then
            plan.bags = math.min(plan.bags, math.floor(bags / demand.required))
            plan.personal = math.min(plan.personal, math.floor((bags + bank) / demand.required))
            plan.account = math.min(plan.account, math.floor(total / demand.required))
        end
    end
    if plan.bags == math.huge then plan.bags, plan.personal, plan.account = 0, 0, 0 end
    plan.noReagents = #plan.requirements == 0 and not plan.incomplete
    return plan
end
