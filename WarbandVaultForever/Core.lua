-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local addonName, Vault = ...
local frame = CreateFrame("Frame")
local pending, pendingItems = false, false
Vault.version = "0.3.0-alpha.1"

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd36bWarband Vault:|r " .. message)
end

local function Queue()
    if pending then return end
    pending = true
    C_Timer.After(0.35, function()
        pending = false
        Vault.Scanner.Refresh()
    end)
end

local function Slash(message)
    message = strtrim(message or ""):lower()
    if message == "scan" then
        Vault.Scanner.Refresh()
        Print("Bags and equipment saved. Visit a bank or mailbox to update those items.")
    elseif message == "minimap" then
        Vault.db.settings.minimap = not (Vault.db.settings.minimap ~= false)
        Vault.UI.minimap:SetShown(Vault.db.settings.minimap)
    elseif message == "resetui" then
        Vault.db.settings.position = nil
        Vault.db.settings.scale = 1
        if Vault.UI.frame then Vault.UI.ApplyPosition() end
        Print("Window position and scale reset.")
    elseif message == "actionbar" then
        Vault.db.settings.actionbar = Vault.db.settings.actionbar == false
        Vault.UI.ActionBar()
    elseif message == "settings" then
        Vault.UI.Settings()
    elseif message == "sync" then
        Vault.SyncUI.Open()
    elseif message == "crafting" then
        local ok,message=Vault.ProfessionWindow.Open()
        if not ok then Print(message) end
    elseif message == "sound" or message == "effects" then
        Vault.db.settings[message] = Vault.db.settings[message] == false
        if message == "effects" then Vault.UI.StopEffects() end
        Vault.UI.RefreshSettings()
        Print(message .. ": " .. (Vault.db.settings[message] and "on" or "off"))
    elseif message == "help" then
        Print("/wvf opens the vault. /wvf settings opens settings. /wvf crafting opens saved recipes in an open profession window. /wvf scan saves items. /wvf minimap or actionbar toggles a shortcut. /wvf sound or effects toggles sound or motion. /wvf resetui resets the window.")
    else
        Vault.UI.Toggle()
    end
end

local function Initialize()
    local db, err = Vault.Model.Open(WarbandVaultForeverDB)
    if not db then Print(err); return end
    WarbandVaultForeverDB, Vault.db = db, db
    SLASH_WARBANDVAULTFOREVER1 = "/wvf"
    SLASH_WARBANDVAULTFOREVER2 = "/warbandvault"
    SlashCmdList.WARBANDVAULTFOREVER = Slash
    BINDING_HEADER_WVF_HEADER = "Warband Vault Forever"
    BINDING_NAME_WVF_TOGGLE = "Open character vault"
    WarbandVaultForever_Toggle = Vault.UI.Toggle
    Vault.UI.Minimap()
    Vault.UI.ActionBar()
    if Vault.ProfessionWindow then Vault.ProfessionWindow.Attach() end
    if Vault.Sync then Vault.Sync.Initialize() end
    Print("Type /wvf to open.")
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == addonName then Initialize() end
        if Vault.db then Vault.UI.ActionBar(); if Vault.ProfessionWindow then Vault.ProfessionWindow.Attach() end end
        return
    end
    if not Vault.db then return end
    if event == "CHAT_MSG_ADDON" then Vault.Sync.Receive(...); return end
    if event == "BANKFRAME_OPENED" then
        Vault.Scanner.bankOpen = true
        Queue()
    elseif event == "BANKFRAME_CLOSED" then
        -- Bag events before close are the last authoritative bank snapshot.
        -- Reading after close could replace a valid bank with unavailable slots.
        Vault.Scanner.bankOpen = false
    elseif event == "MAIL_SHOW" then
        Vault.Scanner.mailOpen = true
        Queue()
    elseif event == "MAIL_CLOSED" then
        Vault.Scanner.mailOpen = false
    elseif event == "MAIL_INBOX_UPDATE" then
        Queue()
    elseif event == "PLAYER_LOGOUT" then
        Vault.Scanner.Refresh()
    elseif event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then
        Vault.Professions.open, Vault.Professions.craft = true, event == "CRAFT_SHOW"
        if Vault.ProfessionWindow then Vault.ProfessionWindow.Attach() end
        Queue()
    elseif event == "TRADE_SKILL_CLOSE" or event == "CRAFT_CLOSE" then
        Vault.Professions.open = false
        Vault.UI.Refresh()
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local id, success = ...
        if success then
            Vault.Scanner.ResolveItem(id)
            Queue()
            if not pendingItems then
                pendingItems = true
                C_Timer.After(0.3, function() pendingItems = false; Vault.UI.Refresh() end)
            end
        end
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYERBANKSLOTS_CHANGED" then
        Vault.Scanner.Bank()
        Queue()
    elseif event == "PLAYER_MONEY" then
        Vault.Scanner.Identity()
        Vault.UI.Refresh()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        Vault.UI.ActionBar()
        C_Timer.After(1, Queue)
    elseif event == "PLAYER_REGEN_ENABLED" then
        Vault.UI.ActionBar()
        if Vault.ProfessionWindow then Vault.ProfessionWindow.Attach() end
    else
        Queue()
    end
end)

for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT",
    "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP",
    "ZONE_CHANGED_NEW_AREA", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED",
    "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "ITEM_DATA_LOAD_RESULT", "PLAYER_REGEN_ENABLED",
    "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_UPDATE", "TRADE_SKILL_LIST_UPDATE",
    "TRADE_SKILL_DATA_SOURCE_CHANGED", "NEW_RECIPE_LEARNED", "SKILL_LINES_CHANGED", "CRAFT_SHOW", "CRAFT_CLOSE", "CRAFT_UPDATE", "CHAT_MSG_ADDON"}) do
    pcall(frame.RegisterEvent, frame, event)
end
