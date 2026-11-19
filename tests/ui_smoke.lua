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
    "SetWordWrap", "SetNumeric", "SetOrientation", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "SetThumbTexture", "SetFocus", "HighlightText", "SetNormalTexture", "SetPushedTexture", "SetDisabledTexture"}) do methods[name] = noop end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return unpack(rawget(self,"point") or {}) end
function methods:SetTexture(value) self.texture=value end
function methods:SetEnabled(value) self.enabled=value end
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
function methods:GetNumber() return tonumber(self:GetText()) or 0 end
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
UI.selected="1:one"; Vault.currentKey="1:one"; UI.source="bags"; UI.query=""
UI.Refresh()
assert(UI.tabs.crafting==nil and UI.crafting==nil,"Vault has no Crafting tab or hidden crafting page")
ProfessionsFrame=frame()
ProfessionsFrame.CraftingPage=frame()
ProfessionsFrame.ProfessionsOverviewTab=frame()
ProfessionsFrame.rightProfessionTabs={frame(),frame()}
WhatsTrainingCraftingTab=frame()
WhatsTrainingCraftingTab:SetPoint("BOTTOMLEFT",ProfessionsFrame,"BOTTOMRIGHT",0,10)
local selectedID=101
ProfessionsFrame.CraftingPage.SchematicForm={GetRecipeInfo=function() return {recipeID=selectedID} end}
ProfessionsFrame.CraftingPage.CreateMultipleInputBox=frame()
ProfessionsFrame.CraftingPage.CreateMultipleInputBox:SetText("3")
local tabs,registered={},nil
ForeverCore={ProfessionTabs={minor=2,Register=function(key,spec) registered=spec; tabs.key=key end,
    Select=function(key) tabs.selected=key; registered.page:Show(); registered.onSelect() end,
    Selected=function() return tabs.selected end,
    ShowNative=function() tabs.selected=nil; if registered then registered.page:Hide() end end}}
assert(loadfile(root.."/WarbandVaultForever/ProfessionWindow.lua"))("WVF",Vault)
local native=Vault.ProfessionWindow
native.Attach(); local firstPanel=native.panel; native.Attach()
assert(native.panel==firstPanel and registered.page==Vault.CraftingUI.frame,"Profession integration registers once")
assert(Vault.CraftingUI.frame:GetFrameLevel()>ProfessionsFrame:GetFrameLevel()+50,"Saved page intercepts clicks above invisible native controls")
assert(native.panel.parent==ProfessionsFrame.CraftingPage,"Materials sidebar belongs to native page")
assert(native.panel.point[4]>=76 and native.toggle.point[4]>=76,"Sidebar and toggle leave the native icon column clear")
local lastNative=ProfessionsFrame.rightProfessionTabs[2]
assert(WhatsTrainingCraftingTab.point[1]=="TOPLEFT" and WhatsTrainingCraftingTab.point[2]==lastNative,
    "Bottom addon tab chain starts under the last native profession icon")
WT_ProfessionTabPosition="bottom"
WhatsTrainingCraftingTab:SetPoint("TOPRIGHT",ProfessionsFrame,"BOTTOMRIGHT",-10,0)
native.CompactTabs()
assert(WhatsTrainingCraftingTab.point[1]=="TOPRIGHT","Explicit bottom placement remains respected")
WT_ProfessionTabPosition=nil; native.CompactTabs()
local previousCombat=InCombatLockdown
InCombatLockdown=function() return true end
WhatsTrainingCraftingTab:SetPoint("BOTTOMLEFT",ProfessionsFrame,"BOTTOMRIGHT",0,10)
native.CompactTabs()
assert(WhatsTrainingCraftingTab.point[1]=="BOTTOMLEFT","Tab positioning waits during combat")
InCombatLockdown=previousCombat; native.CompactTabs()

