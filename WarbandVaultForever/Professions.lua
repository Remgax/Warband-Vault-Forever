-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
Vault.Professions = {}
local P = Vault.Professions

local function Read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if ok then return a, b, c, d, e end
end

local function ItemID(link)
    return link and tonumber(link:match("item:(%d+)"))
end

local function Reagent(id, count, name, icon)
    if id and C_Item and C_Item.GetItemInfo then
        local cachedName, _, _, _, _, _, _, _, _, cachedIcon = C_Item.GetItemInfo(id)
        name, icon = name or cachedName, icon or cachedIcon
        if not cachedName and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    end
    return {id = id, name = name or (id and "Item " .. id or "Reagent not loaded"),
        count = count or 1, icon = icon or 134400}
end

function P.Skills()
    local character = Vault.Scanner.Identity()
    if not character or not GetProfessions or not GetProfessionInfo then return end
    local ok, a, b, c, d, e, f = pcall(GetProfessions)
    if not ok then return end
    local previous, found = character.professions or {}, {}
    for _, index in pairs({a, b, c, d, e, f}) do
        local good, name, icon, rank, maximum, _, _, id = pcall(GetProfessionInfo, index)
        if good and name then
            local skill = previous[name] or {name = name, recipes = {}}
            skill.id, skill.icon, skill.rank, skill.maximum = id, icon, rank, maximum
            found[name] = skill
        end
    end
    -- Login/skill events can arrive before all profession slots are populated.
    -- Missing slots are not evidence that a saved profession was unlearned.
    -- Keep recorded recipes; only update metadata for professions actually returned.
    for name,skill in pairs(found) do previous[name]=skill end
    character.professions=previous
end

local function Foreign()
    local api = C_TradeSkillUI or {}
    return Read(api.IsTradeSkillLinked) or Read(api.IsTradeSkillGuild)
        or Read(api.IsTradeSkillNPC) or Read(IsTradeSkillLinked)
end

