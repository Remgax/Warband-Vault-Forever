-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
Vault.UI = {}
local UI, Model = Vault.UI, Vault.Model
local ART = "Interface\\AddOns\\WarbandVaultForever\\Assets\\"
local C = {
    stone = {0.063, 0.114, 0.169}, inset = {0.09, 0.157, 0.22},
    gold = {0.83, 0.68, 0.41}, text = {0.93, 0.90, 0.83},
    muted = {0.66, 0.74, 0.80}, blue = {0.35, 0.73, 0.87},
}
local labels = {all = "All items", bags = "Bags", bank = "Bank", equipment = "Equipment", mail = "Mailbox"}
UI.source, UI.sort, UI.query = "all", "name", ""

local function Panel(parent, width, height, color, name)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    frame:SetBackdropColor(unpack(color or C.stone))
    frame:SetBackdropBorderColor(0.25, 0.30, 0.34, 1)
    return frame
end

local function Text(parent, text, size, color, width)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(STANDARD_TEXT_FONT, size or 12, "")
    font:SetTextColor(unpack(color or C.text))
    font:SetJustifyH("LEFT")
    font:SetText(text or "")
    if width then font:SetWidth(width) end
    return font
end

local function Button(parent, text, width, height, action)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height or 30)
    button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    button:SetBackdropColor(unpack(C.inset))
    button:SetBackdropBorderColor(0.35, 0.37, 0.36, 1)
    button.label = Text(button, text, 12)
    button.label:SetPoint("CENTER")
    button:SetScript("OnClick", action)
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.gold)) end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.35, 0.37, 0.36, 1)
    end)
    return button
end

local function Scroll(parent, x, y, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", x, y)
    scroll:SetSize(width, height)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width, height)
    scroll:SetScrollChild(child)
    return scroll, child
end

local function Portrait(parent, size)
    local backing = Panel(parent, size + 4, size + 4, C.inset)
    backing:SetBackdropBorderColor(unpack(C.gold))
    local texture = backing:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    backing.portrait = texture
    return backing
end

local function DrawPortrait(frame, character)
    local texture = frame.portrait
    texture:SetTexCoord(0, 1, 0, 1)
    if character.key == Vault.currentKey then
        SetPortraitTexture(texture, "player")
    else
        -- Race/sex portraits remain available when an alt is offline. WoW cannot
        -- retain an arbitrary rendered character texture in SavedVariables.
        local sex = character.sex == 3 and "Female" or "Male"
        texture:SetTexture("Interface\\CharacterFrame\\TemporaryPortrait-" .. sex .. (character.race or "Human"))
    end
end

local function ClassColor(character)
    local color = RAID_CLASS_COLORS[character.class or "WARRIOR"]
    return color and {color.r, color.g, color.b} or C.text
end

local function ItemTooltip(button)
    local result = button.result
    if not result then return end
    local item = result.item
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if item.link then GameTooltip:SetHyperlink(item.link)
    else GameTooltip:SetItemByID(item.id) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(result.character.name .. " - " .. labels[result.source], unpack(C.gold))
    GameTooltip:AddLine("Recorded " .. Model.Age(result.updated, time()), unpack(C.muted))
    if item.expires then
        local remaining = math.floor((item.expires - time()) / 86400)
        GameTooltip:AddLine(remaining < 0 and "Mail may have expired; visit the mailbox." or
            "Mail expires in about " .. remaining .. " days.", 1, 0.65, 0.35)
        if item.cod then GameTooltip:AddLine("Cash on delivery attachment", 1, 0.65, 0.35) end
    end
    local owners = Model.Owners(Vault.db, item.id)
    if #owners > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Recorded across your characters", unpack(C.gold))
        for _, owner in ipairs(owners) do
            GameTooltip:AddDoubleLine(owner.character.name .. " - " .. owner.character.realm,
                tostring(owner.count), 0.8, 0.85, 0.9, 1, 1, 1)
        end
    end
    GameTooltip:Show()
end