assert(native.result.recipe.id==101 and native.count==3,"Native recipe and quantity drive material plan")
assert(native.text.text:find("Need 3",1,true),"Native sidebar scales materials to batch quantity")
assert(native.Open(),"Open saved recipes through profession window")
local crafting=Vault.CraftingUI
assert(#crafting.results==1 and crafting.frame.parent==ProfessionsFrame,"Saved recipes moved into native window")
assert(crafting.Quantity()==1,"Saved recipe planning starts at one")
crafting.search:SetText("no such recipe"); crafting.search.scripts.OnTextChanged(crafting.search)
assert(#crafting.results==0 and Vault.db.settings.recipeSearch=="no such recipe","Independent recipe search persists")
crafting.search:SetText(""); crafting.search.scripts.OnTextChanged(crafting.search)
assert(#crafting.results==1,"Clearing search restores saved recipes")
crafting.availableButton.scripts.OnClick()
assert(Vault.db.settings.recipeAvailableOnly and #crafting.results==1,"Bag availability filter uses saved materials")
crafting.availableButton.scripts.OnClick()

assert(crafting.createAll==nil and crafting.craftButton.text=="Show recipe","Actual crafting uses the native page")
crafting.currentResult.recipe.icon=135879; crafting.Details(crafting.currentResult)
assert(crafting.outputIcon.texture==135879,"Recipe output keeps its icon")
crafting.SetQuantity(0); assert(crafting.Quantity()==1,"Planning never silently calculates a different quantity from its input")
crafting.SetQuantity(3); assert(crafting.Quantity()==3)
local oldAPI=C_TradeSkillUI; local oldProfessions=Vault.Professions
local picked
C_TradeSkillUI={GetBaseProfessionInfo=function() return {professionName="Alchemy"} end,
    GetRecipeInfo=function(id) return {recipeID=id,learned=true} end}
Vault.Professions={open=true}
ProfessionsFrame.CraftingPage.SelectRecipe=function(_,info) picked=info.recipeID end
crafting.ShowNative(); assert(picked==101 and tabs.selected==nil,"Show recipe selects native recipe without crafting")
Vault.Professions.open=false; picked=nil
crafting.ShowNative(); assert(picked==nil,"Closed profession cannot be opened from addon code")
Vault.Professions=oldProfessions; C_TradeSkillUI=oldAPI
native.collapse.scripts.OnClick(); assert(not native.panel:IsShown())
native.toggle.scripts.OnClick(); assert(native.panel:IsShown(),"Materials sidebar can be restored")
selectedID=999; native.Render(); assert(native.result==nil and not native.materials.enabled,"Unknown recipe clears stale materials")
ProfessionsFrame:Hide(); assert(not native.Open(),"Saved browser does not force a profession window open")
ProfessionsFrame:Show()
-- Standalone install: no ForeverCore, Auctionator, or other addon UI.
local sharedCore=ForeverCore
ForeverCore=nil
ProfessionsFrame=frame()
ProfessionsFrame:SetWidth(673)
ProfessionsFrame.Pages={}
ProfessionsFrame.BookPage=false; ProfessionsFrame.SpecPage=false; ProfessionsFrame.OrdersPage=false
ProfessionsFrame.ProfessionsOverviewTab=frame()
ProfessionsFrame.rightProfessionTabs={frame(),frame()}
ProfessionsFrame.CraftingPage=frame()
ProfessionsFrame.CraftingPage:SetAlpha(0.8)
ProfessionsFrame.CraftingPage.SchematicForm={GetRecipeInfo=function() return {recipeID=101} end}
ProfessionsFrame.CraftingPage.CreateMultipleInputBox=frame()
ProfessionsFrame.CraftingPage.CreateMultipleInputBox:SetText("2")
WhatsTrainingCraftingTab=nil
assert(loadfile(root.."/WarbandVaultForever/CraftingUI.lua"))("WVF",Vault)
assert(loadfile(root.."/WarbandVaultForever/ProfessionWindow.lua"))("WVF",Vault)
local standalone=Vault.ProfessionWindow
standalone.Attach()
assert(standalone.panel and standalone.navigation.button:IsShown(),"Standalone addon creates profession menus without ForeverCore")
assert(standalone.result.recipe.id==101 and standalone.count==2,"Standalone native material tracking works")
standalone.navigation.button.scripts.OnClick()
assert(Vault.CraftingUI.frame:IsShown() and ProfessionsFrame:GetWidth()==850 and ProfessionsFrame.CraftingPage:GetAlpha()==0,
    "Standalone tab opens saved recipes and hides native content without closing profession")
Vault.CraftingUI.nativeButton.scripts.OnClick()
assert(not Vault.CraftingUI.frame:IsShown() and ProfessionsFrame:GetWidth()==673 and ProfessionsFrame.CraftingPage:GetAlpha()==0.8,
    "Native recipes restores original width and alpha")
standalone.Open()
ProfessionsFrame.rightProfessionTabs[1].hooks.OnMouseUp()
assert(standalone.navigation.Selected()==nil,"Clicking native profession tabs returns to native content")
standalone.Open(); ProfessionsFrame.hooks.OnHide()
assert(not Vault.CraftingUI.frame:IsShown() and ProfessionsFrame:GetWidth()==673,"Closing resets standalone page state")
local fallbackButton=standalone.navigation.button
standalone.Attach()
assert(standalone.navigation.button==fallbackButton,"Repeated attachment does not duplicate standalone tabs")
InCombatLockdown=function() return true end
assert(not standalone.Open(),"Standalone navigation waits outside combat")
InCombatLockdown=previousCombat
ForeverCore=sharedCore
Vault.Sync={config={enabled=false,auto=true},status="Not linked."}
assert(loadfile(root.."/WarbandVaultForever/SyncUI.lua"))("WVF",Vault)
if not UI.settingsFrame:IsShown() then UI.Settings() end
Vault.SyncUI.Open()
assert(Vault.SyncUI.frame:IsShown() and not UI.settingsFrame:IsShown(),"Account sync hides the parent Settings menu")
assert(Vault.SyncUI.frame:GetFrameLevel()>UI.settingsFrame:GetFrameLevel(),"Sync controls stay above Settings")
Vault.SyncUI.frame:Hide()
assert(UI.settingsFrame:IsShown(),"Closing sync returns to Settings")
print("PASS: satchel UI, close-button events, sound/effects settings, 2000-item scrolling, and bag-bar shortcut")

assert(UI.portrait.mask and UI.portrait.rim,"Character header uses a circular portrait mask and ring")
assert(UI.tabs.equipment==nil, "Storage views have no equipment tab")
UI.helpButton.scripts.OnClick()
assert(UI.infoFrame:IsShown() and UI.infoTitle.text=="Help" and UI.infoText.text:find("ACCOUNT SYNC",1,true),
    "Help opens a scrollable guide with account-sync instructions")
UI.creditsButton.scripts.OnClick()
assert(UI.infoTitle.text=="Credits" and UI.infoText.text:find("Egor Skriptunoff",1,true),
    "Credits identifies the addon author and upstream crypto library")
local clearCalls=0
Vault.ClearRecords=function() clearCalls=clearCalls+1; Vault.Model.ClearRecords(Vault.db); UI.RecordsCleared() end
local records=Vault.db.characters
UI.clearButton.scripts.OnClick()
assert(UI.clearFrame:IsShown() and clearCalls==0 and Vault.db.characters==records,
    "Opening confirmation must never clear saved data")
UI.clearCancel.scripts.OnClick()
assert(not UI.clearFrame:IsShown() and clearCalls==0 and Vault.db.characters==records,
    "Cancel leaves records untouched")
UI.clearButton.scripts.OnClick(); UI.clearAccept.scripts.OnClick()
assert(clearCalls==1 and next(Vault.db.characters)==nil and not UI.clearFrame:IsShown(),
    "Confirm invokes record clearing exactly once")
assert(Vault.CraftingUI.currentResult==nil and Vault.ProfessionWindow.result==nil,
    "Clearing also removes stale profession selections")
print("PASS: storage-only tabs, Help/Credits and cancellable record clearing")
