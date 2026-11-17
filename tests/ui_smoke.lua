-- A strict frame-surface mock catches unsupported calls and exercises UI flows.
local root, Vault = ...
local methods = {}
local function noop() end
for _, name in ipairs({"SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetPoint",
    "ClearAllPoints", "SetFrameStrata", "SetClampedToScreen", "SetMovable", "EnableMouse",
    "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetTexCoord", "SetTexture",
    "SetTextColor", "SetJustifyH", "SetFont", "SetFontObject", "SetAutoFocus", "SetMaxLetters",
    "SetHighlightTexture", "ClearFocus", "SetOwner", "SetHyperlink", "SetItemByID", "AddLine",
    "AddDoubleLine", "SetAllPoints"}) do methods[name] = noop end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:HookScript(event, fn) self.hooks[event] = fn end
function methods:SetShown(value) self.shown = value end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown ~= false end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:GetWidth() return rawget(self, "width") or 100 end
function methods:GetHeight() return rawget(self, "height") or 100 end
function methods:SetScale(scale) self.scale = scale end
function methods:GetEffectiveScale() return rawget(self, "scale") or 1 end
function methods:GetCenter() return 100, 100 end
function methods:SetScrollChild(child) self.child = child end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetVerticalScroll() return rawget(self, "scroll") or 0 end
function methods:SetText(text) self.text = tostring(text) end
function methods:GetText() return rawget(self, "text") or "" end
local function frame(name)
    local object = setmetatable({scripts={}, hooks={}, shown=true}, {__index=function(_, key)
        assert(methods[key], "Unsupported mocked frame call: " .. key)
        return methods[key]
    end})
    if name then _G[name] = object end
    return object
end
CreateFrame=function(_, name) return frame(name) end
function methods:CreateTexture() return frame() end
function methods:CreateFontString() return frame() end
UIParent=frame()
UIParent:SetSize(1920, 1080)
Minimap=frame()
Minimap:SetSize(150, 150)
GameTooltip=frame()
STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF"
GameFontHighlight={}
UISpecialFrames={}
RAID_CLASS_COLORS={MAGE={r=0.4,g=0.8,b=1}}
ITEM_QUALITY_COLORS={}
for i=0,7 do ITEM_QUALITY_COLORS[i]={r=1,g=1,b=1} end
SetPortraitTexture=noop
IsShiftKeyDown=function() return false end
HandleModifiedItemClick=noop
GetCursorPosition=function() return 160, 160 end
C_Timer={After=function(_, fn) fn() end}
assert(loadfile(root .. "/WarbandVaultForever/UI.lua"))("WarbandVaultForever", Vault)
local UI=Vault.UI
-- Real scanner identities supply these fields; normalize the data-only fixtures.
for _, character in pairs(Vault.db.characters) do
    character.class="MAGE"; character.className="Mage"; character.race="Human"
    character.raceName="Human"; character.sex=3; character.level=60; character.faction="Alliance"
end
UI.Minimap()
UI.Toggle()
assert(UI.frame:IsShown() and #UI.rosterButtons == 4, "Roster renders all recorded characters")
assert(#UI.itemButtons <= 84 and #UI.results > 0, "Item grid is bounded and populated")
UI.selected="1:one"
UI.source="bank"
UI.Refresh()
assert(UI.empty.text:find("Bank not recorded",1,true), "Missing bank gives actionable guidance")
UI.selected=nil; UI.source="all"
UI.search:SetText("peace")
UI.search.scripts.OnTextChanged(UI.search)
assert(#UI.results > 0, "Typing in search filters inventory")
UI.query=""
UI.qualityButton.scripts.OnClick(UI.qualityButton)
assert(UI.quality == 0, "First quality filter is poor quality")
UI.quality=nil
UI.tabs.bags.scripts.OnClick(UI.tabs.bags)
assert(UI.source == "bags", "Bag tab changes source")
local mass={}
for i=1,2000 do mass[i]={id=i,name="Test "..i,count=1,quality=1,slot=i} end
Vault.Model.Save(Vault.db.characters["1:one"],"bags",mass,2000,2000)
UI.Refresh()
assert(#UI.results >= 2000 and #UI.itemButtons <= 84, "Large inventories reuse bounded frame pool")
UI.itemsScroll:SetVerticalScroll(590)
UI.RenderGrid()
assert(UI.itemButtons[1].result == UI.results[121], "Scrolled grid maps to the correct item")
UI.minimap.scripts.OnDragStart(UI.minimap)
UI.minimap.scripts.OnUpdate()
assert(type(Vault.db.settings.minimapAngle)=="number", "Minimap drag persists angle")
UI.minimap.scripts.OnDragStop(UI.minimap)
UI.Toggle()
assert(not UI.frame:IsShown(), "Toggle closes vault")
print("PASS: UI construction, tabs, search, empty states, 2000-item scrolling, and minimap drag")