function UI.Create()
    if UI.frame then return end
    local f = Panel(UIParent, 1060, 728, nil, "WarbandVaultForeverFrame")
    table.insert(UISpecialFrames, "WarbandVaultForeverFrame")
    UI.frame = f
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetBackdropBorderColor(unpack(C.gold))
    f:SetScript("OnHide", function() GameTooltip:Hide() end)

    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(113)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        Vault.db.settings.position = {point, relativePoint, x, y}
    end)
    local art = header:CreateTexture(nil, "BACKGROUND")
    art:SetAllPoints()
    art:SetTexture(ART .. "Header")
    art:SetTexCoord(0, 1, 0.287, 0.713)
    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ART .. "Icon")
    icon:SetSize(72, 72)
    icon:SetPoint("LEFT", 18, 0)
    local title = Text(header, "Warband Vault", 29, C.gold)
    title:SetFont("Fonts\\FRIZQT__.TTF", 29, "")
    title:SetPoint("TOPLEFT", 106, -26)
    Text(header, "Forever  /  Your characters. Their treasures.", 13, C.text):SetPoint("TOPLEFT", 108, -65)
    Button(f, "X", 28, 28, function() f:Hide() end):SetPoint("TOPRIGHT", -10, -10)
    UI.totals = Text(f, "", 14, C.gold, 1000)
    UI.totals:SetPoint("TOPLEFT", 20, -132)

    local roster = Panel(f, 259, 499, C.inset)
    roster:SetPoint("TOPLEFT", 16, -161)
    Button(roster, "All characters", 150, 30, function()
        UI.selected = nil; UI.itemsScroll:SetVerticalScroll(0); UI.Refresh()
    end):SetPoint("TOPLEFT", 10, -10)
    UI.sortButton = Button(roster, "Name", 77, 30, function(self)
        UI.sort = UI.sort == "name" and "gold" or "name"
        self.label:SetText(UI.sort == "name" and "Name" or "Gold")
        UI.Refresh()
    end)
    UI.sortButton:SetPoint("TOPRIGHT", -10, -10)
    UI.rosterScroll, UI.rosterChild = Scroll(roster, 8, -49, 220, 436)
    UI.rosterButtons = {}

    local main = Panel(f, 751, 499, C.stone)
    main:SetPoint("TOPLEFT", 290, -161)
    UI.portrait = Portrait(main, 52)
    UI.portrait:SetPoint("TOPLEFT", 14, -12)
    UI.name = Text(main, "All characters", 22, C.gold, 490)
    UI.name:SetPoint("TOPLEFT", 82, -13)
    UI.details = Text(main, "", 12, C.muted, 635)
    UI.details:SetPoint("TOPLEFT", 82, -44)
    UI.characterGold = Text(main, "", 13, C.gold)
    UI.characterGold:SetPoint("TOPRIGHT", -16, -18)
    UI.tabs = {}
    local tabKeys = {"all", "bags", "bank", "equipment", "mail"}
    for i, key in ipairs(tabKeys) do
        local source = key
        local button = Button(main, labels[key], 133, 30, function()
            UI.source = source; UI.itemsScroll:SetVerticalScroll(0); UI.Refresh()
        end)
        button:SetPoint("TOPLEFT", 14 + (i - 1) * 143, -80)
        UI.tabs[key] = button
    end

    local searchBox = Panel(main, 536, 31, C.inset)
    searchBox:SetPoint("TOPLEFT", 14, -124)
    UI.search = CreateFrame("EditBox", nil, searchBox)
    UI.search:SetPoint("TOPLEFT", 10, -2)
    UI.search:SetPoint("BOTTOMRIGHT", -10, 2)
    UI.search:SetFontObject(GameFontHighlight)
    UI.search:SetAutoFocus(false)
    UI.search:SetMaxLetters(160)
    local hint = Text(searchBox, "Search items, item ID, character, or realm", 12, C.muted)
    hint:SetPoint("LEFT", 10, 0)
    UI.search:SetScript("OnTextChanged", function(self)
        UI.query = self:GetText()
        hint:SetShown(UI.query == "")
        UI.itemsScroll:SetVerticalScroll(0)
        UI.RefreshItems()
    end)
    UI.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    UI.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    UI.qualityButton = Button(main, "Any quality", 172, 31, function(self)
        UI.quality = UI.quality == nil and 0 or UI.quality + 1
        if UI.quality > 5 then UI.quality = nil end
        self.label:SetText(UI.quality and (_G["ITEM_QUALITY" .. UI.quality .. "_DESC"] or tostring(UI.quality)) or "Any quality")
        UI.itemsScroll:SetVerticalScroll(0); UI.RefreshItems()
    end)
    UI.qualityButton:SetPoint("TOPRIGHT", -14, -124)
    UI.itemsScroll, UI.itemsChild = Scroll(main, 14, -169, 704, 264)
    UI.itemButtons = {}
    UI.itemsScroll:HookScript("OnVerticalScroll", function() UI.RenderGrid() end)
    UI.empty = Text(UI.itemsChild, "", 15, C.muted, 660)
    UI.empty:SetPoint("TOPLEFT", 10, -40)
    UI.empty:SetJustifyH("CENTER")
    UI.freshness = Text(main, "", 12, C.muted, 716)
    UI.freshness:SetPoint("TOPLEFT", 14, -449)
    UI.resultCount = Text(main, "", 11, C.muted, 716)
    UI.resultCount:SetPoint("TOPLEFT", 14, -473)

    Text(f, "Saved snapshots / Log into each character; visit their bank and mailbox.", 11, C.muted, 690):SetPoint("BOTTOMLEFT", 20, 42)
    Text(f, "Offline portraits use race and gender. Gold shows recorded wallet balances.", 10, C.muted, 690):SetPoint("BOTTOMLEFT", 20, 23)
    Button(f, "Refresh", 100, 30, function() Vault.Scanner.Refresh() end):SetPoint("BOTTOMRIGHT", -143, 25)
    Button(f, "UI scale", 110, 30, function()
        local scale = (Vault.db.settings.scale or 1) - 0.1
        if scale < 0.69 then scale = 1.2 end
        Vault.db.settings.scale = scale
        UI.ApplyPosition()
    end):SetPoint("BOTTOMRIGHT", -22, 25)
    f:Hide()
