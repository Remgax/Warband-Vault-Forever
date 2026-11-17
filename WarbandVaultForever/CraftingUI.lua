-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
Vault.CraftingUI = {}
local View, UI, Crafting, Model = Vault.CraftingUI, Vault.UI, Vault.Crafting, Vault.Model
local W, C = UI.widgets, UI.widgets.colors

local function Key(result)
    return result.character.key .. ":" .. result.profession.name .. ":" .. tostring(result.recipe.id)
end

local function Professions()
    local found, options = {}, {{text = "All professions", value = false}}
    for _, character in ipairs(Model.Characters(Vault.db)) do
        if (not UI.selected or character.key == UI.selected) and (not UI.visibleKeys or UI.visibleKeys[character.key]) then
            for name in pairs(character.professions or {}) do found[name] = true end
        end
    end
    for name in pairs(found) do options[#options + 1] = {text = name, value = name} end
    table.sort(options, function(a, b)
        if a.value == false then return true elseif b.value == false then return false end
        return a.text < b.text
    end)
    return options, found
end

function View.Create()
    local frame = CreateFrame("Frame", nil, UI.main)
    frame:SetPoint("TOPLEFT", 14, -169); frame:SetSize(719, 309)
    UI.crafting = frame
    local left = W.Panel(frame, 258, 309)
    left:SetPoint("TOPLEFT")
    W.Text(left, "Recipes", 14, C.gold):SetPoint("TOPLEFT", 12, -10)
    View.recipeScroll, View.recipeChild = W.Scroll(left, 9, -32, 221, 261)
    View.recipeButtons = {}
    View.recipeEmpty = W.Text(View.recipeChild, "", 12, C.text, 211)
    View.recipeEmpty:SetPoint("TOPLEFT", 4, -14)
    View.detailScroll, View.detailChild = W.Scroll(frame, 277, -3, 415, 253)
    View.title = W.Text(View.detailChild, "", 17, C.gold, 396)
    View.title:SetPoint("TOPLEFT", 1, -6)
    View.owner = W.Text(View.detailChild, "", 11, C.muted, 396)
    View.owner:SetPoint("TOPLEFT", 1, -32)
    View.status = W.Text(View.detailChild, "", 12, C.text, 396)
    View.status:SetPoint("TOPLEFT", 1, -54)
    View.estimate = W.Text(View.detailChild, "", 11, C.muted, 396)
    View.estimate:SetPoint("TOPLEFT", 1, -100)
    View.craftButton=W.Button(frame,"Craft 1",89,28,function()
        if not View.currentResult then return end
        Vault.Scanner.Refresh()
        local plan=Crafting.Plan(Crafting.Inventory(Vault.db,time()),View.currentResult.character,View.currentResult.recipe)
        if plan.bags<1 and not plan.noReagents then
            Vault.Shopping.Open(View.currentResult)
            local list=Vault.Shopping.Build(View.currentResult)
            if list.buyLines>0 then
                local _,message=Vault.Shopping.Export(list); Vault.Shopping.message:SetText(message)
            end
            return
        end
        local _,message=Vault.Professions.Craft(View.currentResult); View.status:SetText(message)
    end)
    View.craftButton:SetPoint("TOPLEFT",277,-278)
    View.materialButton=W.Button(frame,"Materials",120,28,function() if View.currentResult then Vault.Shopping.Open(View.currentResult) end end)
    View.materialButton:SetPoint("TOPLEFT",374,-278)
    View.auctionButton=W.Button(frame,"AH shopping list",165,28,function()
        if not View.currentResult then return end
        Vault.Shopping.Open(View.currentResult)
        local _,message=Vault.Shopping.Export(Vault.Shopping.Build(View.currentResult)); Vault.Shopping.message:SetText(message)
    end)
    View.auctionButton:SetPoint("TOPLEFT",502,-278)
    View.materialRows = {}
    UI.professionButton = W.Button(UI.main, "All professions", 172, 31, function(self)
        UI.FilterMenu(self, Professions(), function(value)
            UI.craftProfession = value or nil; View.recipeScroll:SetVerticalScroll(0); UI.RefreshItems()
        end)
    end)
    UI.professionButton:SetPoint("TOPRIGHT", -14, -124)
    View.recipeScroll:HookScript("OnVerticalScroll", function() View.RenderRecipes() end)
    frame:Hide(); UI.professionButton:Hide()
end

function View.RenderRecipes()
    for _, button in ipairs(View.recipeButtons) do button:Hide() end
    local first = math.floor(View.recipeScroll:GetVerticalScroll() / 44) + 1
    for i = first, math.min(#(View.results or {}), first + 8) do
        local result = View.results[i]
        local pool = i - first + 1
        local button = View.recipeButtons[pool]
        if not button then
            button = W.Button(View.recipeChild, "", 220, 41, function(self)
                View.selected = Key(self.result); View.detailScroll:SetVerticalScroll(0)
                View.RenderRecipes(); View.Details(self.result)
            end)
            button.name = W.Text(button, "", 12, C.text, 204)
            button.name:SetPoint("TOPLEFT", 7, -6)
            button.owner = W.Text(button, "", 10, C.muted, 204)
            button.owner:SetPoint("TOPLEFT", 7, -24)
            View.recipeButtons[pool] = button
        end
        button.result = result
        button:SetPoint("TOPLEFT", 0, -(i - 1) * 44)
        button.name:SetText(result.recipe.name)
        button.owner:SetText(result.character.name .. " / " .. result.profession.name)
        button:SetBackdropBorderColor(unpack(Key(result) == View.selected and C.gold or {0.4, 0.29, 0.17}))
        button:Show()
    end
end

function View.Details(result)
    View.currentResult=result
    View.craftButton:SetShown(result~=nil); View.materialButton:SetShown(result~=nil); View.auctionButton:SetShown(result~=nil)
    for _, row in ipairs(View.materialRows) do row:Hide() end
    if not result then
        View.title:SetText("Choose a recipe")
        View.owner:SetText("")
        View.status:SetText("Open each profession to save its recipes.")
        View.estimate:SetText("")
        View.detailChild:SetHeight(303)
        return
    end
    local recipe, character = result.recipe, result.character
    local plan = Crafting.Plan(View.inventory, character, recipe)
    View.title:SetText(recipe.name)
    View.owner:SetText(character.name .. " / " .. result.profession.name .. " " ..
        (result.profession.rank or "?") .. "/" .. (result.profession.maximum or "?"))
    local status
    if plan.incomplete then status = "Open this profession to finish loading the recipe."
    elseif plan.noReagents then status = "No materials required."
    elseif plan.bags > 0 then status = "Enough in bags for " .. plan.bags .. " crafts."
    elseif plan.personal > 0 then status = "Enough in bags and bank for " .. plan.personal .. " crafts."
    elseif plan.account > 0 then status = "Missing here. Materials are on alts or in mail."
    else status = "Materials missing." end
    if plan.uncertain then status = status .. " Update older alts to check item binding." end
    View.status:SetText(status)
    View.estimate:SetText(Vault.Shopping.Estimate(Vault.Shopping.Build(result)))
    local y = 148
    for i, requirement in ipairs(plan.requirements) do
        local row = View.materialRows[i]
        if not row then
            row = CreateFrame("Frame", nil, View.detailChild)
            row:SetWidth(400)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(26, 26); row.icon:SetPoint("TOPLEFT", 0, -1)
            row.name = W.Text(row, "", 12, C.gold, 365); row.name:SetPoint("TOPLEFT", 34, 0)
            row.counts = W.Text(row, "", 11, C.text, 365); row.counts:SetPoint("TOPLEFT", 34, -19)
            row.owners = W.Text(row, "", 11, C.muted, 392); row.owners:SetPoint("TOPLEFT", 2, -40)
            View.materialRows[i] = row
        end
        row:SetPoint("TOPLEFT", 0, -y)
        row.icon:SetTexture(requirement.icon or 134400)
        local reagentName = requirement.name
        if requirement.id and (not reagentName or reagentName:match("^Item %d+$")) and C_Item.GetItemInfo then
            local name = C_Item.GetItemInfo(requirement.id)
            reagentName = name or reagentName
        end
        row.name:SetText((reagentName or "Reagent") .. " / " .. requirement.required .. " required")
        row.counts:SetText(requirement.unresolved and "Choose reagents in the profession window." or
            "Bags " .. requirement.bags .. " + Bank " .. requirement.bank .. " / Missing " .. requirement.missing)
        local lines = {}
        for _, owner in ipairs(requirement.owners) do
            local record, parts = owner.record, {}
            for _, location in ipairs({"bags", "bank", "mail"}) do
                if record[location] > 0 then
                    local label = location == "bags" and "Bags" or location == "bank" and "Bank" or "Mail"
                    parts[#parts + 1] = label .. " " .. record[location] .. " (" .. Model.Age(record.updated[location], time()) .. ")"
                end
            end
            local limits = owner.otherRealm and " [other realm]" or owner.otherFaction and " [other faction]" or
                record.bound > 0 and " [" .. record.bound .. " bound]" or ""
            lines[#lines + 1] = record.character.name .. ": " .. table.concat(parts, ", ") .. limits
        end
        if requirement.choices then
            for _, choice in ipairs(requirement.choices) do lines[#lines + 1] = choice.name end
        end
        if #lines == 0 then lines[1] = "None in saved bags, banks, or mail." end
        row.owners:SetText(table.concat(lines, "\n"))
        local height = 49 + #lines * 16
        row:SetHeight(height); row:Show(); y = y + height + 10
    end
    View.detailChild:SetHeight(math.max(303, y + 5))
end

function View.Refresh()
    local _, available = Professions()
    if UI.craftProfession and not available[UI.craftProfession] then UI.craftProfession = nil end
    UI.professionButton.label:SetText(UI.craftProfession or "All professions")
    View.results = Crafting.Recipes(Vault.db, UI.selected, UI.craftProfession, UI.query, UI.visibleKeys)
    View.inventory = Crafting.Inventory(Vault.db, time(), Vault.db.settings.includeMail ~= false)
    local selected
    for _, result in ipairs(View.results) do if Key(result) == View.selected then selected = result end end
    selected = selected or View.results[1]
    View.selected = selected and Key(selected) or nil
    View.recipeChild:SetHeight(math.max(261, #View.results * 44))
    View.recipeScroll:SetVerticalScroll(math.min(View.recipeScroll:GetVerticalScroll(), math.max(0, View.recipeChild:GetHeight() - 261)))
    View.recipeEmpty:SetShown(#View.results == 0)
    local skills = {}
    for name in pairs(available) do skills[#skills + 1] = name end
    table.sort(skills)
    View.recipeEmpty:SetText(#skills > 0 and table.concat(skills, "\n") .. "\n\nOpen a profession to save its recipes." or
        "No professions saved.\nLog into this character to record them.")
    if UI.query ~= "" and #View.results == 0 then View.recipeEmpty:SetText("No recipes match your search.") end
    View.RenderRecipes(); View.Details(selected)
    UI.freshness:SetText(selected and ("Recipes saved: " .. Model.Age(selected.profession.updated, time()) ..
        (selected.profession.partial and " / Expand categories and clear profession filters to record more." or "")) or
        "Open each character's professions once to save their recipes.")
    UI.resultCount:SetText(#View.results .. " recipes / Materials for one craft. Tools and cooldowns still apply.")
end
