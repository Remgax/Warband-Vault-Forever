-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
Vault.Scanner = {}
local Scanner, Model = Vault.Scanner, Vault.Model
local container = C_Container

local function Item(id, link, icon, count, quality, bag, slot)
    if not id then return nil end
    local name, _, cachedQuality, _, _, kind, subkind, _, _, cachedIcon = C_Item.GetItemInfo(id)
    if not name and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return {id = id, link = link, icon = icon or cachedIcon or 134400,
        name = name, count = count or 1,
        quality = (quality and quality >= 0) and quality or cachedQuality or 1,
        kind = (kind or "") .. " " .. (subkind or ""), bag = bag, slot = slot}
end

function Scanner.Identity()
    if not Vault.db or not UnitGUID("player") then return end
    local name, surname = UnitFullName("player")
    if not name or name == "" then return end
    if surname and surname ~= "" then name = name .. " " .. surname end
    -- Forever returns the surname as UnitFullName's second result. The
    -- server/ruleset label comes from GetRealmName, never from the name.
    local ruleset = GetRealmName()
    local className, class = UnitClass("player")
    local raceName, race = UnitRace("player")
    local key = tostring(GetCurrentRegion()) .. ":" .. UnitGUID("player")
    Vault.currentKey = key
    local character = Model.Character(Vault.db, key, {
        name = name, ruleset = ruleset ~= "" and ruleset or nil, guid = UnitGUID("player"),
        class = class, className = className, race = race, raceName = raceName,
        sex = UnitSex("player"), level = UnitLevel("player"),
        faction = UnitFactionGroup("player"), zone = GetRealZoneText(),
        money = GetMoney(), lastSeen = time(),
    })
    character.remoteAccount = nil
    character.realm = nil
    return character
end

local function Containers(character, source, bags)
    local items, capacity = {}, 0
    for _, bag in ipairs(bags) do
        local slots = container.GetContainerNumSlots(bag) or 0
        capacity = capacity + slots
        for slot = 1, slots do
            local info = container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local entry = Item(info.itemID, info.hyperlink, info.iconFileID,
                    info.stackCount, info.quality, bag, slot)
                entry.bound = info.isBound
                if entry.bound == nil and C_Item.IsBound then entry.bound = C_Item.IsBound({bagID = bag, slotIndex = slot}) end
                items[#items + 1] = entry
            elseif C_Item.DoesItemExist and C_Item.DoesItemExist({bagID = bag, slotIndex = slot}) then
                local id = C_Item.GetItemID({bagID = bag, slotIndex = slot})
                if id and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
                return -- Keep the previous snapshot until uncached slots become readable.
            end
        end
    end
    if capacity == 0 then return end
    Model.Save(character, source, items, capacity, time())
end

function Scanner.Bags()
    local character = Scanner.Identity()
    if not character then return end
    local bags = {0, 1, 2, 3, 4}
    if Enum.BagIndex.ReagentBag then bags[#bags + 1] = Enum.BagIndex.ReagentBag end
    if Enum.BagIndex.Keyring then bags[#bags + 1] = Enum.BagIndex.Keyring end
    Containers(character, "bags", bags)
end

function Scanner.Bank()
    if not Scanner.bankOpen then return end
    local character = Scanner.Identity()
    if not character then return end
    local bags = {}
    -- Forever uses character bank tabs. The legacy branch is only for older clients.
    if C_Bank and C_Bank.FetchPurchasedBankTabData and Enum.BagIndex.CharacterBankTab_1 then
        local tabs = C_Bank.FetchPurchasedBankTabData(Enum.BankType.Character)
        if not tabs then return end -- Unavailable data must never erase an existing snapshot.
        for _, tab in ipairs(tabs) do
            if tab.ID then bags[#bags + 1] = tab.ID end
        end
        if #bags == 0 then return end
    else
        bags = {Enum.BagIndex.Bank or -1}
        for bag = 5, 11 do bags[#bags + 1] = bag end
    end
    Containers(character, "bank", bags)
end

function Scanner.Mail()
    if not Scanner.mailOpen then return end
    local character = Scanner.Identity()
    if not character then return end
    local loaded, total = GetInboxNumItems()
    local items, money, codMoney = {}, 0, 0
    for mail = 1, loaded do
        local _, _, _, _, attachedMoney, cod, days = GetInboxHeaderInfo(mail)
        money = money + (attachedMoney or 0)
        codMoney = codMoney + (cod or 0)
        for slot = 1, (ATTACHMENTS_MAX_RECEIVE or 16) do
            local _, id, icon, count, quality = GetInboxItem(mail, slot)
            if id then
                local entry = Item(id, GetInboxItemLink(mail, slot), icon, count, quality, mail, slot)
                entry.expires = days and time() + days * 86400
                entry.cod = cod and cod > 0 or false
                items[#items + 1] = entry
            end
        end
    end
    Model.Save(character, "mail", items, #items, time())
    character.snapshots.mail.money = money
    character.snapshots.mail.codMoney = codMoney
    character.snapshots.mail.partial = loaded < (total or loaded)
end

function Scanner.Refresh()
    if not Vault.db then return end
    Scanner.Bags()
    Scanner.Bank()
    Scanner.Mail()
    if Vault.Professions then Vault.Professions.Skills(); Vault.Professions.Scan() end
    if Vault.UI then Vault.UI.Refresh() end
    if Vault.ProfessionWindow then Vault.ProfessionWindow.Refresh() end
end

function Scanner.ResolveItem(id)
    local name, link, quality, _, _, kind, subkind, _, _, icon = C_Item.GetItemInfo(id)
    if not name then return end
    for _, character in pairs(Vault.db.characters) do
        for _, snapshot in pairs(character.snapshots) do
            for _, item in ipairs(snapshot.items) do
                if item.id == id then
                    item.name, item.quality = name, quality
                    item.link = item.link or link
                    item.icon = icon or item.icon
                    item.kind = (kind or "") .. " " .. (subkind or "")
                end
            end
        end
    end
end