end

function UI.ApplyPosition()
    local f = UI.frame
    local fit = math.min(UIParent:GetWidth() / 1100, UIParent:GetHeight() / 768, 1)
    f:SetScale(math.min(Vault.db.settings.scale or 1, fit))
    local p = Vault.db.settings.position
    f:ClearAllPoints()
    if p then f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else f:SetPoint("CENTER") end
end

function UI.RenderGrid()
    local results = UI.results or {}
    for _, button in ipairs(UI.itemButtons) do button:Hide() end
    local first = math.floor(UI.itemsScroll:GetVerticalScroll() / 59) * 12 + 1
    -- Reuse 84 slots regardless of how many possessions the account records.
    for i = first, math.min(first + 83, #results) do
        local result = results[i]
        local poolIndex = i - first + 1
        local button = UI.itemButtons[poolIndex]
        if not button then
            button = CreateFrame("Button", nil, UI.itemsChild, "BackdropTemplate")
            button:SetSize(53, 53)
            button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2})
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetPoint("TOPLEFT", 3, -3)
            button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
            button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
            button.count = Text(button, "", 12)
            button.count:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            button.count:SetPoint("BOTTOMRIGHT", -4, 4)
            button:SetScript("OnEnter", ItemTooltip)
            button:SetScript("OnLeave", function() GameTooltip:Hide() end)
            button:SetScript("OnClick", function(self)
                if IsShiftKeyDown() and self.result.item.link then
                    HandleModifiedItemClick(self.result.item.link)
                end
            end)
            UI.itemButtons[poolIndex] = button
        end
        button.result = result
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", ((i - 1) % 12) * 58, -math.floor((i - 1) / 12) * 59)
        button.icon:SetTexture(result.item.icon or 134400)
        button.count:SetText(result.item.count > 1 and result.item.count or "")
        local color = ITEM_QUALITY_COLORS[result.item.quality or 1]
        button:SetBackdropColor(0, 0, 0, 1)
        button:SetBackdropBorderColor(color.r, color.g, color.b, 1)
        button:Show()
    end
end

