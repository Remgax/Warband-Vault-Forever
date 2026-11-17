-- A strict frame-surface mock catches unsupported calls and exercises UI flows.
local root, Vault = ...
local methods = {}
local function noop() end
for _, name in ipairs({"SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetPoint",
    "ClearAllPoints", "SetFrameStrata", "SetClampedToScreen", "SetMovable", "EnableMouse",
    "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetTexCoord", "SetTexture",
    "SetTextColor", "SetJustifyH", "SetFont", "SetFontObject", "SetAutoFocus", "SetMaxLetters",
    "SetHighlightTexture", "ClearFocus", "SetOwner", "SetHyperlink", "SetItemByID", "AddLine",
    "AddDoubleLine", "SetAllPoints", "SetBlendMode", "SetVertexColor", "SetColorTexture", "AddMaskTexture",
    "SetWordWrap", "SetNumeric", "SetOrientation", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "SetThumbTexture", "SetFocus", "HighlightText"}) do methods[name] = noop end
function methods:GetStringHeight() return 500 end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:HookScript(event, fn) self.hooks[event] = fn end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:Show() self.shown = true end
function methods:Hide()
    local wasShown = self.shown
    self.shown = false
    if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown ~= false end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:GetWidth() return rawget(self, "width") or 100 end
function methods:GetHeight() return rawget(self, "height") or 100 end
function methods:SetScale(scale) self.scale = scale end
function methods:GetEffectiveScale() return rawget(self, "scale") or 1 end
function methods:GetCenter() return 100, 100 end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return rawget(self,"level") or 1 end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return rawget(self,"alpha") or 1 end
function methods:SetParent(parent) self.parent = parent end
function methods:GetRight() return rawget(self,"right") or 900 end
function methods:RegisterForClicks(...) self.clicks = {...} end
function methods:SetScrollChild(child) self.child = child end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetVerticalScroll() return rawget(self, "scroll") or 0 end
function methods:SetText(text) self.text = tostring(text) end
function methods:GetText() return rawget(self, "text") or "" end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return rawget(self,"checked") end
function methods:SetValue(value)
    self.value=value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
end
local function frame(name)
    local object = setmetatable({scripts={}, hooks={}, shown=true}, {__index=function(_, key)
        assert(methods[key], "Unsupported mocked frame call: " .. key)
        return methods[key]
    end})
    if name then _G[name] = object end
    return object
end
CreateFrame=function(_, name, parent)
    local f = frame(name)
    f.parent = parent
    if parent then f.level = parent:GetFrameLevel() + 1 end
    return f
