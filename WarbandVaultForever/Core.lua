-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local addonName, Vault = ...
local frame = CreateFrame("Frame")
local pending, pendingItems = false, false
Vault.version = "0.1.0-alpha.1"

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
        Print("Bags and equipment updated. Open a bank or mailbox to refresh those records.")
    elseif message == "minimap" then
        Vault.db.settings.minimap = not (Vault.db.settings.minimap ~= false)
        Vault.UI.minimap:SetShown(Vault.db.settings.minimap)
    elseif message == "resetui" then
        Vault.db.settings.position = nil
        Vault.db.settings.scale = 1
        if Vault.UI.frame then Vault.UI.ApplyPosition() end
        Print("Window position and scale reset.")
    elseif message == "help" then
        Print("/wvf - open vault; /wvf scan - refresh; /wvf minimap - toggle icon; /wvf resetui - reset window.")
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
    Print("Ready. Type /wvf to browse your characters.")
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == addonName then Initialize() end
        return
    end
    if not Vault.db then return end
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
        C_Timer.After(1, Queue)
    else
        Queue()
    end
end)

for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT",
    "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP",
    "ZONE_CHANGED_NEW_AREA", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED",
    "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "ITEM_DATA_LOAD_RESULT"}) do
    frame:RegisterEvent(event)
end
