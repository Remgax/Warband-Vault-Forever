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
        if (not View.character or character.key == View.character) then
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

function View.Create(parent)
    if View.frame then return end
    local frame = W.Panel(parent, 820, 480)
    frame:SetPoint("TOPLEFT", 15, -68)
    View.frame = frame
    frame:SetFrameLevel(parent:GetFrameLevel()+100)
    frame:EnableMouse(true)
    local header=W.Text(frame,"Warband recipes",16,C.gold)
    header:SetPoint("TOPLEFT",12,-12)
    View.characterButton=W.Button(frame,"All characters",185,27,function(self)
        local options={{text="All characters",value=false}}
        for _,character in ipairs(Model.Characters(Vault.db)) do
            options[#options+1]={text=character.name.." / "..Vault.Model.Ruleset(character),value=character.key}
        end
        UI.FilterMenu(self,options,function(value) View.character=value or nil; View.selected=nil; View.Refresh() end)
    end)
    View.characterButton:SetPoint("TOPLEFT",12,-40)
    local search=W.Panel(frame,260,27); search:SetPoint("TOPLEFT",207,-40)
    View.search=CreateFrame("EditBox",nil,search,"InputBoxTemplate")
    View.search:SetPoint("TOPLEFT",8,-2); View.search:SetSize(245,23); View.search:SetAutoFocus(false)
    View.search:SetText(Vault.db.settings.recipeSearch or "")
    View.searchHint=W.Text(search,"Search recipes",11,C.muted,235); View.searchHint:SetPoint("LEFT",10,0)
    View.searchHint:SetShown(View.search:GetText()=="")
    View.search:SetScript("OnTextChanged",function(self) View.searchHint:SetShown(self:GetText()==""); View.query=self:GetText(); Vault.db.settings.recipeSearch=View.query; View.Refresh() end)
    View.search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    View.query=Vault.db.settings.recipeSearch or ""
    View.availableOnly=Vault.db.settings.recipeAvailableOnly==true
    View.availableButton=W.Button(frame,"",140,27,function()
        View.availableOnly=not View.availableOnly; Vault.db.settings.recipeAvailableOnly=View.availableOnly; View.Refresh()
    end)
    View.availableButton:SetPoint("TOPLEFT",12,-76)
    View.nativeButton=W.Button(frame,"Native recipes",140,27,function() Vault.ProfessionWindow.ShowNative() end)
    View.nativeButton:SetPoint("TOPRIGHT",-12,-76)
    local body=CreateFrame("Frame",nil,frame); body:SetPoint("TOPLEFT",12,-112); body:SetSize(719,309)
    frame=body
    local left = W.Panel(frame, 258, 309)
    left:SetPoint("TOPLEFT")
    W.Text(left, "Recipes", 14, C.gold):SetPoint("TOPLEFT", 12, -10)
    View.recipeScroll, View.recipeChild = W.Scroll(left, 9, -32, 221, 261)
    View.recipeButtons = {}
    View.recipeEmpty = W.Text(View.recipeChild, "", 12, C.text, 211)
    View.recipeEmpty:SetPoint("TOPLEFT", 4, -14)
    View.detailScroll, View.detailChild = W.Scroll(frame, 277, -3, 415, 253)
    View.output = W.Panel(View.detailChild,42,42)
    View.output:SetPoint("TOPLEFT",0,-3); View.output:EnableMouse(true)
    View.outputIcon=View.output:CreateTexture(nil,"ARTWORK")
    View.outputIcon:SetPoint("TOPLEFT",4,-4); View.outputIcon:SetPoint("BOTTOMRIGHT",-4,4)
    View.outputIcon:SetTexCoord(0.06,0.94,0.06,0.94)
    View.output:SetScript("OnEnter",function(self)
        local result=View.currentResult
        if not result then return end
        local recipe=result.recipe
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if recipe.outputID then GameTooltip:SetItemByID(recipe.outputID)
        elseif recipe.link then GameTooltip:SetHyperlink(recipe.link)
        else GameTooltip:AddLine(recipe.name,unpack(C.gold)) end
        GameTooltip:Show()
    end)
    View.output:SetScript("OnLeave",function() GameTooltip:Hide() end)
    View.title = W.Text(View.detailChild, "", 17, C.gold, 347)
    View.title:SetPoint("TOPLEFT", 49, -6)
    View.title:SetWordWrap(false)
    View.owner = W.Text(View.detailChild, "", 11, C.muted, 347)
    View.owner:SetPoint("TOPLEFT", 49, -32)
    View.status = W.Text(View.detailChild, "", 12, C.text, 396)
    View.status:SetPoint("TOPLEFT", 1, -54)
    View.estimate = W.Text(View.detailChild, "", 11, C.muted, 290)
    View.estimate:SetPoint("TOPLEFT", 1, -74)
    local function NativeButton(label,width,x,action)
        local button=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        button:SetSize(width,26); button:SetPoint("TOPLEFT",x,-278)
        button:SetText(label); button:SetScript("OnClick",action); return button
    end
    View.decrease=NativeButton("",22,421,function() View.SetQuantity(View.Quantity()-1) end)
    View.decrease:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    View.decrease:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    View.decrease:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    View.quantity=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
    View.quantity:SetSize(42,22); View.quantity:SetPoint("TOPLEFT",452,-280)
    View.quantity:SetAutoFocus(false); View.quantity:SetNumeric(true); View.quantity:SetMaxLetters(3)
    View.quantity:SetJustifyH("CENTER")
    View.quantity:SetScript("OnTextChanged",function() View.QuantityChanged() end)
    View.quantity:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    View.quantity:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    View.increase=NativeButton("",22,501,function() View.SetQuantity(View.Quantity()+1) end)
    View.increase:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    View.increase:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    View.increase:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    View.craftButton=NativeButton("Show recipe",110,587,function() View.ShowNative() end)
    W.Text(frame,"Plan quantity",11,C.muted):SetPoint("TOPLEFT",277,-285)
    View.materialButton=W.Button(View.detailChild,"Materials",90,25,function()
        if View.currentResult then Vault.Shopping.Open(View.currentResult,math.max(1,View.Quantity())) end
    end)
    View.materialButton:SetPoint("TOPRIGHT",-14,-69)
    View.materialRows = {}
    View.professionButton = W.Button(View.frame, "All professions", 172, 31, function(self)
        UI.FilterMenu(self, Professions(), function(value)
            View.profession = value or nil; Vault.db.settings.recipeProfession=View.profession; View.recipeScroll:SetVerticalScroll(0); View.Refresh()
        end)
    end)
    View.professionButton:SetPoint("TOPLEFT", 477, -40)
    View.recipeScroll:HookScript("OnVerticalScroll", function() View.RenderRecipes() end)
    View.freshness=W.Text(View.frame,"",11,C.muted,790); View.freshness:SetPoint("TOPLEFT",12,-435)
    View.resultCount=W.Text(View.frame,"",11,C.muted,790); View.resultCount:SetPoint("TOPLEFT",12,-456)
    View.profession=Vault.db.settings.recipeProfession
    View.frame:Hide()
end

function View.Quantity() return math.max(1,math.min(999,math.floor(tonumber(View.quantity:GetText()) or 1))) end
function View.UpdateControls()
    local count=View.Quantity()
    View.craftButton:SetEnabled(View.currentResult~=nil and View.currentResult.character.key==Vault.currentKey and count>0)
    View.decrease:SetEnabled(count>1); View.increase:SetEnabled(count<999)
    if View.currentResult then View.estimate:SetText(Vault.Shopping.Estimate(Vault.Shopping.Build(View.currentResult,math.max(1,count)),true)) end
end
function View.SetQuantity(count)
    View.syncingQuantity=true
    View.quantity:SetText(tostring(math.max(1,math.min(999,count))))
    View.syncingQuantity=false; View.QuantityChanged()
end
function View.QuantityChanged()
    if View.syncingDetails or View.syncingQuantity then return end
    if View.currentResult then View.Details(View.currentResult) else View.UpdateControls() end
end
function View.ShowNative()
    local result=View.currentResult
    if not result or result.character.key~=Vault.currentKey then return end
    if InCombatLockdown and InCombatLockdown() then View.status:SetText("Leave combat before selecting a recipe."); return end
    local api=C_TradeSkillUI
    local info=api and api.GetBaseProfessionInfo and api.GetBaseProfessionInfo()
    if not Vault.Professions.open or not info or info.professionName~=result.profession.name then
        View.status:SetText("Open "..result.profession.name.." from your spellbook first."); return
    end
    local page=ProfessionsFrame and ProfessionsFrame.CraftingPage
    local recipeInfo=api.GetRecipeInfo and api.GetRecipeInfo(tonumber(result.recipe.id))
    if not page or not page.SelectRecipe or not recipeInfo or not recipeInfo.learned then
        View.status:SetText("Find this recipe in the native profession list first."); return
    end
    Vault.ProfessionWindow.ShowNative()
    page:SelectRecipe(recipeInfo)

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
    View.syncingDetails=true
    View.currentResult=result
    for _,control in ipairs({View.craftButton,View.quantity,View.decrease,View.increase,View.materialButton}) do control:SetShown(result~=nil) end
    for _, row in ipairs(View.materialRows) do row:Hide() end
    View.output:SetShown(result~=nil)
    if not result then
        View.title:ClearAllPoints(); View.title:SetPoint("TOPLEFT",1,-6)
        View.title:SetText("Choose a recipe")
        View.owner:SetText("")
        View.status:SetText("Open each profession to save its recipes.")
        View.estimate:SetText("")
        View.detailChild:SetHeight(303)
        View.syncingDetails=false
        return
    end
    local recipe, character = result.recipe, result.character
    local plan = Crafting.Plan(View.inventory, character, recipe)
    View.title:ClearAllPoints(); View.title:SetPoint("TOPLEFT",49,-6)
    local icon=recipe.icon
    if recipe.outputID and C_Item.GetItemInfo then
        local cached=select(10,C_Item.GetItemInfo(recipe.outputID))
        icon=cached or icon
        if not cached and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(recipe.outputID) end
    end
    View.outputIcon:SetTexture(icon or 134400)
    View.title:SetText(recipe.name)
    View.owner:SetText(character.name .. " / " .. result.profession.name .. " " ..
        (result.profession.rank or "?") .. "/" .. (result.profession.maximum or "?"))
    local status
    if plan.incomplete then status = "Open the profession to load this recipe."
    elseif character.key~=Vault.currentKey then status = "Log into "..character.name.." to create."
    elseif Vault.Professions and not Vault.Professions.open then status = "Open "..result.profession.name.." to create."
    elseif plan.noReagents then status = "No materials required."
    elseif plan.bags > 0 then status = plan.bags.." available from bags."
    elseif plan.personal > 0 then status = "Collect materials from your bank."
    elseif plan.account > 0 then status = "Collect materials from alts or mail."
    else status = "Materials missing. See Materials for a shopping list." end
    View.status:SetText(status)
    if View.quantityKey~=Key(result) then View.quantityKey=Key(result); View.quantity:SetText("1") end
    View.UpdateControls()
    View.estimate:SetText(Vault.Shopping.Estimate(Vault.Shopping.Build(result,math.max(1,View.Quantity())),true))
    local y = 112
    local batch=Crafting.Plan(View.inventory,character,Crafting.ScaleRecipe(recipe,math.max(1,View.Quantity())))
    for i, requirement in ipairs(batch.requirements) do
        local row = View.materialRows[i]
        if not row then
            row = CreateFrame("Frame", nil, View.detailChild)
            row:SetWidth(400)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(24, 24); row.icon:SetPoint("TOPLEFT", 0, -1)
            row.name = W.Text(row, "", 12, C.gold, 365); row.name:SetPoint("TOPLEFT", 32, 0)
            row.counts = W.Text(row, "", 11, C.text, 365); row.counts:SetPoint("TOPLEFT", 32, -17)
            row.owners = W.Text(row, "", 10, C.muted, 365); row.owners:SetPoint("TOPLEFT", 32, -34)
            View.materialRows[i] = row
        end
        row:SetPoint("TOPLEFT", 0, -y)
        row.icon:SetTexture(requirement.icon or 134400)
        local reagentName = requirement.name
        if requirement.id and (not reagentName or reagentName:match("^Item %d+$")) and C_Item.GetItemInfo then
            local name = C_Item.GetItemInfo(requirement.id)
            reagentName = name or reagentName
        end
        row.name:SetText((reagentName or "Reagent") .. "  (" .. requirement.required .. " required)")
        row.counts:SetText(requirement.unresolved and "Choose reagents in the profession window." or
            "Bags " .. requirement.bags .. " / Bank " .. requirement.bank .. " / Buy " .. requirement.accountMissing)
        local lines = {}
        for _, owner in ipairs(requirement.owners) do
            local record, parts = owner.record, {}
            for _, location in ipairs({"bags", "bank", "mail"}) do
                if record[location] > 0 then
                    local label = location == "bags" and "Bags" or location == "bank" and "Bank" or "Mail"
                    parts[#parts + 1] = label .. " " .. record[location]
                end
            end
            local limits = owner.otherRuleset and " [other or unknown ruleset]" or owner.otherFaction and " [other faction]" or
                record.bound > 0 and " [" .. record.bound .. " bound]" or ""
            lines[#lines + 1] = record.character.name .. ": " .. table.concat(parts, ", ") .. limits
        end
        if requirement.choices then
            for _, choice in ipairs(requirement.choices) do lines[#lines + 1] = choice.name end
        end
        row.owners:SetText(table.concat(lines, "\n"))
        row.owners:SetShown(#lines>0)
        local height = 36 + (#lines>0 and row.owners:GetStringHeight()+4 or 0)
        row:SetHeight(height); row:Show(); y = y + height + 8
    end
    View.detailChild:SetHeight(math.max(303, y + 5))
    View.syncingDetails=false
end

function View.Refresh()
    if not View.frame or not Vault.db then return end
    local _, available = Professions()
    if View.profession and not available[View.profession] then View.profession = nil end
    View.professionButton.label:SetText(View.profession or "All professions")
    View.results = Crafting.Recipes(Vault.db, View.character, View.profession, View.query or "")
    View.inventory = Crafting.Inventory(Vault.db, time(), Vault.db.settings.includeMail ~= false)
    View.characterButton.label:SetText(View.character and Vault.db.characters[View.character] and Vault.db.characters[View.character].name or "All characters")
    View.availableButton.label:SetText(View.availableOnly and "Bags: craftable" or "All availability")
    if View.availableOnly then
        local filtered={}
        for _,result in ipairs(View.results) do
            local plan=Crafting.Plan(View.inventory,result.character,result.recipe)
            if not plan.incomplete and (plan.noReagents or plan.bags>0) then filtered[#filtered+1]=result end
        end
        View.results=filtered
    end
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
    if (View.query or "") ~= "" and #View.results == 0 then View.recipeEmpty:SetText("No recipes match your search.") end
    View.RenderRecipes(); View.Details(selected)
    View.freshness:SetText(selected and ("Recipes saved: " .. Model.Age(selected.profession.updated, time()) ..
        (selected.profession.partial and " / Clear profession filters to record more." or "")) or
        "Open each character's professions once to save their recipes.")
    View.resultCount:SetText(#View.results .. " recipes / Tools and cooldowns apply.")
end
