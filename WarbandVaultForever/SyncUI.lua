-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
local View, S, W = {}, Vault.Sync, Vault.UI.widgets
Vault.SyncUI=View
function View.Refresh()
    if not View.frame or not S.config then return end
    View.status:SetText(S.status or "Not linked.")
    local label=S.config.peerID and ("Linked account: "..(S.config.peerLabel or S.config.peerID)) or "No account paired."
    if S.config.lastSync then label=label.."\nLast received: "..Vault.Model.Age(S.config.lastSync,time()).." / "..(S.config.lastCharacter or "") end
    View.peer:SetText(label)
    View.accept:SetShown(S.pending~=nil)
    View.enabled:SetChecked(S.config.enabled==true)
    View.auto:SetChecked(S.config.auto~=false)
    View.professions:SetChecked(S.config.shareProfessions~=false)
    View.mail:SetChecked(S.config.shareMail~=false)
end
local function Input(parent,x,y,width)
    local backing=W.Panel(parent,width,32); backing:SetPoint("TOPLEFT",x,y)
    local field=CreateFrame("EditBox",nil,backing)
    field:SetPoint("TOPLEFT",8,-3); field:SetPoint("BOTTOMRIGHT",-8,3)
    field:SetFontObject(GameFontHighlight); field:SetAutoFocus(false); field:SetMaxLetters(80)
    field:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    return field
end
function View.Open()
    if not View.frame then
        local panel=W.Panel(UIParent,580,610,nil,"WarbandVaultForeverSync")
        View.frame=panel; panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG"); panel:SetClampedToScreen(true)
        table.insert(UISpecialFrames,"WarbandVaultForeverSync")
        local close=CreateFrame("Button",nil,panel,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() panel:Hide() end)
        W.Text(panel,"Account sync",22,W.colors.gold):SetPoint("TOPLEFT",22,-20)
        W.Text(panel,"Pair once for all characters on two accounts. Both accounts need this version\nand must be online on the same realm and faction to exchange updates.",12,nil,535):SetPoint("TOPLEFT",22,-57)
        W.Text(panel,"1. On the first account, create a code. Copy it privately to the other account.",12,nil,530):SetPoint("TOPLEFT",22,-105)
        local code=Input(panel,22,-130,360); View.code=code
        W.Button(panel,"Create / show code",166,30,function()
            if not S.config.key then
                local ok,created,err=pcall(S.Create)
                if not ok or not created then S.status=err or "Could not create a pairing code. Please reload the addon."; View.Refresh(); return end
            end
            code:SetText(S.Code()); code:SetFocus(); code:HighlightText()
        end):SetPoint("TOPLEFT",390,-131)
        W.Text(panel,"2. On the other account, paste that code here and choose Pair.",12,nil,535):SetPoint("TOPLEFT",22,-177)
        View.input=Input(panel,22,-201,360)
        W.Button(panel,"Pair account",166,30,function()
            local ok,err=S.Join(View.input:GetText()); View.input:SetText(""); View.input:ClearFocus()
            if not ok then S.status=err end; View.Refresh()
        end):SetPoint("TOPLEFT",390,-202)
        View.accept=W.Button(panel,"Approve account",166,30,S.Accept)
        View.accept:SetPoint("TOPRIGHT",-24,-243)
        View.peer=W.Text(panel,"",12,W.colors.gold,525); View.peer:SetPoint("TOPLEFT",22,-252)
        View.status=W.Text(panel,"",12,nil,530); View.status:SetPoint("TOPLEFT",22,-304)
        for i,option in ipairs({{"enabled","Enable account sync","enabled"},{"auto","Sync changes automatically","auto"},
            {"professions","Share professions and recipes","shareProfessions"},{"mail","Share mailbox records","shareMail"}}) do
            local field,label,key=unpack(option)
            local check=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
            check:SetSize(26,26); check:SetPoint("TOPLEFT",22,-351-(i-1)*31)
            W.Text(check,label,12):SetPoint("LEFT",check,"RIGHT",4,0)
            check:SetScript("OnClick",function(self)
                S.config[key]=self:GetChecked() and true or false
                if key=="enabled" and not S.config.enabled then S.Stop(); S.status="Sync paused. Saved records remain available." end
                S.fingerprints={}; S.lastHello=-30; S.lastScan=-30; View.Refresh()
            end)
            View[field]=check
        end
        W.Text(panel,"Bags, banks, equipment, and gold are shared. Bank contents update at a banker.\nKeep the code private. Data uses WoW messages; it is authenticated, not encrypted.\nUnlink removes this account's imported records and pairing code.",11,W.colors.muted,535):SetPoint("TOPLEFT",22,-487)
        W.Button(panel,"Sync now",120,30,S.Now):SetPoint("BOTTOMLEFT",22,20)
        W.Button(panel,"Unlink account",145,30,function()
            S.Unlink(); View.code:SetText(""); View.input:SetText("")
        end):SetPoint("BOTTOMLEFT",154,20)
        W.Button(panel,"Done",100,30,function() panel:Hide() end):SetPoint("BOTTOMRIGHT",-22,20)
        panel:SetScript("OnHide",function()
            View.code:SetText(""); View.input:SetText("")
            if View.returnToSettings then View.returnToSettings=false; Vault.UI.settingsFrame:Show() end
        end)
    end
    if Vault.UI.settingsFrame and Vault.UI.settingsFrame:IsShown() then
        View.returnToSettings=true; Vault.UI.settingsFrame:Hide()
    end
    View.frame:SetFrameLevel((Vault.UI.settingsFrame and Vault.UI.settingsFrame:GetFrameLevel() or 1)+30)
    View.Refresh(); View.frame:Show()
end
