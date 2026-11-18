-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
local Window = {}
Vault.ProfessionWindow = Window
local W, Model = Vault.UI.widgets, Vault.Model
local KEY = "WarbandVaultForever"

local function Tabs()
    local tabs = ForeverCore and ForeverCore.ProfessionTabs
    return tabs and (tabs.minor or 0) >= 2 and tabs or nil
end

function Window.SelectedRecipe()
    local page = ProfessionsFrame and ProfessionsFrame.CraftingPage
    local form = page and page.SchematicForm
    local info = form and form.GetRecipeInfo and form:GetRecipeInfo()
    return info and info.recipeID, page
end

function Window.Result(id)
    if not id or not Vault.currentKey then return end
    for _, result in ipairs(Vault.Crafting.Recipes(Vault.db, Vault.currentKey)) do
        if tostring(result.recipe.id) == tostring(id) then return result end
    end
end

function Window.Render()
    if not Window.panel then return end
    local id, page = Window.SelectedRecipe()
    local result = Window.Result(id)
    Window.result = result
    local input = page and page.CreateMultipleInputBox
    local count = input and input.GetNumber and input:GetNumber() or
        input and input.GetText and tonumber(input:GetText()) or 1
    count = math.max(1, math.min(999, math.floor(tonumber(count) or 1)))
    Window.count = count
    Window.materials:SetEnabled(result ~= nil)
    if not result then
        Window.title:SetText("Warband materials")
        Window.text:SetText("Select a learned recipe.\n\nOpen each profession once to save its recipes. Use Warband recipes to browse saved characters.")
    else
        local list = Vault.Shopping.Build(result, count)
        Window.title:SetText(result.recipe.name)
        local lines = {count .. " craft(s)", Vault.Shopping.Estimate(list, true), ""}
        if list.incomplete then lines[#lines+1] = "Recipe details are still loading." end
        for _, item in ipairs(list.items) do
            lines[#lines+1] = item.name .. " / Need " .. item.required
            lines[#lines+1] = "Bags " .. item.bags .. "  Bank " .. item.bank .. "  Buy " .. item.buy
            for _, holding in ipairs(item.holdings) do
                lines[#lines+1] = holding.name .. ": " .. holding.source .. " " .. holding.count ..
                    (holding.restricted and " (cannot transfer)" or "") .. " / " .. Model.Age(holding.updated, time())
            end
            for _, provider in ipairs(item.providers) do
                lines[#lines+1] = "Collect: " .. provider.name .. " / " .. provider.source .. " " .. provider.count
            end
            lines[#lines+1] = ""
        end
        lines[#lines+1] = "Saved bank and alt counts need collecting before crafting."
        Window.text:SetText(table.concat(lines, "\n"))
    end
    Window.child:SetHeight(math.max(300, Window.text:GetStringHeight() + 12))
end

function Window.Refresh()
    if not Vault.db then return end
    Window.Attach()
    if not Window.panel then return end
    if Vault.CraftingUI.frame:IsShown() then Vault.CraftingUI.Refresh() end
    Window.Render()
end

function Window.Open()
    Window.Attach()
    if not Window.panel then return false, "Install or update ForeverCore to use Warband recipes in the profession window." end
    if not ProfessionsFrame:IsShown() then return false, "Open a profession from your spellbook, then choose the Warband recipes side tab." end
    Tabs().Select(KEY)
    Vault.CraftingUI.Refresh()
    return true
end

function Window.Attach()
    if Window.panel or not Vault.db or not ProfessionsFrame or not ProfessionsFrame.CraftingPage or not Tabs() then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local host = ProfessionsFrame
    Vault.CraftingUI.Create(host)
    Tabs().Register(KEY, {icon="Interface\\AddOns\\WarbandVaultForever\\Assets\\Icon",
        tooltip="Warband recipes",page=Vault.CraftingUI.frame,minWidth=850,
        onSelect=function() Vault.CraftingUI.Refresh() end})
    local page=host.CraftingPage
    -- Parenting to the native page makes the sidebar follow its visibility,
    -- including other addons selecting their own profession pages.
    local panel=W.Panel(page or host,320,450)
    Window.panel=panel
    panel:SetPoint("TOPLEFT",host,"TOPRIGHT",35,-45)
    Window.title=W.Text(panel,"Warband materials",15,W.colors.gold,290)
    Window.title:SetPoint("TOPLEFT",14,-16)
    Window.scroll,Window.child=W.Scroll(panel,14,-52,265,330)
    Window.text=W.Text(Window.child,"",11,W.colors.text,260)
    Window.text:SetPoint("TOPLEFT")
    Window.materials=W.Button(panel,"Materials and shopping",205,28,function()
        if Window.result then Vault.Shopping.Open(Window.result,Window.count) end
    end)
    Window.materials:SetPoint("BOTTOMLEFT",14,14)
    Window.collapse=W.Button(panel,"Hide",65,28,function()
        Vault.db.settings.professionMaterials=false; Window.Visibility()
    end)
    Window.collapse:SetPoint("BOTTOMRIGHT",-12,14)
    Window.toggle=W.Button(page or host,"Warband materials",145,25,function()
        Vault.db.settings.professionMaterials=Vault.db.settings.professionMaterials==false
        Window.Visibility()
    end)
    Window.toggle:SetPoint("TOPLEFT",host,"TOPRIGHT",35,-15)
    host:HookScript("OnHide",function()
        if Tabs().Selected()==KEY then Tabs().ShowNative() end
        if Vault.UI.filterMenu then Vault.UI.filterMenu:Hide() end
    end)
    local elapsed=0
    Window.watcher=CreateFrame("Frame",nil,host)
    Window.watcher:SetScript("OnUpdate",function(_,delta)
        elapsed=elapsed+delta
        if elapsed<0.3 then return end
        elapsed=0
        Window.Visibility()
        local id,page=Window.SelectedRecipe()
        local input=page and page.CreateMultipleInputBox
        local value=input and input.GetText and input:GetText() or "1"
        local signature=tostring(id)..":"..tostring(value)
        if Window.signature~=signature then Window.signature=signature; Window.Render() end
    end)
    Window.Visibility()
    Window.Render()
end

function Window.Visibility()
    if Window.panel then
        local native=Tabs().Selected()==nil
        Window.toggle:SetShown(native)
        Window.panel:SetShown(native and Vault.db.settings.professionMaterials~=false)
    end
end
