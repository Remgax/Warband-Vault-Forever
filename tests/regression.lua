-- This harness exercises data and event behavior, not Blizzard's rendering engine.
local root = ...
local Vault = {}
local passed = 0
local function check(condition, message)
    assert(condition, message)
    passed = passed + 1
end
local function loadModule(name)
    assert(loadfile(root .. "/WarbandVaultForever/" .. name .. ".lua"))("WarbandVaultForever", Vault)
end
loadModule("Model")
local M = Vault.Model
local db = M.Open()
Vault.db = db
local a = M.Character(db, "1:one", {name="Aeris", ruleset="PvE", money=10123})
local b = M.Character(db, "1:two", {name="Borin", ruleset="PvP", money=20234})
M.Save(a, "bags", {{id=1, name="Peacebloom", count=12, quality=1, slot=1}}, 16, 1000)
M.Save(b, "bank", {{id=1, name="Peacebloom", count=8, quality=1, slot=1},
    {id=2, name="Epic Blade", count=1, quality=4, slot=2}}, 28, 900)
local gold, characters, stacks = M.Totals(db)
check(gold == 30357 and characters == 2 and stacks == 3, "Account totals aggregate snapshots")
check(#M.Find(db, nil, "all", "peace", nil) == 2, "Cross-character search")
check(#M.Find(db, a.key, "bank", "", nil) == 0, "Unrecorded bank is empty without inventing data")
check(#M.Find(db, nil, "all", "BORIN", nil) == 2, "Owner search is case insensitive")
check(#M.Find(db, nil, "all", "PvP", nil) == 2, "Ruleset search")
check(#M.Find(db, nil, "all", "2", nil) == 1, "Item ID search")
check(#M.Find(db, nil, "all", "[", nil) == 0, "Search uses literal text, not Lua patterns")
check(#M.Find(db, nil, "all", "", 4) == 1, "Quality filter")
check(M.Find(db, nil, "all", "", nil)[1].item.id == 2, "High-quality items sort first")
check(M.Characters(db, "gold")[1].key == b.key, "Character gold sort")
check(M.Owners(db, 1)[2].count == 8, "Ownership counts use all locations")
check(M.Money(10123):find("1g", 1, true) ~= nil, "Copper converts to gold")
check(M.Age(nil, 100) == "Not recorded" and M.Age(10, 130) == "2m ago", "Snapshot age labels")
local future = {schema=999, characters={sentinel=true}}
check(M.Open(future) == nil and future.characters.sentinel, "Future schema is preserved and rejected")
check(M.Open(db) == db and db.characters[a.key] == a, "Opening saved data preserves records")

-- Mock only the read interfaces used by Scanner. IDs model Forever bank tabs.
local now, currentGuid, money = 2000, "Player-1-ABC", 54321
local data = {
    [0] = {capacity=16, [1]={itemID=1, hyperlink="item:1", iconFileID=123, stackCount=5, quality=1}},
    [6] = {capacity=28, [1]={itemID=2, hyperlink="item:2", iconFileID=234, stackCount=1, quality=4}},
    [7] = {capacity=28, [1]={itemID=1, hyperlink="item:1", iconFileID=123, stackCount=7, quality=1}},
}
local requested = {}
C_Container = {
    GetContainerNumSlots=function(bag) return data[bag] and data[bag].capacity or 0 end,
    GetContainerItemInfo=function(bag, slot) return data[bag] and data[bag][slot] end,
}
C_Item = {
    GetItemInfo=function(id)
        return id == 1 and "Peacebloom" or "Epic Blade", "item:" .. id,
            id == 1 and 1 or 4, 1, 1, "Trade Goods", "Herb", 20, "", 123
    end,
    RequestLoadItemDataByID=function(id) requested[id] = true end,
}
Enum = {BagIndex={CharacterBankTab_1=6, CharacterBankTab_2=7, Bank=-1}, BankType={Character=0}}
local tabs = {{ID=6}, {ID=7}}
C_Bank = {FetchPurchasedBankTabData=function() return tabs end}
UnitGUID=function() return currentGuid end
UnitFullName=function() return "Tester", "Test Realm" end
UnitClass=function() return "Mage", "MAGE" end
UnitRace=function() return "Human", "Human" end
UnitSex=function() return 3 end
UnitLevel=function() return 60 end
UnitFactionGroup=function() return "Alliance" end
GetCurrentRegion=function() return 3 end
GetRealmName=function() return "Test Realm" end
GetRealZoneText=function() return "Stormwind" end
GetMoney=function() return money end
time=function() return now end
GetInventoryItemID=function(_, slot) return slot == 16 and 2 or nil end
GetInventoryItemLink=function() return "item:2" end
GetInventoryItemTexture=function() return 234 end
GetInventoryItemQuality=function() return 4 end
GetInboxNumItems=function() return 1, 2 end
GetInboxHeaderInfo=function() return nil, nil, "Sender", "Subject", 10000, 0, 3 end
GetInboxItem=function(_, slot) if slot == 1 then return "Peacebloom", 1, 123, 4, 1 end end
GetInboxItemLink=function() return "item:1" end
loadModule("Scanner")
local S = Vault.Scanner
S.Bags()
local current = db.characters[Vault.currentKey]
check(current.money == 54321 and current.level == 60, "Player identity and wallet recorded")
check(current.snapshots.bags.items[1].count == 5, "Bag stack recorded")
check(current.name == "Tester Test Realm" and current.ruleset == "Test Realm" and current.realm == nil,
    "Forever's surname remains part of the name, separate from the server/ruleset label")
M.Save(current, "equipment", {{id=98765, name="Legacy equipped blade", count=1, quality=4}}, 19, 1000)
check(#M.Find(db, nil, "all", "Legacy equipped", nil) == 0 and #M.Owners(db, 98765) == 0,
    "Legacy equipment remains saved but is excluded from storage views and owner counts")
local bagSnapshot = current.snapshots.bags
local backpack = data[0]
data[0] = nil
S.Bags()
check(current.snapshots.bags == bagSnapshot, "Unavailable zero-capacity bags preserve the last snapshot")
data[0] = {capacity=16}
S.Bags()
check(#current.snapshots.bags.items == 0, "An accessible empty backpack can replace the last snapshot")
data[0] = backpack
S.Bags()
S.Bank()
check(current.snapshots.bank == nil, "Closed bank cannot invent a snapshot")
S.bankOpen = true
S.Bank()
check(#current.snapshots.bank.items == 2 and current.snapshots.bank.capacity == 56,
    "Forever purchased bank IDs include every tab")
local snapshot = current.snapshots.bank
S.bankOpen = false
data[6], data[7] = nil, nil
S.Bank()
check(current.snapshots.bank == snapshot, "Closing bank preserves the last snapshot")
S.bankOpen = true
S.Bank()
check(current.snapshots.bank == snapshot, "Unavailable zero-capacity bank preserves snapshot")
tabs = nil
S.Bank()
check(current.snapshots.bank == snapshot, "Missing purchased-tab data preserves snapshot")
tabs = {{ID=6}}
data[6] = {capacity=28}
C_Item.DoesItemExist=function(location) return location.bagID == 6 and location.slotIndex == 1 end
C_Item.GetItemID=function() return 2 end
S.Bank()
check(current.snapshots.bank == snapshot and requested[2], "Uncached occupied slot preserves snapshot and requests data")
C_Item.DoesItemExist=nil
S.Bank()
check(#current.snapshots.bank.items == 0, "Authoritatively empty bank replaces old items")
S.mailOpen=true
S.Mail()
check(current.snapshots.mail.items[1].count == 4 and current.snapshots.mail.partial,
    "Mail attachment and partial inbox tracked")
check(current.snapshots.mail.items[1].expires == now + 3*86400,
    "Mail expiration recorded")
check(current.snapshots.mail.money == 10000 and current.money == 54321,
    "Mailbox gold is separate from wallet balance")
local mail = current.snapshots.mail
S.mailOpen=false
S.Mail()
check(current.snapshots.mail == mail, "Closed mailbox preserves records")
local oldKey = Vault.currentKey
currentGuid = "Player-2-DEF"
S.Bags()
check(Vault.currentKey ~= oldKey and db.characters[oldKey] == current,
    "Logging another character retains the first character")
print("PASS: " .. passed .. " model/scanner regressions")
return Vault, passed
