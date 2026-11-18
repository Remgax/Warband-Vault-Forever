-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
local Window = {}
Vault.ProfessionWindow = Window
local W, Model = Vault.UI.widgets, Vault.Model
local KEY = "WarbandVaultForever"
-- Reserve the full native side-tab column and a gap before the materials panel.
local SIDEBAR_GAP = 76

local function Tabs()
    local tabs = ForeverCore and ForeverCore.ProfessionTabs
    return tabs and (tabs.minor or 0) >= 2 and tabs or nil
end

local function Locked()
    return InCombatLockdown and InCombatLockdown()
end

local function LastNative(host)
    local last = host.ProfessionsOverviewTab
    for _, tab in ipairs(host.rightProfessionTabs or {}) do
        if tab:IsShown() then last = tab end
    end
    return last
end

-- Keep our page independent of other addons. ForeverCore remains the preferred
-- tab coordinator when available, but the same small interface works alone.
local function BuiltInTabs(host)
    local api = {hidden = {}}
    function api.Selected() return api.selected end
    function api.ShowNative()
        if Locked() then api.pending = true; return end
        api.pending = nil
        api.selected = nil
        if api.spec then api.spec.page:Hide() end
        for page, alpha in pairs(api.hidden) do page:SetAlpha(alpha) end
        api.hidden = {}
        if api.width then host:SetWidth(api.width); api.width = nil end
    end
    function api.Select(key)
        if Locked() or not api.spec then return end
        if not api.selected then
            api.width = host:GetWidth()
            local function conceal(page)
                if page and page:IsShown() and api.hidden[page] == nil then
                    api.hidden[page] = page:GetAlpha()
                    page:SetAlpha(0)
                end
            end
            for _, page in ipairs(host.Pages or {}) do conceal(page) end
            for _, name in ipairs({"CraftingPage", "BookPage", "SpecPage", "OrdersPage"}) do conceal(host[name]) end
        end
        api.selected = key
        host:SetWidth(api.spec.minWidth or 850)
        api.spec.page:Show()
        if api.spec.onSelect then api.spec.onSelect() end
    end
    function api.Layout()
        if Locked() or not api.button then return end
        local above = LastNative(host)
        if api.placed and api.above == above then return end
        api.placed, api.above = true, above
        api.button:ClearAllPoints()
        if above then api.button:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -4)
        else api.button:SetPoint("TOPLEFT", host, "TOPRIGHT", 2, -80) end
    end
    function api.Register(key, spec)
        api.spec = spec
        local button = W.Button(host, "", 48, 48, function() Window.Open() end)
        api.button = button
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 5, -5); icon:SetPoint("BOTTOMRIGHT", -5, 5)
        icon:SetTexture(spec.icon)
        button:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Warband recipes")
            GameTooltip:Show()
        end)
        button:HookScript("OnLeave", function() GameTooltip:Hide() end)
        local function nativeClick() if api.selected then api.ShowNative() end end
        local overview = host.ProfessionsOverviewTab
        if overview then overview:HookScript("OnMouseUp", nativeClick) end
        for _, tab in ipairs(host.rightProfessionTabs or {}) do tab:HookScript("OnMouseUp", nativeClick) end
        if EventRegistry and EventRegistry.RegisterCallback then
            EventRegistry:RegisterCallback("ProfessionsFrame.TabSet", nativeClick, api)
            EventRegistry:RegisterCallback("Professions.ProfessionSelected", nativeClick, api)
        end
        api.Layout()
        return button
    end
    return api
end

function Window.ShowNative()
    if Window.navigation then Window.navigation.ShowNative() end
end

-- What's Training anchors its right tab at the window's bottom. ForeverCore
-- stacks registered addon tabs beneath it, putting the last tabs outside the
-- window. Move that chain's head below the native profession tabs instead.
function Window.CompactTabs()
    if InCombatLockdown and InCombatLockdown() then return end
    local launcher = _G.WhatsTrainingCraftingTab
    if not launcher or not launcher:IsShown() or WT_ProfessionTabPosition == "top" or WT_ProfessionTabPosition == "bottom" then return end
    local host = ProfessionsFrame
    local above = host and host.ProfessionsOverviewTab
    for _, tab in ipairs(host and host.rightProfessionTabs or {}) do
        if tab:IsShown() then above = tab end
    end
    if not above then return end
    local point, relative, relativePoint, x, y = launcher:GetPoint(1)
    if point == "TOPLEFT" and relative == above and relativePoint == "BOTTOMLEFT" and x == 0 and y == -2 then return end
    launcher:ClearAllPoints()
    launcher:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -2)
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
    if not Window.panel then return false, "Open a profession from your spellbook first." end
    if not ProfessionsFrame:IsShown() then return false, "Open a profession from your spellbook, then choose the Warband recipes side tab." end
    if Locked() then return false, "Leave combat before opening Warband recipes." end
    Window.navigation.Select(KEY)
    Vault.CraftingUI.Refresh()
    return true
end

function Window.Attach()
    if Window.panel then
        if Window.navigation.pending and not Locked() then Window.ShowNative() end
        return
    end
    if not Vault.db or not ProfessionsFrame or not ProfessionsFrame.CraftingPage then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local host = ProfessionsFrame
    Window.navigation = Tabs() or BuiltInTabs(host)
    Window.CompactTabs()
    Vault.CraftingUI.Create(host)
    Window.navigation.Register(KEY, {icon="Interface\\AddOns\\WarbandVaultForever\\Assets\\Icon",
        tooltip="Warband recipes",page=Vault.CraftingUI.frame,minWidth=850,
        onSelect=function() Vault.CraftingUI.Refresh() end})
    local page=host.CraftingPage
    -- Parenting to the native page makes the sidebar follow its visibility,
    -- including other addons selecting their own profession pages.
    local panel=W.Panel(page or host,320,450)
    Window.panel=panel
    panel:SetPoint("TOPLEFT",host,"TOPRIGHT",SIDEBAR_GAP,-45)
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
    Window.toggle:SetPoint("TOPLEFT",host,"TOPRIGHT",SIDEBAR_GAP,-15)
    host:HookScript("OnHide",function()
        if Window.navigation.Selected()==KEY then Window.ShowNative() end
        if Vault.UI.filterMenu then Vault.UI.filterMenu:Hide() end
    end)
    local elapsed=0
    Window.watcher=CreateFrame("Frame",nil,host)
    Window.watcher:SetScript("OnUpdate",function(_,delta)
        elapsed=elapsed+delta
        if elapsed<0.3 then return end
        elapsed=0
        Window.CompactTabs()
        if Window.navigation.Layout then Window.navigation.Layout() end
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
        local native=Window.navigation.Selected()==nil
        Window.toggle:SetShown(native)
        Window.panel:SetShown(native and Vault.db.settings.professionMaterials~=false)
    end
end