end
function methods:CreateTexture() return frame() end
function methods:CreateMaskTexture() return frame() end
function methods:CreateFontString() return frame() end
UIParent=frame()
UIParent:SetSize(1920, 1080)
Minimap=frame()
Minimap:SetSize(150, 150)
BagsBar=frame()
MainMenuBarBackpackButton=frame()
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
local sounds={}
SOUNDKIT={IG_BACKPACK_OPEN=862}
PlaySound=function(id) sounds[#sounds+1]=id end
local soundVolumes={}
C_Sound={PlaySoundWithOptions=function(params)
    sounds[#sounds+1]=params.soundKitID; soundVolumes[#soundVolumes+1]=params.volumeOverride
end}
assert(loadfile(root .. "/WarbandVaultForever/Crafting.lua"))("WarbandVaultForever", Vault)
assert(loadfile(root .. "/WarbandVaultForever/Shopping.lua"))("WarbandVaultForever", Vault)
assert(loadfile(root .. "/WarbandVaultForever/UI.lua"))("WarbandVaultForever", Vault)
assert(loadfile(root .. "/WarbandVaultForever/CraftingUI.lua"))("WarbandVaultForever", Vault)
local UI=Vault.UI
-- Real scanner identities supply these fields; normalize the data-only fixtures.
for _, character in pairs(Vault.db.characters) do
    character.class="MAGE"; character.className="Mage"; character.race="Human"
    character.raceName="Human"; character.sex=3; character.level=60; character.faction="Alliance"
end
UI.Minimap()
UI.ActionBar()
UI.Toggle()
assert(UI.frame:IsShown() and #UI.rosterButtons == 4, "Roster renders all recorded characters")
assert(#UI.itemButtons <= 66 and #UI.results > 0, "Item grid is bounded and populated")
assert(#sounds==1 and sounds[1]==SOUNDKIT.IG_BACKPACK_OPEN, "Opening uses the native backpack sound")
assert(soundVolumes[1]==0.8, "Opening volume is per sound, not a global game setting")
assert(UI.closeButton:GetFrameLevel()>UI.header:GetFrameLevel(), "Close control sits above draggable header")
UI.frame.scripts.OnUpdate(UI.frame,0.3)
assert(UI.frame.scripts.OnUpdate==nil and UI.frame:GetAlpha()==1 and not UI.flap:IsShown(), "Opening effect finishes and removes its update handler")
UI.selected="1:one"
UI.source="bank"
UI.Refresh()
assert(UI.empty.text:find("Visit a banker as Aeris",1,true), "Missing bank names the character to visit")
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
assert(#UI.results >= 2000 and #UI.itemButtons <= 66, "Large inventories reuse bounded frame pool")
UI.itemsScroll:SetVerticalScroll(600)
UI.RenderGrid()
assert(UI.itemButtons[1].result == UI.results[101], "Scrolled grid maps to the correct item")
assert(#sounds==1, "Changing tabs and searching do not replay opening sound")
UI.minimap.scripts.OnDragStart(UI.minimap)
UI.minimap.scripts.OnUpdate()
assert(type(Vault.db.settings.minimapAngle)=="number", "Minimap drag persists angle")
UI.minimap.scripts.OnDragStop(UI.minimap)
UI.closeButton.scripts.OnMouseUp(UI.closeButton,"LeftButton")
assert(not UI.frame:IsShown(), "Close button mouse release closes the window")
assert(UI.frame.scripts.OnUpdate==nil, "Closing stops opening effects")
Vault.db.settings.sound=false; Vault.db.settings.effects=false
UI.actionbar.scripts.OnClick()
assert(UI.frame:IsShown() and #sounds==1 and UI.frame.scripts.OnUpdate==nil,
    "Action-bar shortcut opens the vault and respects disabled sound/effects")
UI.closeButton.scripts.OnClick()
assert(not UI.frame:IsShown(), "Native close-button click closes the window")
assert(UI.actionbar.parent==BagsBar, "Action-bar shortcut follows the bags bar")
local bagsBar=BagsBar; BagsBar=nil
UI.ActionBar()
assert(UI.actionbar.parent==MainMenuBarBackpackButton, "Shortcut falls back to backpack when bags bar is unavailable")
BagsBar=bagsBar
UI.Toggle(); UI.Toggle()
assert(not UI.frame:IsShown(), "Toggle closes vault")
UI.Settings()
assert(UI.settingsFrame:IsShown() and UI.soundButton==nil and UI.effectsButton==nil,
    "Settings are separate from the inventory page")
UI.settingsSliders.scale:SetValue(0.85)
assert(Vault.db.settings.scale==0.85 and UI.frame.scale==0.85, "Scale slider applies the saved scale")
UI.settingsSliders.soundVolume:SetValue(0.25)
UI.PlayOpeningSound()
assert(soundVolumes[#soundVolumes]==0.25, "Sound slider controls the playback volume override")
UI.settingsSliders.effectStrength:SetValue(0)
assert(Vault.db.settings.effects==false, "Effects slider zero disables motion and glow")
UI.Toggle()
UI.characterSearch:SetText("borin"); UI.characterSearch.scripts.OnTextChanged(UI.characterSearch)
local shown=0; for _, button in ipairs(UI.rosterButtons) do if button:IsShown() then shown=shown+1 end end
assert(shown==1 and UI.visibleKeys["1:two"], "Character search narrows the roster and item scope")
UI.clearFilters.scripts.OnClick()
assert(UI.rosterFilters.query==nil, "Clear filters resets character search")
Vault.db.characters["1:one"].professions={Alchemy={name="Alchemy",rank=10,maximum=75,updated=2000,
    recipes={[101]={id=101,name="Test potion",reagents={{id=1,name="Peacebloom",count=1}}}}}}
UI.selected="1:one"; UI.source="crafting"; UI.query=""
UI.Refresh()
assert(UI.crafting:IsShown() and not UI.itemsScroll:IsShown() and #Vault.CraftingUI.results==1,
    "Crafting tab lists saved recipes separately from the inventory")
assert(Vault.CraftingUI.status.text:find("Enough",1,true), "Crafting details show material sufficiency")
Vault.Sync={config={enabled=false,auto=true},status="Not linked."}
assert(loadfile(root.."/WarbandVaultForever/SyncUI.lua"))("WVF",Vault)
if not UI.settingsFrame:IsShown() then UI.Settings() end
Vault.SyncUI.Open()
assert(Vault.SyncUI.frame:IsShown() and not UI.settingsFrame:IsShown(),"Account sync hides the parent Settings menu")
assert(Vault.SyncUI.frame:GetFrameLevel()>UI.settingsFrame:GetFrameLevel(),"Sync controls stay above Settings")
Vault.SyncUI.frame:Hide()
assert(UI.settingsFrame:IsShown(),"Closing sync returns to Settings")
print("PASS: satchel UI, close-button events, sound/effects settings, 2000-item scrolling, and bag-bar shortcut")
