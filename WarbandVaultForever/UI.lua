-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
Vault.UI = {}
local UI, Model = Vault.UI, Vault.Model
local ART = "Interface\\AddOns\\WarbandVaultForever\\Assets\\"
local Skins = Vault.Skins
local C = Skins.colors
local labels = {all = "All items", bags = "Bags", bank = "Bank", mail = "Mailbox"}
local COLUMNS, CELL, VIEW_HEIGHT = 10, 60, 210
UI.source, UI.sort, UI.query = "bags", "name", ""

local function Panel(parent, width, height, color, name)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    Skins.Register(frame, color==C.inset and "inset" or "panel")
    return frame
end

local function Text(parent, text, size, color, width)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(STANDARD_TEXT_FONT, size or 12, "")
    font:SetTextColor(unpack(color or C.text))
    Skins.Font(font, color or C.text)
    font:SetJustifyH("LEFT")
    font:SetText(text or "")
    if width then font:SetWidth(width) end
    return font
end

local function Button(parent, text, width, height, action)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height or 30)
    Skins.Register(button, "button")
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    button.label = Text(button, text, 12)
    button.label:SetPoint("CENTER")
    button.label:SetWidth(width - 12); button.label:SetWordWrap(false); button.label:SetJustifyH("CENTER")
    button:SetScript("OnClick", action)
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.gold)) end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(Skins.Current().buttonBorder))
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
    Skins.Tint(background,C.inset)
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
    Skins.Tint(rim,C.gold)
    backing.mask=mask; backing.rim=rim
    backing.portrait = texture
    return backing
end

UI.widgets = {Panel = Panel, Text = Text, Button = Button, Scroll = Scroll, colors = C}
UI.rosterFilters = {}

