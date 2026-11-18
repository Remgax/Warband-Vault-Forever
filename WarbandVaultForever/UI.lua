-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
Vault.UI = {}
local UI, Model = Vault.UI, Vault.Model
local ART = "Interface\\AddOns\\WarbandVaultForever\\Assets\\"
local C = {
    stone = {0.145, 0.102, 0.078}, inset = {0.29, 0.19, 0.125},
    gold = {0.79, 0.61, 0.30}, text = {0.94, 0.89, 0.78},
    muted = {0.72, 0.65, 0.54}, blue = {0.42, 0.69, 0.81},
}
local labels = {all = "All items", bags = "Bags", bank = "Bank", equipment = "Equipment", mail = "Mailbox"}
local COLUMNS, CELL, VIEW_HEIGHT = 10, 60, 210
UI.source, UI.sort, UI.query = "bags", "name", ""

local function Panel(parent, width, height, color, name)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({bgFile = ART .. "Leather", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16, tile = true, tileSize = 256, insets = {left = 5, right = 5, top = 5, bottom = 5}})
    frame:SetBackdropColor(1, 1, 1, 1)
    frame:SetBackdropBorderColor(0.65, 0.50, 0.29, 1)
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
    button:SetBackdrop({bgFile = ART .. "Leather", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10, insets = {left = 3, right = 3, top = 3, bottom = 3}})
    button:SetBackdropColor(1, 1, 1, 1)
    button:SetBackdropBorderColor(0.40, 0.29, 0.17, 1)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    button.label = Text(button, text, 12)
    button.label:SetPoint("CENTER")
    button.label:SetWidth(width - 12); button.label:SetWordWrap(false); button.label:SetJustifyH("CENTER")
    button:SetScript("OnClick", action)
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.gold)) end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.40, 0.29, 0.17, 1)
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
    local backing = CreateFrame("Frame",nil,parent)
    backing:SetSize(size+4,size+4)
    local background=backing:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(); background:SetTexture(ART.."CircleMask")
    background:SetVertexColor(unpack(C.inset))
    local texture = backing:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    backing.livePortrait = backing:CreateTexture(nil, "ARTWORK")
    backing.livePortrait:SetAllPoints(texture)
    backing.livePortrait:Hide()
    local mask=backing:CreateMaskTexture(nil,"ARTWORK")
    mask:SetTexture(ART.."CircleMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask); backing.livePortrait:AddMaskTexture(mask)
    local rim=backing:CreateTexture(nil,"OVERLAY")
    rim:SetTexture(ART.."SlotRing"); rim:SetAllPoints()
    rim:SetVertexColor(unpack(C.gold))
    backing.mask=mask; backing.rim=rim
    backing.portrait = texture
    return backing
end

UI.widgets = {Panel = Panel, Text = Text, Button = Button, Scroll = Scroll, colors = C}
UI.rosterFilters = {}

function UI.FilterMenu(anchor, choices, selectChoice)
    if not UI.filterMenu then
        local menu = Panel(UI.frame, 230, 300, nil, "WarbandVaultForeverFilterMenu")
        menu:SetFrameLevel(UI.frame:GetFrameLevel() + 50)
        menu:SetClampedToScreen(true)
        table.insert(UISpecialFrames, "WarbandVaultForeverFilterMenu")
        menu.scroll, menu.child = Scroll(menu, 8, -10, 192, 278)
        menu.buttons = {}
        UI.filterMenu = menu
    end
    local menu = UI.filterMenu
    for _, button in ipairs(menu.buttons) do button:Hide() end
    local height = math.min(#choices * 28 + 20, 300)
    menu:SetHeight(height)
    menu.scroll:SetHeight(height - 20)
    menu.child:SetHeight(#choices * 28)
    menu.scroll:SetVerticalScroll(0)
    menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    for i, choice in ipairs(choices) do
        local button = menu.buttons[i]
        if not button then button = Button(menu.child, "", 190, 26, function() end); menu.buttons[i] = button end
        button.label:SetText(choice.text)
        button:SetPoint("TOPLEFT", 0, -(i - 1) * 28)
        local option = choice
        button:SetScript("OnClick", function() menu:Hide(); selectChoice(option.value) end)
        button:Show()
    end
    menu:Show()
end

local function FilterOptions(field, title)
    local values, choices = {}, {{text = title, value = false}}
    for _, character in ipairs(Vault.Model.Characters(Vault.db)) do
        if field == "profession" then
            for name in pairs(character.professions or {}) do values[name] = name end
        elseif character[field] then values[character[field]] = field == "class" and character.className or character[field] end
    end
    for value, text in pairs(values) do choices[#choices + 1] = {text = text, value = value} end
    table.sort(choices, function(a, b)
        if a.value == false then return true elseif b.value == false then return false end
        return a.text < b.text
    end)
    return choices
end

function UI.RosterLayout()
    local top = UI.filtersExpanded and 240 or 112
    UI.filterPanel:SetShown(UI.filtersExpanded or false)
    UI.rosterScroll:ClearAllPoints()
    UI.rosterScroll:SetPoint("TOPLEFT", UI.roster, "TOPLEFT", 12, -top)
    UI.rosterScroll:SetHeight(523 - top - 16)
    UI.rosterScroll:SetVerticalScroll(0)
    local active = 0
    for key, value in pairs(UI.rosterFilters) do if value and value ~= "" then active = active + 1 end end
    UI.filterButton.label:SetText("Filters" .. (active > 0 and " (" .. active .. ")" or ""))
end

local function DrawPortrait(frame, character)
    local texture = frame.portrait
    texture:SetTexCoord(0, 1, 0, 1)
    if character.key == Vault.currentKey and not character.remoteAccount then
        texture:Hide(); frame.livePortrait:Show()
        SetPortraitTexture(frame.livePortrait, "player")
    else
        frame.livePortrait:Hide(); texture:Show()
        -- Never reuse the player's rendered portrait as an offline portrait.
        local sex = character.sex == 3 and "female" or "male"
        local race = (character.race or ""):lower()
        local atlas = "raceicon128-" .. race .. "-" .. sex
        texture:SetTexture(nil)
        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
            texture:SetAtlas(atlas)
        else
            texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[character.class]
            if coords then texture:SetTexCoord(unpack(coords)) end
        end
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
    GameTooltip:AddLine("Saved: " .. Model.Age(result.updated, time()), unpack(C.muted))
    if item.expires then
        local remaining = math.floor((item.expires - time()) / 86400)
        GameTooltip:AddLine(remaining < 0 and "Mail may have expired; visit the mailbox." or
            "Mail expires in about " .. remaining .. " days.", 1, 0.65, 0.35)
        if item.cod then GameTooltip:AddLine("Cash on delivery attachment", 1, 0.65, 0.35) end
    end
    local owners = Model.Owners(Vault.db, item.id)
    if #owners > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Owned by", unpack(C.gold))
        for _, owner in ipairs(owners) do
            GameTooltip:AddDoubleLine(owner.character.name .. " - " .. owner.character.realm,
                tostring(owner.count), 0.8, 0.85, 0.9, 1, 1, 1)
        end
    end
    GameTooltip:Show()
end

function UI.StopEffects()
    if not UI.frame then return end
    UI.frame:SetScript("OnUpdate", nil)
    UI.frame:SetAlpha(1)
    if UI.flap then UI.flap:Hide() end
end

function UI.OpenEffect()
    UI.StopEffects()
    local strength = Vault.db.settings.effects == false and 0 or Vault.db.settings.effectStrength or 0.7
    if strength <= 0 then return end
    local elapsed = 0
    UI.frame:SetAlpha(1 - 0.75 * strength)
    UI.flap:Show()
    UI.frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        local p = math.min(elapsed / 0.24, 1)
        local eased = 1 - (1 - p) ^ 3
        self:SetAlpha(1 - 0.75 * strength * (1 - eased))
        UI.flap:SetHeight(65 + 130 * strength * (1 - eased))
        UI.flap:SetAlpha(0.9 * strength * (1 - eased))
        if p == 1 then UI.StopEffects() end
    end)
end

function UI.PlayOpeningSound()
    local volume = Vault.db.settings.sound == false and 0 or Vault.db.settings.soundVolume or 0.8
    if volume <= 0 or not SOUNDKIT or not SOUNDKIT.IG_BACKPACK_OPEN then return end
    if C_Sound and C_Sound.PlaySoundWithOptions then
        C_Sound.PlaySoundWithOptions({soundKitID = SOUNDKIT.IG_BACKPACK_OPEN, volumeOverride = volume})
    elseif C_Sound and C_Sound.PlaySound then
        C_Sound.PlaySound(SOUNDKIT.IG_BACKPACK_OPEN, nil, false, false, nil, volume)
    elseif PlaySound then PlaySound(SOUNDKIT.IG_BACKPACK_OPEN) end
end

function UI.Close()
    if UI.frame then UI.frame:Hide() end
end

function UI.Help(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine("Warband Vault", unpack(C.gold))
    GameTooltip:AddLine("Log into each character to save their bags and gold.", 1, 1, 1)
    GameTooltip:AddLine("Visit their bank and mailbox to save those items.", 1, 1, 1)
    GameTooltip:AddLine("Choose a character, then a storage tab. Search by item or owner.", 1, 1, 1)
    GameTooltip:AddLine("Hover an item for details. Shift-click to link it.", 1, 1, 1)
    GameTooltip:AddLine("Drag the title to move the window. Escape closes it.", unpack(C.muted))
    GameTooltip:AddLine("Offline portraits show race and gender. Gold totals count wallets.", unpack(C.muted))
    GameTooltip:Show()
end

function UI.Create()
    if UI.frame then return end
    local f = Panel(UIParent, 1060, 760, nil, "WarbandVaultForeverFrame")
    table.insert(UISpecialFrames, "WarbandVaultForeverFrame")
    UI.frame = f
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetBackdropBorderColor(unpack(C.gold))
    f:SetScript("OnHide", function()
        UI.StopEffects(); GameTooltip:Hide()
        if UI.filterMenu then UI.filterMenu:Hide() end
    end)

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
    UI.header = header
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
    Text(header, "Forever", 13, C.muted):SetPoint("TOPLEFT", 108, -65)
    local close = CreateFrame("Button", "WarbandVaultForeverCloseButton", f, "UIPanelCloseButton")
    close:SetSize(36, 36)
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetFrameLevel(header:GetFrameLevel() + 20)
    close:EnableMouse(true)
    close:RegisterForClicks("LeftButtonUp")
    close:SetScript("OnClick", UI.Close)
    close:SetScript("OnMouseUp", function(_, mouse) if mouse == "LeftButton" then UI.Close() end end)
    UI.closeButton = close
    UI.settingsButton = Button(f, "Settings", 82, 28, function() UI.Settings() end)
    UI.settingsButton:SetPoint("BOTTOMRIGHT", -133, 20)
    UI.settingsButton:SetFrameLevel(header:GetFrameLevel() + 20)
    UI.totals = Text(f, "", 14, C.gold, 1000)
    UI.totals:SetPoint("TOPLEFT", 20, -132)

    local roster = Panel(f, 259, 523, C.inset)
    UI.roster = roster
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
    UI.rosterScroll, UI.rosterChild = Scroll(roster, 12, -49, 216, 458)
    UI.rosterButtons = {}
    local characterSearch = Panel(roster, 230, 28)
    characterSearch:SetPoint("TOPLEFT", 12, -47)
    UI.characterSearch = CreateFrame("EditBox", nil, characterSearch)
    UI.characterSearch:SetPoint("TOPLEFT", 7, -2); UI.characterSearch:SetPoint("BOTTOMRIGHT", -7, 2)
    UI.characterSearch:SetFontObject(GameFontHighlight); UI.characterSearch:SetAutoFocus(false)
    UI.characterSearch:SetMaxLetters(100)
    local characterHint = Text(characterSearch, "Find a character or profession", 11, C.muted)
    characterHint:SetPoint("LEFT", 7, 0)
    UI.characterSearch:SetScript("OnTextChanged", function(self)
        UI.rosterFilters.query = self:GetText()
        characterHint:SetShown(self:GetText() == "")
        UI.Refresh()
    end)
    UI.characterSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    UI.filterButton = Button(roster, "Filters", 111, 26, function()
        UI.filtersExpanded = not UI.filtersExpanded; UI.RosterLayout(); UI.Refresh()
    end)
    UI.filterButton:SetPoint("TOPLEFT", 12, -79)
    UI.clearFilters = Button(roster, "Clear filters", 111, 26, function()
        UI.rosterFilters = {}; UI.characterSearch:SetText("")
        if UI.minLevel then UI.minLevel:SetText(""); UI.maxLevel:SetText("") end
        for _, control in pairs(UI.filterControls) do control.button.label:SetText(control.title) end
        UI.RosterLayout(); UI.Refresh()
    end)
    UI.clearFilters:SetPoint("TOPLEFT", 131, -79)
    UI.filterPanel = CreateFrame("Frame", nil, roster)
    UI.filterPanel:SetPoint("TOPLEFT", 12, -112); UI.filterPanel:SetSize(230, 123)
    UI.filterControls = {}
    for i, definition in ipairs({{"class", "Any class"}, {"profession", "Any profession"}, {"realm", "Any realm"}, {"faction", "Any faction"}}) do
        local field, title = definition[1], definition[2]
        local button = Button(UI.filterPanel, title, 111, 28, function(self)
            UI.FilterMenu(self, FilterOptions(field, title), function(value)
                UI.rosterFilters[field] = value or nil
                local label = title
                for _, choice in ipairs(FilterOptions(field, title)) do if choice.value == value then label = choice.text end end
                self.label:SetText(label); UI.RosterLayout(); UI.Refresh()
            end)
        end)
        button:SetPoint("TOPLEFT", ((i - 1) % 2) * 119, -math.floor((i - 1) / 2) * 34)
        UI.filterControls[field] = {button = button, title = title}
    end
    Text(UI.filterPanel, "Level", 12, C.muted):SetPoint("TOPLEFT", 3, -77)
    for i, key in ipairs({"minLevel", "maxLevel"}) do
        local box = Panel(UI.filterPanel, 67, 27)
        box:SetPoint("TOPLEFT", 64 + (i - 1) * 85, -70)
        local input = CreateFrame("EditBox", nil, box)
        input:SetPoint("TOPLEFT", 7, -2); input:SetPoint("BOTTOMRIGHT", -7, 2)
        input:SetFontObject(GameFontHighlight); input:SetAutoFocus(false); input:SetNumeric(true); input:SetMaxLetters(3)
        input:SetScript("OnTextChanged", function(self) UI.rosterFilters[key] = tonumber(self:GetText()); UI.Refresh() end)
        input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        UI[key] = input
    end
    Text(UI.filterPanel, "to", 11, C.muted):SetPoint("TOPLEFT", 132, -77)
    UI.rosterEmpty = Text(UI.rosterChild, "No characters match.\nClear the filters to see everyone.", 12, C.muted, 205)
    UI.rosterEmpty:SetPoint("TOPLEFT", 5, -20)
    UI.RosterLayout()

    local main = Panel(f, 751, 523, C.stone)
    UI.main = main
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
    labels.crafting = "Crafting"
    local tabKeys = {"all", "bags", "bank", "equipment", "mail", "crafting"}
    for i, key in ipairs(tabKeys) do
        local source = key
        local button = Button(main, labels[key], 112, 30, function()
            UI.source = source; UI.itemsScroll:SetVerticalScroll(0); UI.Refresh()
        end)
        button:SetPoint("TOPLEFT", 14 + (i - 1) * 120, -80)
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
    local hint = Text(searchBox, "Search items or characters", 12, C.muted)
    UI.searchHint = hint
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
    local satchel = main:CreateTexture(nil, "ARTWORK")
    satchel:SetTexture(ART .. "Satchel")
    satchel:SetPoint("TOPLEFT", 5, -165)
    satchel:SetSize(741, 318)
    UI.satchel = satchel
    local flapHost = CreateFrame("Frame", nil, main)
    flapHost:SetAllPoints(main)
    flapHost:SetFrameLevel(main:GetFrameLevel() + 6)
    flapHost:EnableMouse(false)
    UI.flap = flapHost:CreateTexture(nil, "OVERLAY")
    UI.flap:SetTexture(ART .. "Satchel")
    UI.flap:SetTexCoord(0, 1, 0, 0.25)
    UI.flap:SetPoint("TOPLEFT", 5, -165)
    UI.flap:SetSize(741, 65)
    UI.flap:Hide()
    UI.itemsScroll, UI.itemsChild = Scroll(main, 64, -244, 610, VIEW_HEIGHT)
    UI.itemButtons = {}
    UI.itemsScroll:HookScript("OnVerticalScroll", function() UI.RenderGrid() end)
    UI.empty = Text(UI.itemsChild, "", 15, C.text, 620)
    UI.empty:SetPoint("TOPLEFT", 5, -55)
    UI.empty:SetJustifyH("CENTER")
    UI.freshness = Text(main, "", 12, C.muted, 716)
    UI.freshness:SetPoint("BOTTOMLEFT", 17, 33)
    UI.resultCount = Text(main, "", 11, C.muted, 716)
    UI.resultCount:SetPoint("BOTTOMLEFT", 17, 14)

    local help = Button(f, "Help", 64, 30, UI.Help)
    help:SetPoint("BOTTOMLEFT", 20, 22)
    help:SetScript("OnEnter", UI.Help)
    help:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Text(f, "Hover for details. Shift-click to link.", 11, C.muted, 292):SetPoint("BOTTOMLEFT", 98, 31)
    Button(f, "Refresh", 100, 30, function() Vault.Scanner.Refresh() end):SetPoint("BOTTOMRIGHT", -22, 22)
    if Vault.CraftingUI then Vault.CraftingUI.Create() end
    f:Hide()
end

function UI.ApplyPosition()
    local f = UI.frame
    local fit = math.min(UIParent:GetWidth() / 1100, UIParent:GetHeight() / 800)
    f:SetScale(math.min(Vault.db.settings.scale or 1, fit))
    local p = Vault.db.settings.position
    f:ClearAllPoints()
    if p then f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else f:SetPoint("CENTER") end
end

function UI.RenderGrid()
    local results = UI.results or {}
    for _, button in ipairs(UI.itemButtons) do button:Hide() end
    local first = math.floor(UI.itemsScroll:GetVerticalScroll() / CELL) * COLUMNS + 1
    -- Six rows cover the viewport and the next scroll boundary.
    for i = first, math.min(first + COLUMNS * 6 - 1, #results) do
        local result = results[i]
        local poolIndex = i - first + 1
        local button = UI.itemButtons[poolIndex]
        if not button then
            button = CreateFrame("Button", nil, UI.itemsChild, "BackdropTemplate")
            button:SetSize(48, 48)
            button:EnableMouse(true)
            button:RegisterForClicks("LeftButtonUp")
            button.pocket = button:CreateTexture(nil, "BACKGROUND")
            button.pocket:SetTexture(ART .. "CircleMask")
            button.pocket:SetAllPoints()
            button.pocket:SetVertexColor(0, 0, 0, 0.9)
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetPoint("TOPLEFT", 4, -4)
            button.icon:SetPoint("BOTTOMRIGHT", -4, 4)
            button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
            button.mask = button:CreateMaskTexture(nil, "ARTWORK")
            button.mask:SetTexture(ART .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            button.mask:SetAllPoints(button.icon)
            button.icon:AddMaskTexture(button.mask)
            button.rim = button:CreateTexture(nil, "OVERLAY")
            button.rim:SetTexture(ART .. "SlotRing")
            button.rim:SetAllPoints()
            button.count = Text(button, "", 12)
            button.count:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            button.count:SetPoint("BOTTOMRIGHT", -4, 4)
            button.glow = button:CreateTexture(nil, "OVERLAY")
            button.glow:SetTexture(ART .. "SlotGlow")
            button.glow:SetBlendMode("ADD")
            button.glow:SetVertexColor(1, 0.76, 0.32, 0.7)
            button.glow:SetSize(72, 72)
            button.glow:SetPoint("CENTER")
            button.glow:Hide()
            button:SetScript("OnEnter", function(self)
                local strength = Vault.db.settings.effects == false and 0 or Vault.db.settings.effectStrength or 0.7
                self.glow:SetAlpha(strength)
                self.glow:SetShown(strength > 0)
                ItemTooltip(self)
            end)
            button:SetScript("OnLeave", function(self) self.glow:Hide(); GameTooltip:Hide() end)
            button:SetScript("OnClick", function(self)
                if IsShiftKeyDown() and self.result.item.link then
                    HandleModifiedItemClick(self.result.item.link)
                end
            end)
            UI.itemButtons[poolIndex] = button
        end
        button.result = result
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", ((i - 1) % COLUMNS) * CELL, -math.floor((i - 1) / COLUMNS) * CELL)
        button.glow:Hide()
        local item=result.item
        local localIcon=C_Item.GetItemIconByID and C_Item.GetItemIconByID(item.id)
        if not localIcon and C_Item.GetItemInfo then localIcon=select(10,C_Item.GetItemInfo(item.id)) end
        if result.character and result.character.remoteAccount and not localIcon and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(item.id) end
        button.icon:SetTexture(localIcon or item.icon or 134400)
        button.count:SetText(result.item.count > 1 and result.item.count or "")
        local color = ITEM_QUALITY_COLORS[result.item.quality or 1]
        button.rim:SetVertexColor(color.r, color.g, color.b, 1)
        button:Show()
    end
end

function UI.RefreshItems()
    if not UI.frame or not Vault.db then return end
    local crafting = UI.source == "crafting"
    UI.satchel:SetShown(not crafting)
    UI.itemsScroll:SetShown(not crafting)
    UI.qualityButton:SetShown(not crafting)
    if UI.crafting then UI.crafting:SetShown(crafting) end
    if UI.professionButton then UI.professionButton:SetShown(crafting) end
    UI.searchHint:SetText(crafting and "Search recipes or professions" or "Search items or characters")
    if crafting and Vault.CraftingUI then Vault.CraftingUI.Refresh(); return end
    local results = Model.Find(Vault.db, UI.selected, UI.source, UI.query, UI.quality, UI.visibleKeys)
    UI.results = results
    UI.itemsChild:SetHeight(math.max(VIEW_HEIGHT, math.ceil(#results / COLUMNS) * CELL))
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
                message = "Visit a banker as " .. character.name .. " to save this bank."
            elseif UI.source == "mail" and character and not snapshot then
                message = "Open a mailbox as " .. character.name .. " to save their mail."
            elseif snapshot then message = "No items in " .. labels[UI.source]:lower() .. "."
            else message = "No saved items. Log into a character to save their bags." end
        end
        UI.empty:SetText(message)
    end
    local stackCount = 0
    for _, result in ipairs(results) do stackCount = stackCount + result.item.count end
    UI.resultCount:SetText(#results .. " stacks / " .. stackCount .. " items")
    if character and UI.source ~= "all" then
        local details = labels[UI.source] .. ": " .. Model.Age(snapshot and snapshot.updated, time())
        if snapshot and UI.source ~= "mail" then
            details = details .. " / " .. #snapshot.items .. "/" .. snapshot.capacity .. " slots used"
        end
        if snapshot and snapshot.partial then details = details .. " / More mail to load" end
        if snapshot and snapshot.money and snapshot.money > 0 then details = details .. " / Mail gold: " .. Model.Money(snapshot.money) end
        UI.freshness:SetText(details)
    elseif character then
        UI.freshness:SetText("Bags: " .. Model.Age(character.snapshots.bags and character.snapshots.bags.updated, time()) ..
            " / Bank: " .. Model.Age(character.snapshots.bank and character.snapshots.bank.updated, time()) ..
            " / Mail: " .. Model.Age(character.snapshots.mail and character.snapshots.mail.updated, time()))
    else
        UI.freshness:SetText("Saved items from all characters. Log into an owner to update them.")
    end
end

function UI.Refresh()
    if not UI.frame or not UI.frame:IsShown() or not Vault.db then return end
    local gold, count, stacks = Model.Totals(Vault.db)
    UI.totals:SetText("Total gold: " .. Model.Money(gold) .. "      Characters: " .. count)
    for _, button in ipairs(UI.rosterButtons) do button:Hide() end
    local characters = Model.Characters(Vault.db, UI.sort, UI.rosterFilters)
    UI.visibleKeys = {}
    for _, character in ipairs(characters) do UI.visibleKeys[character.key] = true end
    if UI.selected and not UI.visibleKeys[UI.selected] then UI.selected = nil end
    UI.rosterEmpty:SetShown(#characters == 0)
    for i, character in ipairs(characters) do
        local button = UI.rosterButtons[i]
        if not button then
            button = Button(UI.rosterChild, "", 215, 81, function(self)
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
            button.selection = button:CreateTexture(nil, "OVERLAY")
            button.selection:SetColorTexture(unpack(C.gold))
            button.selection:SetPoint("TOPLEFT", 1, -3)
            button.selection:SetPoint("BOTTOMLEFT", 1, 3)
            button.selection:SetWidth(3)
            UI.rosterButtons[i] = button
        end
        button.character = character
        button:SetPoint("TOPLEFT", 0, -(i - 1) * 88)
        button.name:SetText(character.name .. (character.key == Vault.currentKey and " *" or "") .. (character.remoteAccount and " +" or ""))
        button.name:SetTextColor(unpack(ClassColor(character)))
        button.meta:SetText(character.level .. " " .. (character.className or character.class) .. "\n" .. character.realm)
        button.money:SetText(Model.Money(character.money))
        DrawPortrait(button.face, character)
        button:SetBackdropColor(unpack(UI.selected == character.key and {0.38, 0.25, 0.14} or C.stone))
        button.selection:SetShown(UI.selected == character.key)
        button:Show()
    end
    UI.rosterChild:SetHeight(math.max(UI.rosterScroll:GetHeight(), #characters * 88))
    local filterCount = 0
    for _, value in pairs(UI.rosterFilters) do if value and value ~= "" then filterCount = filterCount + 1 end end
    UI.filterButton.label:SetText("Filters" .. (filterCount > 0 and " (" .. filterCount .. ")" or ""))
    local character = UI.selected and Vault.db.characters[UI.selected]
    if character then
        UI.name:SetText(character.name)
        UI.name:SetTextColor(unpack(ClassColor(character)))
        UI.details:SetText(character.level .. " " .. character.raceName .. " " .. character.className ..
            " / " .. character.realm .. " / " .. character.faction .. (character.remoteAccount and " / Linked account" or ""))
        UI.characterGold:SetText(Model.Money(character.money))
        DrawPortrait(UI.portrait, character)
    else
        UI.name:SetText("All characters")
        UI.name:SetTextColor(unpack(C.gold))
        UI.details:SetText("Choose a character or search by owner.")
        UI.characterGold:SetText("")
        UI.portrait.livePortrait:Hide(); UI.portrait.portrait:Show()
        UI.portrait.portrait:SetTexCoord(0, 1, 0, 1)
        UI.portrait.portrait:SetTexture(ART .. "Icon")
    end
    for key, button in pairs(UI.tabs) do
        button.label:SetTextColor(unpack(key == UI.source and C.gold or C.text))
        button:SetBackdropColor(unpack(key == UI.source and {0.38, 0.25, 0.14} or C.stone))
    end
    UI.RefreshItems()
end

function UI.Toggle()
    if not Vault.db then return end
    UI.Create()
    if UI.frame:IsShown() then UI.Close(); return end
    if not UI.hasOpened then UI.selected = Vault.currentKey; UI.hasOpened = true end
    UI.frame:Show()
    UI.ApplyPosition(); UI.Refresh(); UI.OpenEffect()
    UI.PlayOpeningSound()
end

function UI.RefreshSettings()
    if UI.settingsChecks then
        for key, control in pairs(UI.settingsChecks) do control:SetChecked(Vault.db.settings[key] ~= false) end
    end
    if UI.settingsSliders then
        UI.settingsSync = true
        for key, slider in pairs(UI.settingsSliders) do
            local value = Vault.db.settings[key] or slider.default
            if key == "soundVolume" and Vault.db.settings.sound == false then value = 0 end
            if key == "effectStrength" and Vault.db.settings.effects == false then value = 0 end
            slider:SetValue(value)
            slider.label:SetText(slider.title .. ": " .. math.floor(value * 100 + 0.5) .. "%")
        end
        UI.settingsSync = false
    end
end

function UI.Settings()
    if not UI.settingsFrame then
        local panel = Panel(UIParent, 435, 525, nil, "WarbandVaultForeverSettings")
        UI.settingsFrame = panel
        panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG"); panel:SetClampedToScreen(true)
        table.insert(UISpecialFrames, "WarbandVaultForeverSettings")
        Text(panel, "Settings", 22, C.gold):SetPoint("TOPLEFT", 22, -20)
        local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4); close:SetScript("OnClick", function() panel:Hide() end)
        UI.settingsChecks = {}
        for i, option in ipairs({{"minimap", "Show minimap shortcut"}, {"actionbar", "Show shortcut beside bags"},
            {"includeMail", "Include mailbox items in material checks"}}) do
            local key, label = option[1], option[2]
            local control = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            control:SetSize(28, 28); control:SetPoint("TOPLEFT", 22, -54 - (i - 1) * 34)
            Text(control, label, 12):SetPoint("LEFT", control, "RIGHT", 4, 0)
            control:SetScript("OnClick", function(self)
                Vault.db.settings[key] = self:GetChecked() and true or false
                if key == "minimap" then UI.minimap:SetShown(Vault.db.settings[key]) end
                if key == "actionbar" then UI.ActionBar() end
                UI.Refresh()
            end)
            UI.settingsChecks[key] = control
        end
        UI.settingsSliders = {}
        for i, definition in ipairs({{"scale", "Window scale", 0.65, 1.2, 1},
            {"soundVolume", "Opening sound", 0, 1, 0.8}, {"effectStrength", "Effects strength", 0, 1, 0.7}}) do
            local key, title = definition[1], definition[2]
            local slider = CreateFrame("Slider", nil, panel, "BackdropTemplate")
            slider:SetPoint("TOPLEFT", 30, -196 - (i - 1) * 73); slider:SetSize(285, 18)
            slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(definition[3], definition[4]); slider:SetValueStep(0.05)
            slider:SetObeyStepOnDrag(true)
            slider:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8})
            slider:SetBackdropColor(0.05, 0.03, 0.02, 1)
            slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
            slider.title, slider.default = title, definition[5]
            slider.label = Text(slider, "", 12, C.text, 370)
            slider.label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 10)
            slider:SetScript("OnValueChanged", function(self, value)
                if UI.settingsSync then return end
                value = math.floor(value * 20 + 0.5) / 20
                Vault.db.settings[key] = value
                self.label:SetText(title .. ": " .. math.floor(value * 100 + 0.5) .. "%")
                if key == "scale" and UI.frame then UI.ApplyPosition() end
                if key == "soundVolume" then Vault.db.settings.sound = value > 0 end
                if key == "effectStrength" then Vault.db.settings.effects = value > 0; UI.StopEffects() end
            end)
            UI.settingsSliders[key] = slider
        end
        Button(panel, "Test sound", 87, 28, UI.PlayOpeningSound):SetPoint("TOPRIGHT", -18, -261)
        if not (C_Sound and (C_Sound.PlaySoundWithOptions or C_Sound.PlaySound)) then
            UI.settingsSliders.soundVolume:EnableMouse(false)
            UI.settingsSliders.soundVolume:SetAlpha(0.5)
            Text(panel, "This client uses WoW's sound-effects volume.", 10, C.muted, 390):SetPoint("TOPLEFT", 30, -294)
        end
        Text(panel, "Set sound or effects to 0% to turn them off.", 11, C.muted, 385):SetPoint("TOPLEFT", 25, -387)
        Button(panel, "Account sync", 150, 30, function() Vault.SyncUI.Open() end):SetPoint("TOPLEFT", 25, -414)
        Button(panel, "Reset window", 124, 30, function()
            Vault.db.settings.position = nil; Vault.db.settings.scale = 1
            if UI.frame then UI.ApplyPosition() end
            UI.RefreshSettings()
        end):SetPoint("BOTTOMLEFT", 25, 23)
        Button(panel, "Done", 90, 30, function() panel:Hide() end):SetPoint("BOTTOMRIGHT", -25, 23)
        panel:Hide()
    end
    UI.RefreshSettings()
    UI.settingsFrame:SetShown(not UI.settingsFrame:IsShown())
end

function UI.ActionBar()
    if InCombatLockdown and InCombatLockdown() then return end
    local anchor = BagsBar or MainMenuBarBackpackButton
    if not anchor then return end
    if not UI.actionbar then
        local button = CreateFrame("Button", "WarbandVaultForeverBagButton", UIParent, "BackdropTemplate")
        button:SetSize(36, 36)
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonUp")
        button:SetBackdrop({edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 12})
        button:SetBackdropBorderColor(unpack(C.gold))
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 4, -4); icon:SetPoint("BOTTOMRIGHT", -4, 4)
        icon:SetTexture(ART .. "Icon")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        button:SetScript("OnClick", UI.Toggle)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Warband Vault", unpack(C.gold))
            GameTooltip:AddLine("Click to open saved inventories.", 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        UI.actionbar = button
    end
    local button = UI.actionbar
    button:SetParent(anchor)
    button:SetFrameLevel(anchor:GetFrameLevel() + 5)
    button:ClearAllPoints()
    local right = anchor:GetRight()
    local scale = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if right and UIParent:GetWidth() - right * scale > 44 * scale then
        button:SetPoint("LEFT", anchor, "RIGHT", 5, 0)
    else
        button:SetPoint("RIGHT", anchor, "LEFT", -5, 0)
    end
    button:SetShown(Vault.db.settings.actionbar ~= false)
end

function UI.Minimap()
    local button = CreateFrame("Button", "WarbandVaultForeverMinimapButton", Minimap)
    button:SetSize(30, 30)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    local function Position()
        local angle = math.rad(Vault.db.settings.minimapAngle or 225)
        local radius = Minimap:GetWidth() / 2 + 7
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
    end
    Position()
    button:SetFrameStrata("MEDIUM")
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT",3,-3); texture:SetPoint("BOTTOMRIGHT",-3,3)
    texture:SetTexture(ART .. "Icon")
    local mask=button:CreateMaskTexture(nil,"ARTWORK")
    mask:SetAllPoints(texture); mask:SetTexture(ART .. "CircleMask")
    texture:AddMaskTexture(mask)
    local border=button:CreateTexture(nil,"OVERLAY")
    border:SetAllPoints(); border:SetTexture(ART .. "SlotRing")
    button.icon=texture; button.mask=mask; button.border=border
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
        GameTooltip:AddLine("Click to open saved inventories.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move around the minimap.", unpack(C.muted))
        GameTooltip:AddLine("/wvf minimap to hide this button", unpack(C.muted))
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetShown(Vault.db.settings.minimap ~= false)
    UI.minimap = button
end