local function Modern(character)
    local api = C_TradeSkillUI
    if not api or not api.GetAllRecipeIDs or not api.GetRecipeInfo then return false end
    local info = Read(api.GetBaseProfessionInfo)
    local ids = Read(api.GetAllRecipeIDs)
    if not info or not info.professionName or not ids or #ids == 0 then return false end
    local oldName = Read(GetTradeSkillLine)
    if oldName and oldName ~= "UNKNOWN" and oldName ~= info.professionName then return false end
    local previous = character.professions[info.professionName]
    local skill = previous or {name = info.professionName, recipes = {}}
    skill.id = info.professionID or skill.id
    skill.rank, skill.maximum = info.skillLevel or skill.rank, info.maxSkillLevel or skill.maximum
    local found, complete = {}, true
    for _, id in ipairs(ids) do
        local recipeInfo = Read(api.GetRecipeInfo, id)
        if not recipeInfo or recipeInfo.learned == nil then complete = false
        elseif recipeInfo.learned then
            local recipe = {id = id, name = recipeInfo.name or "Recipe " .. id,
                icon = recipeInfo.icon or 134400, reagents = {}}
            local schematic = Read(api.GetRecipeSchematic, id, false)
            if schematic and schematic.reagentSlotSchematics then
                recipe.outputID = schematic.outputItemID
                recipe.quantity = schematic.quantityMin or 1
                for _, slot in ipairs(schematic.reagentSlotSchematics) do
                    local basic = Enum.CraftingReagentType and Enum.CraftingReagentType.Basic or 1
                    if (slot.reagentType == nil or slot.reagentType == basic) and (slot.quantityRequired or 0) > 0 then
                        local choices = slot.reagents or {}
                        if #choices == 1 and choices[1].itemID then
                            recipe.reagents[#recipe.reagents + 1] = Reagent(choices[1].itemID, slot.quantityRequired)
                        else
                            local reagent = Reagent(nil, slot.quantityRequired, "Choose a reagent")
                            reagent.choices = {}
                            for _, choice in ipairs(choices) do
                                if choice.itemID then reagent.choices[#reagent.choices + 1] = Reagent(choice.itemID, slot.quantityRequired) end
                            end
                            recipe.reagents[#recipe.reagents + 1] = reagent
                            recipe.incomplete = true
                        end
                    end
                end
            else recipe.incomplete = true end
            recipe.link = Read(api.GetRecipeItemLink, id)
            if recipe.outputID and C_Item.GetItemInfo then
                local _, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(recipe.outputID)
                recipe.icon = icon or recipe.icon
            end
            local old = skill.recipes[id]
            found[id] = recipe.incomplete and old and not old.incomplete and old or recipe
        end
    end
    if complete then skill.recipes = found
    else for id, recipe in pairs(found) do skill.recipes[id] = recipe end end
    skill.updated, skill.partial = time(), not complete
    character.professions[skill.name] = skill
    return true
end

local function Legacy(character, craft)
    local name, rank, maximum
    if craft then name, rank, maximum = Read(GetCraftDisplaySkillLine)
    else name, rank, maximum = Read(GetTradeSkillLine) end
    if not name or name == "UNKNOWN" then return end
    local count = Read(craft and GetNumCrafts or GetNumTradeSkills)
    if not count then return end
    local skill = character.professions[name] or {name = name, recipes = {}}
    skill.rank, skill.maximum = rank or skill.rank, maximum or skill.maximum
    for i = 1, count do
        local recipeName, subName, kind
        if craft then recipeName, subName, kind = Read(GetCraftInfo, i)
        else recipeName, kind = Read(GetTradeSkillInfo, i) end
        if recipeName and kind and kind ~= "header" and kind ~= "subheader" then
            local recipeLink = Read(craft and GetCraftItemLink or GetTradeSkillRecipeLink, i)
            local id = recipeLink and tonumber(recipeLink:match("enchant:(%d+)") or recipeLink:match("spell:(%d+)"))
                or recipeName .. (subName or "")
            local recipe = {id = id, name = recipeName .. (subName and subName ~= "" and " (" .. subName .. ")" or ""),
                icon = Read(craft and GetCraftIcon or GetTradeSkillIcon, i) or 134400, reagents = {}, quantity = 1}
            recipe.link = Read(craft and GetCraftItemLink or GetTradeSkillItemLink, i)
            recipe.outputID = ItemID(recipe.link)
            local reagentCount = Read(craft and GetCraftNumReagents or GetTradeSkillNumReagents, i)
            if not reagentCount then recipe.incomplete = true end
            for reagentIndex = 1, reagentCount or 0 do
                local reagentName, icon, required = Read(craft and GetCraftReagentInfo or GetTradeSkillReagentInfo, i, reagentIndex)
                local link = Read(craft and GetCraftReagentItemLink or GetTradeSkillReagentItemLink, i, reagentIndex)
                local reagent = Reagent(ItemID(link), required, reagentName, icon)
                if not reagent.id or not required then recipe.incomplete = true end
                recipe.reagents[#recipe.reagents + 1] = reagent
            end
            local old = skill.recipes[id]
            skill.recipes[id] = recipe.incomplete and old and not old.incomplete and old or recipe
        end
    end
    -- Legacy filters/collapsed headers can hide recipes. Merge, never erase them.
    skill.updated, skill.partial = time(), true
    character.professions[name] = skill
end

function P.Scan()
    if not P.open or Foreign() then return end
    local character = Vault.Scanner.Identity()
    if not character then return end
    character.professions = character.professions or {}
    if P.craft then Legacy(character, true)
    elseif not Modern(character) then Legacy(character, false) end
end

function P.Available(result)
    if not result or result.character.key~=Vault.currentKey or not P.open or Foreign() then return 0 end
    local plan=Vault.Crafting.Plan(Vault.Crafting.Inventory(Vault.db,time()),result.character,result.recipe)
    if plan.incomplete then return 0 end
    local maximum=plan.noReagents and 1 or plan.bags
    local api=C_TradeSkillUI
    local base=api and Read(api.GetBaseProfessionInfo)
    if not P.craft and base and base.professionName==result.profession.name and type(result.recipe.id)=="number" and api.CraftRecipe then
        local info=Read(api.GetRecipeInfo,result.recipe.id)
        if not info or info.learned~=true then return 0 end
        local available=Read(api.GetCraftableCount,result.recipe.id)
        if type(available)=="number" then maximum=plan.noReagents and available or math.min(maximum,available) end
    else
        local name=Read(P.craft and GetCraftDisplaySkillLine or GetTradeSkillLine)
        if name~=result.profession.name then return 0 end
        if P.craft then maximum=math.min(maximum,1) end
    end
    return math.max(0,math.min(999,math.floor(maximum)))
end

function P.Craft(result, count)
    count=count or 1
    if type(count)~="number" or count~=math.floor(count) or count<1 or count>999 then return false,"Choose between 1 and 999 crafts." end
    if result.character.key~=Vault.currentKey then return false,"Log into "..result.character.name.." to craft this recipe." end
    if InCombatLockdown and InCombatLockdown() then return false,"Leave combat before crafting." end
    if not P.open or Foreign() then return false,"Open your "..result.profession.name.." profession window first." end
    Vault.Scanner.Refresh()
    local plan=Vault.Crafting.Plan(Vault.Crafting.Inventory(Vault.db,time()),result.character,Vault.Crafting.ScaleRecipe(result.recipe,count))
    if plan.incomplete then return false,"Finish loading this recipe in the profession window." end
    if plan.bags<1 and not plan.noReagents then return false,"Collect the materials shown in the shopping list." end
    local api=C_TradeSkillUI
    local base=api and Read(api.GetBaseProfessionInfo)
    if not P.craft and base and base.professionName==result.profession.name and type(result.recipe.id)=="number" and api.CraftRecipe then
        local recipe=Read(api.GetRecipeInfo,result.recipe.id)
        if not recipe or recipe.learned~=true then return false,"This recipe is not available in the open profession." end
        local available=Read(api.GetCraftableCount,result.recipe.id)
        if available and available<count then return false,"The game cannot craft that quantity. Check materials, tools and cooldowns." end
        local ok=pcall(api.CraftRecipe,result.recipe.id,count)
        return ok,ok and "Craft requested. Check the profession window for tools or cooldown requirements." or "WoW could not start this craft. Check the profession window."
    end
    local name=Read(P.craft and GetCraftDisplaySkillLine or GetTradeSkillLine)
    if name~=result.profession.name then return false,"Open your "..result.profession.name.." profession window first." end
    for i=1,Read(P.craft and GetNumCrafts or GetNumTradeSkills) or 0 do
        local recipeName,subName,kind=Read(P.craft and GetCraftInfo or GetTradeSkillInfo,i)
        local link=Read(P.craft and GetCraftItemLink or GetTradeSkillRecipeLink,i)
        local id=link and tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
        if recipeName and (id==result.recipe.id or type(result.recipe.id)=="string" and recipeName..(P.craft and subName or "" )==result.recipe.id) then
            local fn=P.craft and DoCraft or DoTradeSkill
            if type(fn)~="function" then break end
            if P.craft and count>1 then return false,"This profession creates one item at a time. Set the quantity to 1." end
            local ok=pcall(fn,i,count)
            return ok,ok and "Craft requested. Complete any target selection in the profession window." or "WoW could not start the craft."
        end
    end
    return false,"Find the recipe in your profession window, then try again."
end
