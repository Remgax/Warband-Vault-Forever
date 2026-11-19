local root = ...
local Vault, calls, frames, timers = {}, {}, {}, {}
local function counted(name)
    return function() calls[name] = (calls[name] or 0) + 1 end
end
Vault.Model = {Open=function(db) return db or {characters={},settings={minimap=true}} end}
Vault.Scanner = {Identity=counted("identity"), Bank=counted("bank"),
    Refresh=counted("refresh"), ResolveItem=counted("resolve")}
Vault.UI = {Toggle=counted("toggle"), Minimap=counted("minimap"),
    Refresh=counted("ui"), ApplyPosition=counted("position"),
    minimap={SetShown=function(_, value) calls.visible=value end}}
Vault.ProfessionWindow={Attach=counted("professionAttach"), Open=function() calls.professionOpen=(calls.professionOpen or 0)+1; return true end}
Vault.UI.ActionBar=counted("actionbar")
Vault.UI.StopEffects=counted("stopEffects")
Vault.UI.RefreshSettings=counted("settings")
Vault.UI.Help=counted("help")
CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(event) self.events[event]=true end
    function f:SetScript(_, fn) self.handler=fn end
    frames[#frames+1]=f
    return f
end
C_Timer={After=function(_, fn) timers[#timers+1]=fn end}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
SlashCmdList={}
strtrim=function(value) return value:match("^%s*(.-)%s*$") end
WarbandVaultForeverDB=nil
assert(loadfile(root .. "/WarbandVaultForever/Core.lua"))("WarbandVaultForever",Vault)
local f=frames[1]
local function event(name, ...) f.handler(f,name,...) end
local function flush()
    while #timers > 0 do local batch=timers; timers={}; for _, fn in ipairs(batch) do fn() end end
end
event("ADDON_LOADED","OtherAddon")
assert(not Vault.db, "Other addon load must not initialize this addon")
event("ADDON_LOADED","WarbandVaultForever")
assert(Vault.db == WarbandVaultForeverDB and calls.minimap==1, "SavedVariables initialize once")
event("PLAYER_LOGIN")
flush()
assert(calls.refresh==1, "Login scans asynchronously")
event("BAG_UPDATE_DELAYED"); event("BAG_UPDATE_DELAYED"); event("PLAYER_EQUIPMENT_CHANGED")
flush()
assert(calls.refresh==2, "Burst updates debounce into one complete refresh")
event("BANKFRAME_OPENED")
assert(Vault.Scanner.bankOpen, "Bank opens authoritative scanning window")
event("BAG_UPDATE_DELAYED")
assert(calls.bank==3, "Bank changes scan synchronously before bank close")
event("BANKFRAME_CLOSED")
assert(not Vault.Scanner.bankOpen, "Bank closes authoritative scanning window")
event("MAIL_SHOW"); assert(Vault.Scanner.mailOpen)
event("MAIL_CLOSED"); assert(not Vault.Scanner.mailOpen)
event("ITEM_DATA_LOAD_RESULT",1,true)
flush()
assert(calls.resolve==1, "Item data completion resolves cached details")
SlashCmdList.WARBANDVAULTFOREVER("minimap")
assert(calls.visible==false, "First minimap toggle hides the visible button")
SlashCmdList.WARBANDVAULTFOREVER("minimap")
assert(calls.visible==true, "Second minimap toggle shows the button")
SlashCmdList.WARBANDVAULTFOREVER("")
assert(calls.toggle==1, "Slash command opens vault")
SlashCmdList.WARBANDVAULTFOREVER("crafting")
assert(calls.professionOpen==1 and calls.toggle==1,"Crafting command opens profession integration without opening vault")
event("PLAYER_REGEN_ENABLED")
assert(calls.professionAttach>=2,"Deferred profession integration retries after combat")
WarbandVaultForever_Toggle()
assert(calls.toggle==2, "Global key binding invokes UI")
SlashCmdList.WARBANDVAULTFOREVER("help")
assert(calls.help==1, "Help command opens the full guide")
local beforeLogout=calls.refresh
event("BAG_UPDATE_DELAYED")
event("PLAYER_LOGOUT")
flush()
assert(calls.refresh==beforeLogout, "Logout never rescans unavailable APIs or runs a queued scan")
print("PASS: lifecycle, debounce, bank/mail guards, item load, slash commands, and key binding")