function UI.RefreshItems()
    if not UI.frame or not Vault.db then return end
    local results = Model.Find(Vault.db, UI.selected, UI.source, UI.query, UI.quality)
    UI.results = results
    UI.itemsChild:SetHeight(math.max(264, math.ceil(#results / 12) * 59))
    local maxScroll = math.max(0, UI.itemsChild:GetHeight() - UI.itemsScroll:GetHeight())
    if UI.itemsScroll:GetVerticalScroll() > maxScroll then UI.itemsScroll:SetVerticalScroll(maxScroll) end
    UI.RenderGrid()
    UI.empty:SetShown(#results == 0)
    local character = UI.selected and Vault.db.characters[UI.selected]
    local snapshot = character and character.snapshots[UI.source]
    if #results == 0 then
        local message = "No items match your search."
        if UI.query == "" and UI.quality == nil then
            if UI.source == "bank" and character and not snapshot then
                message = "Bank not recorded.\nLog into " .. character.name .. " and visit a banker."
            elseif UI.source == "mail" and character and not snapshot then
                message = "Mailbox not recorded.\nLog into " .. character.name .. " and open a mailbox."
            else message = "No recorded items here.\nLog into each character to record their possessions." end
        end
        UI.empty:SetText(message)
    end
    local stackCount = 0
    for _, result in ipairs(results) do stackCount = stackCount + result.item.count end
    UI.resultCount:SetText(#results .. " stacks / " .. stackCount .. " items / Hover for owner and saved time; Shift-click to link.")
    if character and UI.source ~= "all" then
        local details = labels[UI.source] .. ": " .. Model.Age(snapshot and snapshot.updated, time())
        if snapshot and UI.source ~= "mail" then
            details = details .. " / " .. #snapshot.items .. " of " .. snapshot.capacity .. " slots occupied"
        end
        if snapshot and snapshot.partial then details = details .. " / More mail remains on the server" end
        if snapshot and snapshot.money and snapshot.money > 0 then details = details .. " / Mail gold: " .. Model.Money(snapshot.money) end
        UI.freshness:SetText(details)
    elseif character then
        UI.freshness:SetText("Bags: " .. Model.Age(character.snapshots.bags and character.snapshots.bags.updated, time()) ..
            " / Bank: " .. Model.Age(character.snapshots.bank and character.snapshots.bank.updated, time()) ..
            " / Mail: " .. Model.Age(character.snapshots.mail and character.snapshots.mail.updated, time()))
    else
        UI.freshness:SetText("Browsing saved records across all realms. Offline records refresh on that character.")
    end
end

function UI.Refresh()
    if not UI.frame or not UI.frame:IsShown() or not Vault.db then return end
    local gold, count, stacks = Model.Totals(Vault.db)
    UI.totals:SetText("Recorded gold  " .. Model.Money(gold) .. "     /     " .. count .. " characters     /     " .. stacks .. " recorded stacks")
    for _, button in ipairs(UI.rosterButtons) do button:Hide() end
    local characters = Model.Characters(Vault.db, UI.sort)
    for i, character in ipairs(characters) do
        local button = UI.rosterButtons[i]
        if not button then
            button = Button(UI.rosterChild, "", 219, 81, function(self)
                UI.selected = self.character.key
                UI.itemsScroll:SetVerticalScroll(0)
                UI.Refresh()
            end)
            button.face = Portrait(button, 36)
            button.face:SetPoint("TOPLEFT", 8, -10)
            button.name = Text(button, "", 13, nil, 153)
            button.name:SetPoint("TOPLEFT", 54, -11)
            button.meta = Text(button, "", 10, C.muted, 154)
            button.meta:SetPoint("TOPLEFT", 54, -31)
            button.money = Text(button, "", 11, C.gold, 200)
            button.money:SetPoint("TOPLEFT", 10, -58)
            UI.rosterButtons[i] = button
        end
        button.character = character
        button:SetPoint("TOPLEFT", 0, -(i - 1) * 88)
        button.name:SetText(character.name .. (character.key == Vault.currentKey and " *" or ""))
        button.name:SetTextColor(unpack(ClassColor(character)))
        button.meta:SetText(character.level .. " " .. (character.className or character.class) .. "\n" .. character.realm)
        button.money:SetText(Model.Money(character.money))
        DrawPortrait(button.face, character)
        button:SetBackdropColor(unpack(UI.selected == character.key and {0.17, 0.24, 0.29} or C.inset))
        button:Show()
    end
    UI.rosterChild:SetHeight(math.max(436, #characters * 88))
    local character = UI.selected and Vault.db.characters[UI.selected]
    if character then
        UI.name:SetText(character.name)
        UI.name:SetTextColor(unpack(ClassColor(character)))
        UI.details:SetText(character.level .. " " .. character.raceName .. " " .. character.className ..
            " / " .. character.realm .. " / " .. character.faction)
        UI.characterGold:SetText(Model.Money(character.money))
        DrawPortrait(UI.portrait, character)
    else
        UI.name:SetText("All characters")
        UI.name:SetTextColor(unpack(C.gold))
        UI.details:SetText("Search every recorded character, realm, and storage location.")
        UI.characterGold:SetText("")
        UI.portrait.portrait:SetTexCoord(0, 1, 0, 1)
        UI.portrait.portrait:SetTexture(ART .. "Icon")
    end
    for key, button in pairs(UI.tabs) do
        button.label:SetTextColor(unpack(key == UI.source and C.gold or C.text))
        button:SetBackdropColor(unpack(key == UI.source and {0.18, 0.23, 0.26} or C.inset))
    end
    UI.RefreshItems()
end

function UI.Toggle()
    if not Vault.db then return end
    UI.Create()
    UI.frame:SetShown(not UI.frame:IsShown())
    if UI.frame:IsShown() then UI.ApplyPosition(); UI.Refresh() end
end

function UI.Minimap()
    local button = CreateFrame("Button", "WarbandVaultForeverMinimapButton", Minimap)
    button:SetSize(30, 30)
    local function Position()
        local angle = math.rad(Vault.db.settings.minimapAngle or 225)
        local radius = Minimap:GetWidth() / 2 + 7
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
    end
    Position()
    button:SetFrameStrata("MEDIUM")
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture(ART .. "Icon")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        self.dragged = true
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local cx, cy = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            Vault.db.settings.minimapAngle = math.deg(math.atan2(y / scale - cy, x / scale - cx))
            Position()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        C_Timer.After(0.1, function() self.dragged = false end)
    end)
    button:SetScript("OnClick", function(self) if not self.dragged then UI.Toggle() end end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Warband Vault Forever", unpack(C.gold))
        GameTooltip:AddLine("Click to browse your characters.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move around the minimap.", unpack(C.muted))
        GameTooltip:AddLine("/wvf minimap to hide this button", unpack(C.muted))
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetShown(Vault.db.settings.minimap ~= false)
    UI.minimap = button
end