function UI.FilterMenu(anchor, choices, selectChoice)
    if not UI.filterMenu then
        local menu = Panel(UIParent, 230, 300, nil, "WarbandVaultForeverFilterMenu")
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel(100)
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
        elseif field == "ruleset" then
            local value = Model.Ruleset(character); values[value] = value
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
    UI.rosterScroll:SetHeight((UI.rosterHeight or 523) - top - 16)
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
            GameTooltip:AddDoubleLine(owner.character.name .. " - " .. Model.Ruleset(owner.character),
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
    if strength <= 0 or Skins.Current().compact then return end
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

local function SkinItem(button)
    local compact = Skins.Current().compact == true
    local round = not compact
    if button.round ~= round then
        if round then button.icon:AddMaskTexture(button.mask)
        else button.icon:RemoveMaskTexture(button.mask) end
        button.round = round
    end
    local size, inset = compact and 38 or 48, compact and 2 or 4
    button:SetSize(size,size)
    button.icon:ClearAllPoints()
    button.icon:SetPoint("TOPLEFT",inset,-inset); button.icon:SetPoint("BOTTOMRIGHT",-inset,inset)
    button.pocket:SetTexture(compact and "Interface\\Buttons\\UI-EmptySlot-Disabled" or ART.."CircleMask")
    button.rim:SetShown(round)
    button:SetBackdrop(compact and {bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1} or nil)
    button.glow:SetTexture(compact and "Interface\\Buttons\\ButtonHilight-Square" or ART.."SlotGlow")
    button.glow:SetSize(compact and 42 or 72,compact and 42 or 72)
end

function UI.ApplySkin(id)
    id = id or Vault.db.settings.skin
    Skins.Apply(id)
    local compact = Skins.Current().compact == true
    COLUMNS, CELL, VIEW_HEIGHT = compact and 16 or 10, compact and 44 or 60, compact and 260 or 210
    if UI.frame then
        UI.StopEffects()
        if not compact then UI.frame:SetBackdropBorderColor(unpack(C.gold)) end
        UI.frame:SetHeight(compact and 660 or 760)
        UI.header:SetHeight(compact and 50 or 113)
        UI.headerArt:SetShown(not compact); UI.headerIcon:SetShown(not compact); UI.headerSubtitle:SetShown(not compact)
        UI.headerTitle:ClearAllPoints(); UI.headerTitle:SetPoint("TOPLEFT",compact and 20 or 106,compact and -14 or -26)
        UI.headerTitle:SetFont("Fonts\\FRIZQT__.TTF",compact and 21 or 29,"")
        UI.totals:ClearAllPoints(); UI.totals:SetPoint("TOPLEFT",20,compact and -67 or -132)
        UI.rosterHeight = compact and 500 or 523
        UI.roster:ClearAllPoints(); UI.roster:SetPoint("TOPLEFT",16,compact and -92 or -161)
        UI.roster:SetHeight(UI.rosterHeight)
        UI.main:ClearAllPoints(); UI.main:SetPoint("TOPLEFT",290,compact and -92 or -161)
        UI.main:SetHeight(UI.rosterHeight)
        UI.satchel:SetShown(not compact)
        UI.itemsScroll:ClearAllPoints()
        UI.itemsScroll:SetPoint("TOPLEFT",UI.main,"TOPLEFT",compact and 20 or 64,compact and -174 or -244)
        UI.itemsScroll:SetSize(compact and 704 or 610,VIEW_HEIGHT)
        UI.itemsChild:SetWidth(compact and 704 or 610)
        UI.empty:SetWidth(compact and 680 or 620)
        UI.itemsScroll:SetVerticalScroll(0)
        UI.RosterLayout(); UI.ApplyPosition()
        UI.RefreshItems(); UI.Refresh()
    end
    if Vault.CraftingUI then Vault.CraftingUI.Refresh() end
    if UI.skinLabel then UI.skinLabel:SetText("Skin: "..Skins.Current().name) end
end

function UI.SelectSkin(id)
    if not Skins.Valid(id) then return false end
    Vault.db.settings.skin = id
    UI.ApplySkin(id)
    return true
end

function UI.SkinPicker()
    if not UI.skinFrame then
        local panel = Panel(UIParent,770,345,nil,"WarbandVaultForeverSkins")
        UI.skinFrame = panel
        panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG"); panel:SetFrameLevel(210)
        panel:SetClampedToScreen(true)
        table.insert(UISpecialFrames,"WarbandVaultForeverSkins")
        Text(panel,"Choose your skin",22,C.gold):SetPoint("TOPLEFT",22,-20)
        Text(panel,"Preview a style. You can change it anytime in Settings.",12,C.muted):SetPoint("TOPLEFT",22,-52)
        UI.skinCards = {}
        for i, definition in ipairs(Skins.list) do
            local skin = definition
            local card = CreateFrame("Button",nil,panel,"BackdropTemplate")
            card:SetSize(232,188); card:SetPoint("TOPLEFT",22+(i-1)*247,-82)
            card:EnableMouse(true); card:RegisterForClicks("LeftButtonUp")
            card:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
            Skins.Style(card,"panel",skin.id)
            local title = card:CreateFontString(nil,"OVERLAY")
            title:SetFont(STANDARD_TEXT_FONT,14,""); title:SetText(skin.name)
            title:SetTextColor(unpack(skin.colors.gold)); title:SetPoint("TOPLEFT",12,-13)
            local description = card:CreateFontString(nil,"OVERLAY")
            description:SetFont(STANDARD_TEXT_FONT,12,""); description:SetText(skin.description)
            description:SetTextColor(unpack(skin.colors.text)); description:SetJustifyH("LEFT")
            description:SetWidth(205); description:SetWordWrap(true); description:SetPoint("TOPLEFT",12,-112)
            local preview = card:CreateTexture(nil,"BACKGROUND")
            preview:SetPoint("TOPLEFT",9,-40); preview:SetSize(214,61)
            preview:SetTexture(skin.compact and skin.background or ART.."Satchel")
            if not skin.compact then preview:SetTexCoord(0,1,0.2,0.8) end
            for slot=1,4 do
                local icon = card:CreateTexture(nil,"ARTWORK")
                icon:SetSize(32,32); icon:SetPoint("TOPLEFT",16+(slot-1)*51,-55)
                icon:SetTexture(({"Interface\\Icons\\INV_Misc_Herb_01","Interface\\Icons\\INV_Potion_51",
                    "Interface\\Icons\\INV_Misc_Gem_Ruby_01","Interface\\Icons\\INV_Misc_Bag_08"})[slot])
                if not skin.compact then
                    local mask=card:CreateMaskTexture(nil,"ARTWORK")
                    mask:SetTexture(ART.."CircleMask"); mask:SetAllPoints(icon); icon:AddMaskTexture(mask)
                end
            end
            card:SetScript("OnClick",function()
                UI.skinChoice = skin.id; UI.ApplySkin(skin.id)
                for _, option in ipairs(Skins.list) do
                    UI.skinCards[option.id]:SetBackdropBorderColor(unpack(option.id==skin.id and option.colors.gold or option.border))
                end
            end)
            UI.skinCards[skin.id] = card
        end
        UI.skinUse = Button(panel,"Use selected skin",170,30,function()
            UI.SelectSkin(UI.skinChoice); panel:Hide()
        end)
        UI.skinUse:SetPoint("BOTTOMRIGHT",-22,22)
        UI.skinCancel = Button(panel,"Cancel",100,30,function() panel:Hide() end)
        UI.skinCancel:SetPoint("BOTTOMLEFT",22,22)
        local close = CreateFrame("Button",nil,panel,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() panel:Hide() end)
        panel:Hide()
        panel:SetScript("OnHide",function()
            -- Dismissing the welcome picker keeps the original and completes
            -- onboarding, so it does not interrupt every subsequent login.
            if not Skins.Valid(Vault.db.settings.skin) then Vault.db.settings.skin="satchel" end
            UI.ApplySkin(Vault.db.settings.skin)
        end)
    end
    UI.skinChoice = Skins.Valid(Vault.db.settings.skin) and Vault.db.settings.skin or "satchel"
    for _, skin in ipairs(Skins.list) do
        UI.skinCards[skin.id]:SetBackdropBorderColor(unpack(skin.id==UI.skinChoice and skin.colors.gold or skin.border))
    end
    UI.skinFrame:Show()
end

function UI.FirstLogin()
    if Skins.Valid(Vault.db.settings.skin) or InCombatLockdown and InCombatLockdown() then return end
    if UI.skinFrame and UI.skinFrame:IsShown() then return end
    UI.SkinPicker()
end

local helpText = [[GETTING STARTED
Log into each character once to record bags and wallet gold. Open that character's bank and mailbox to record them. Offline records are snapshots, not live inventory. Saved times show their age. Log out normally or use /reload so WoW writes the data to disk.

FINDING ITEMS
Choose All characters or a character, then All items, Bags, Bank or Mailbox. Search by item name, ID, full character name or ruleset; combine quality and character filters. Hover for details and recorded owners. Shift-click to link an item. Equipped gear is not included in these storage views.

PROFESSIONS AND MATERIALS
Open each profession to save learned recipes. On legacy windows, clear filters and expand categories. Warband recipes browses saved recipes; Show recipe returns your own recipe to the native window. Warband materials shows bags, banks and eligible alt supplies for the selected quantity. Collect stored materials first; craft using the game's Create controls. Soulbound alt items, other or unknown rulesets, other factions, expired mail and COD attachments cannot supply a transfer.

AUCTIONATOR
Materials can create a shopping list for missing quantities when Auctionator is available. Estimates use cached prices and may be partial or stale. This addon never buys items automatically.

ACCOUNT SYNC
In Settings > Account sync, create a private code, enter it on the other account, then approve the request on the account that created the code. Both accounts need matching addon versions and must be reachable on the same ruleset and faction. Sharing is optional; messages are authenticated, not encrypted. Keep pairing codes private. Unlink removes imported records and preserves your own characters.

SETTINGS AND DATA
Choose Original Satchel, Classic Blizzard or Minimal Dark on your first login or in Settings > Choose skin. Click a card to preview, then Use selected skin to save it for this account. Cancel restores your saved style; dismissing the first welcome keeps Original Satchel. Simple skins use compact square items without the bag animation. Skin changes keep your inventories, filters and other preferences.

Settings also controls scale, shortcuts, sound and effects. Clear saved records removes all local and imported character snapshots, gold, recipes and the cached shopping plan after confirmation. Preferences and pairing are kept; sync is paused. Later game events can record the current character again. Enable sync yourself to resume imports. Old records without a known ruleset need a fresh login before their supplies can be treated as transferable.

COMMANDS
/wvf opens or closes the vault; /wvf scan refreshes accessible records; /wvf settings opens Settings; /wvf sync opens account sync; /wvf crafting opens saved recipes in an open profession window; /wvf minimap and /wvf actionbar toggle shortcuts; /wvf sound and /wvf effects toggle sound and motion; /wvf resetui resets position and scale; /wvf help opens this guide.

LIMITS AND TROUBLESHOOTING
Only the logged-in character can be scanned. Gold totals count wallets; mailbox gold is separate. Guild banks, auctions and currencies are not tracked. If something is missing, clear filters, log into its owner and visit their bank or mailbox. Report addon version, client build, reproduction steps and Lua errors; never publish pairing codes or private SavedVariables.]]

local creditsText = [[Warband Vault Forever
Created by Remgax.

CODE AND ORIGINAL ARTWORK
Copyright 2026 Remgax. Distributed under GNU GPLv3 (GPL-3.0-only). The repository and release archive include the license. Original generated artwork is included under the same license.

SHA256 AND HMAC
Libs/SHA.lua adapts pure_lua_SHA v12 by Egor Skriptunoff, copyright 2018-2022, under the MIT license. The original license is retained in that file.

OPTIONAL INTEGRATIONS
Auctionator provides shopping-list and cached-price APIs. ForeverCore profession tabs are used when available. Neither addon is required for inventory tracking or saved recipe browsing.

WORLD OF WARCRAFT
Blizzard game assets are referenced at runtime and are not redistributed with this addon. This is an independent addon project.

SOURCE AND BUG REPORTS
https://github.com/Remgax/Warband-Vault-Forever]]

local function Info(title, text)
    if not UI.infoFrame then
        local panel = Panel(UIParent, 650, 550, nil, "WarbandVaultForeverHelp")
        UI.infoFrame = panel
        panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG"); panel:SetClampedToScreen(true)
        table.insert(UISpecialFrames, "WarbandVaultForeverHelp")
        UI.infoTitle = Text(panel, "", 22, C.gold)
        UI.infoTitle:SetPoint("TOPLEFT", 22, -20)
        local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4); close:SetScript("OnClick", function() panel:Hide() end)
        UI.infoScroll, UI.infoChild = Scroll(panel, 22, -64, 582, 410)
        UI.infoText = Text(UI.infoChild, "", 12, C.text, 574)
        UI.infoText:SetPoint("TOPLEFT"); UI.infoText:SetWordWrap(true)
        Button(panel, "Done", 90, 30, function() panel:Hide() end):SetPoint("BOTTOMRIGHT", -22, 20)
    end
    UI.infoTitle:SetText(title); UI.infoText:SetText(text)
    UI.infoChild:SetHeight(math.max(410, UI.infoText:GetStringHeight() + 20))
    UI.infoScroll:SetVerticalScroll(0); UI.infoFrame:Show()
end

function UI.Help()
    Info("Help", helpText)
end

function UI.Credits()
    Info("Credits", creditsText)
end

function UI.RecordsCleared()
    UI.selected = nil; UI.results = {}; UI.visibleKeys = {}
    if UI.filterMenu then UI.filterMenu:Hide() end
    if Vault.Shopping then
        Vault.Shopping.result = nil
        if Vault.Shopping.frame then Vault.Shopping.frame:Hide() end
    end
    if Vault.CraftingUI then
        Vault.CraftingUI.character = nil; Vault.CraftingUI.selected = nil
        Vault.CraftingUI.Refresh()
    end
    if Vault.ProfessionWindow then Vault.ProfessionWindow.Refresh() end
    UI.Refresh()
end

function UI.ConfirmClear()
    if not UI.clearFrame then
        local panel = Panel(UIParent, 520, 260, nil, "WarbandVaultForeverClear")
        UI.clearFrame = panel
        panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG"); panel:SetFrameLevel(200)
        panel:SetClampedToScreen(true)
        table.insert(UISpecialFrames, "WarbandVaultForeverClear")
        Text(panel, "Clear saved records?", 22, C.gold):SetPoint("TOPLEFT", 22, -20)
        Text(panel, "Remove ALL local and imported character inventories, gold, recipes and the cached shopping plan?\n\nPreferences and pairing are kept. Account sync will pause. Future game events can record the current character again. This cannot be undone.", 12, C.text, 470):SetPoint("TOPLEFT", 22, -64)
        UI.clearAccept = Button(panel, "Clear saved records", 180, 30, function()
            panel:Hide(); Vault.ClearRecords()
        end)
        UI.clearAccept:SetPoint("BOTTOMLEFT", 22, 22)
        UI.clearCancel = Button(panel, "Cancel", 100, 30, function() panel:Hide() end)
        UI.clearCancel:SetPoint("BOTTOMRIGHT", -22, 22)
    end
    UI.clearFrame:Show()
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
    UI.headerArt = art
    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ART .. "Icon")
    icon:SetSize(72, 72)
    icon:SetPoint("LEFT", 18, 0)
    UI.headerIcon = icon
    local title = Text(header, "Warband Vault", 29, C.gold)
    title:SetFont("Fonts\\FRIZQT__.TTF", 29, "")
    title:SetPoint("TOPLEFT", 106, -26)
    UI.headerTitle = title
    UI.headerSubtitle = Text(header, "Forever", 13, C.muted)
    UI.headerSubtitle:SetPoint("TOPLEFT", 108, -65)
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
    for i, definition in ipairs({{"class", "Any class"}, {"profession", "Any profession"}, {"ruleset", "Any ruleset"}, {"faction", "Any faction"}}) do
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
    local tabKeys = {"all", "bags", "bank", "mail"}
    for i, key in ipairs(tabKeys) do
        local source = key
        local button = Button(main, labels[key], 172, 30, function()
            UI.source = source; UI.itemsScroll:SetVerticalScroll(0); UI.Refresh()
        end)
        button:SetPoint("TOPLEFT", 14 + (i - 1) * 183, -80)
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

    UI.helpButton = Button(f, "Help", 64, 30, UI.Help)
    UI.helpButton:SetPoint("BOTTOMLEFT", 20, 22)
    UI.creditsButton = Button(f, "Credits", 76, 30, UI.Credits)
    UI.creditsButton:SetPoint("BOTTOMLEFT", 92, 22)
    Text(f, "Hover for details. Shift-click to link.", 11, C.muted, 270):SetPoint("BOTTOMLEFT", 182, 31)
    Button(f, "Refresh", 100, 30, function() Vault.Scanner.Refresh() end):SetPoint("BOTTOMRIGHT", -22, 22)
    f:Hide()
    UI.ApplySkin()
end

function UI.ApplyPosition()
    local f = UI.frame
    local fit = math.min(UIParent:GetWidth() / 1100, UIParent:GetHeight() / (f:GetHeight()+40))
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
    -- Reuse only the viewport plus two rows across either slot size.
    local rows = math.ceil(VIEW_HEIGHT / CELL) + 2
    for i = first, math.min(first + COLUMNS * rows - 1, #results) do
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
            button.round = true
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
        SkinItem(button)
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
        button:SetBackdropBorderColor(color.r,color.g,color.b,1)
        button:Show()
    end
end

function UI.RefreshItems()
    if not UI.frame or not Vault.db then return end
    if UI.source == "crafting" then UI.source = "bags" end
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
        button.meta:SetText(character.level .. " " .. (character.className or character.class) .. "\n" .. Model.Ruleset(character))
        button.money:SetText(Model.Money(character.money))
        DrawPortrait(button.face, character)
        button:SetBackdropColor(unpack(UI.selected == character.key and C.selected or C.stone))
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
            " / " .. Model.Ruleset(character) .. " / " .. character.faction .. (character.remoteAccount and " / Linked account" or ""))
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
        button:SetBackdropColor(unpack(key == UI.source and C.selected or C.stone))
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
        local panel = Panel(UIParent, 435, 590, nil, "WarbandVaultForeverSettings")
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
        UI.clearButton = Button(panel, "Clear saved records", 205, 30, UI.ConfirmClear)
        UI.clearButton:SetPoint("TOPRIGHT", -25, -414)
        UI.skinLabel = Text(panel,"Skin: "..Skins.Current().name,12,C.text,240)
        UI.skinLabel:SetPoint("TOPLEFT",25,-466)
        UI.skinButton = Button(panel,"Choose skin",120,30,UI.SkinPicker)
        UI.skinButton:SetPoint("TOPRIGHT",-25,-454)
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
    Skins.Tint(border,C.gold)
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
