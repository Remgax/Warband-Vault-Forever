-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
local S, Data, Crypto = {}, Vault.SyncData, Vault.Crypto
Vault.Sync = S
local PREFIX, CHUNK = "WVF3", 140
local function Clock() return GetTime() end
local function RandomID()
    return Crypto.sha256(tostring({}) .. tostring(time()) .. tostring(Clock()) ..
        tostring(UnitGUID("player")) .. tostring(math.random()) .. tostring(math.random()))
end
local function Notify()
    if Vault.SyncUI then Vault.SyncUI.Refresh() end
end
local function Status(message) S.status=message; Notify() end
local function MAC(text) return Crypto.hmac(Crypto.sha256,S.config.key,text):sub(1,32) end
local function ValidID(value) return type(value)=="string" and #value==12 and value:match("^%x+$") end
local function Channel()
    return S.config.key and "WVF" .. Crypto.sha256("discovery:"..S.config.key):sub(1,20)
end
local function Send(kind,payload,target,session,channel)
    if not S.config.key or not S.config.enabled then return end
    S.sequence=S.sequence+1
    local body=table.concat({"3",kind,S.config.id,S.session,session or "",S.sequence,payload or ""},"|")
    local message=body.."|"..MAC(body)
    assert(#message<=250)
    local ok,result=pcall(C_ChatInfo.SendAddonMessage,PREFIX,message,channel or "WHISPER",target)
    if not ok then Status("WoW blocked addon communication. Try again outside combat.") end
    if ok and Enum and Enum.SendAddonMessageResult and result and result~=Enum.SendAddonMessageResult.Success then
        Status("WoW could not send a sync message. Check the channel, ruleset and faction.")
    end
end
local function Control(kind,payload,target,session)
    if #S.controls<30 then S.controls[#S.controls+1]={kind,payload,target,session} end
end
function S.Initialize()
    Vault.db.sync=Vault.db.sync or {enabled=false,auto=true}
    S.config=Vault.db.sync
    if not Crypto or not Crypto.sha256 then Status("Account sync could not load its hashing library. Please reinstall the addon."); return end
    S.config.id=S.config.id or RandomID():sub(1,12)
    S.session=RandomID():sub(1,12); S.sequence=0; S.controls={}; S.fingerprints={}; S.rate={}
    S.joined=nil; S.active=nil; S.tx=nil; S.rx=nil; S.pending=nil; S.retired={}; S.lastHello=-30; S.lastScan=-30
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage or not C_ChatInfo.RegisterAddonMessagePrefix then
        Status("This client does not provide addon messaging."); return
    end
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,PREFIX)
    if not ok or result==false then Status("Could not register account sync messages."); return end
    if C_Timer.NewTicker then S.ticker=C_Timer.NewTicker(0.15,S.Tick) end
    Status(S.config.key and "Waiting for the linked account." or "Not linked.")
end
function S.Stop()
    if S.joined and LeaveChannelByName then pcall(LeaveChannelByName,S.joined) end
    S.joined=nil; S.active=nil; S.tx=nil; S.rx=nil; S.controls={}; S.pending=nil; S.retired={}; S.completed=nil
end
function S.Create()
    if not Crypto or not S.session then return false,"Account sync did not initialize. Please reload or reinstall." end
    if S.config.key then return false,"Unlink the current connection before creating another." end
    S.config.key=RandomID():sub(1,32); S.config.enabled=true; S.config.joining=false
    S.lastHello=-30; Status("Copy the pairing code to your other account. Awaiting approval."); return true
end
function S.Join(code)
    if not Crypto or not S.session then return false,"Account sync did not initialize. Please reload or reinstall." end
    if S.config.key then return false,"Unlink the current connection first." end
    code=(code or ""):gsub("%s", ""):lower():gsub("^wvf3%-", "")
    if #code~=32 or not code:match("^%x+$") then return false,"Enter the complete WVF3 pairing code." end
    S.config.key=code; S.config.enabled=true; S.config.joining=true; S.lastHello=-30
    Status("Waiting for approval on the account that created the code."); return true
end
function S.Code() return S.config.key and ("WVF3-"..S.config.key) or "" end
function S.Accept()
    local p=S.pending
    if not p or S.config.peerID then return end
    S.config.peerID=p.id; S.config.peerLabel=p.sender; S.config.joining=false
    Control("A","",p.sender,p.session); S.pending=nil
    Status("Account approved. Establishing the connection.")
end
function S.Unlink()
    local id=S.config.peerID
    S.Stop()
    S.config.key=nil; S.config.peerID=nil; S.config.peerLabel=nil; S.config.joining=false; S.config.enabled=false
    S.config.lastSync=nil; S.config.lastCharacter=nil; S.fingerprints={}
    for key,c in pairs(Vault.db.characters) do if id and c.remoteAccount==id then Vault.db.characters[key]=nil end end
    if Vault.UI then Vault.UI.Refresh() end
    Status("Unlinked. Imported records removed; your own characters are unchanged.")
end
function S.Now()
    S.fingerprints={}; S.lastScan=-30; S.manual=true
    if S.active then Control("R","",S.active.sender,S.active.session) end
    S.lastHello=-30; Status("Looking for the linked account.")
end
local function Announce()
    if not S.joined then return end
    local id=GetChannelName(S.joined)
    if id and id>0 then Send("H","",tostring(id),nil,"CHANNEL")
    else Status("Discovery channel unavailable. Both accounts need the same ruleset and faction.") end
end
local function BeginNext()
    if not S.active or S.tx then return end
    for _,c in ipairs(Vault.Model.Characters(Vault.db)) do
        if not c.remoteAccount then
            local record=Data.Local(c)
            if S.config.shareProfessions==false then record.professions=nil end
            if S.config.shareMail==false then record.snapshots.mail=nil end
            local ok,stable=pcall(Data.Encode,record,true)
            if ok then
                local digest=Crypto.sha256(stable); local old=S.fingerprints[c.key]
                if not old or old.digest~=digest or Clock()-old.sent>300 then
                    local encoded=Crypto.bin_to_base64(Data.Encode(record))
                    S.tx={id=RandomID():sub(1,12),key=c.key,digest=digest,encoded=encoded,
                        hash=Crypto.sha256(encoded),total=math.ceil(#encoded/CHUNK),ack=-1,next=1,
                        lastBegin=-10,lastSend=Clock(),progress=Clock()}
                    return
                end
            else Status("A character record is too large to sync. Disable profession sharing and retry.") end
        end
    end
    S.manual=false
end
function S.Tick()
    if not S.config or not S.config.key or not S.config.enabled then return end
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return end
    if not UnitGUID("player") then return end
    local name=Channel()
    if not S.joined and JoinChannelByName then
        local ok=pcall(JoinChannelByName,name); if ok then S.joined=name; S.lastHello=Clock()-15 end
    end
    if Clock()-S.lastHello>=20 then S.lastHello=Clock(); Announce() end
    if S.active and Clock()-S.active.seen>65 then S.active=nil; S.tx=nil; S.rx=nil; Status("Linked account offline or unreachable. Saved records remain available.") end
    if S.rx and Clock()-S.rx.progress>120 then S.rx=nil end
    if #S.controls>0 then local m=table.remove(S.controls,1); Send(unpack(m)); return end
    if not S.active then return end
    if (S.manual or S.config.auto~=false) and Clock()-S.lastScan>10 then S.lastScan=Clock(); BeginNext() end
    local tx=S.tx
    if not tx then return end
    if Clock()-tx.progress>120 then S.tx=nil; Status("Sync timed out. It will retry when the account is reachable."); return end
    if tx.ack<0 then
        if Clock()-tx.lastBegin>2 then
            tx.lastBegin=Clock(); Send("B",tx.id..":"..tx.total..":"..tx.hash,S.active.sender,S.active.session)
        end
    else
        if Clock()-tx.lastSend>2 then tx.next=tx.ack+1 end
        if tx.next<=tx.total and tx.next<=tx.ack+8 then
            local i=tx.next; tx.next=i+1; tx.lastSend=Clock()
            Send("D",tx.id..":"..i..":"..tx.encoded:sub((i-1)*CHUNK+1,i*CHUNK),S.active.sender,S.active.session)
        elseif tx.ack==tx.total and Clock()-tx.lastSend>2 then
            tx.lastSend=Clock(); Send("B",tx.id..":"..tx.total..":"..tx.hash,S.active.sender,S.active.session)
        end
    end
end
local function Active(id,session,sender)
    if not S.active or S.active.session~=session or S.active.sender~=sender then
        if S.active and S.active.session~=session then S.retired[S.active.session]=true end
        S.active={id=id,session=session,sender=sender,seen=Clock(),sequence=0}
        S.tx=nil; S.rx=nil; S.completed=nil; S.fingerprints={}; S.lastScan=-30
        Control("K","",sender,session)
    end
    S.active.seen=Clock(); S.config.peerLabel=sender
end
function S.Receive(prefix,message,channel,sender)
    if prefix~=PREFIX or not S.config or not S.config.enabled or not S.config.key or type(message)~="string" or #message>250 then return end
    if channel~="WHISPER" and channel~="CHANNEL" then return end
    local version,kind,id,session,target,seq,payload,mac=message:match("^(%d+)|(%a)|(%x+)|(%x+)|(%x*)|(%d+)|([^|]*)|(%x+)$")
    if version~="3" or not ValidID(id) or id==S.config.id or not ValidID(session) or #seq>9 or #mac~=32 then return end
    if S.retired[session] then return end
    if channel=="CHANNEL" and kind~="H" then return end
    if kind~="H" and target~=S.session then return end
    if kind=="H" and target~="" then return end
    -- Bound authentication work and sender buckets before HMAC verification.
    if type(sender)~="string" or #sender>180 then return end
    local bucket=S.rate[sender]
    if not bucket then
        local count=0; for _ in pairs(S.rate) do count=count+1 end
        if count>=32 then return end
        bucket={at=Clock(),count=0}; S.rate[sender]=bucket
    end
    if Clock()-bucket.at>1 then bucket.at=Clock(); bucket.count=0 end
    bucket.count=bucket.count+1; if bucket.count>25 then return end
    local body=message:sub(1,#message-33)
    if MAC(body)~=mac then return end
    if kind=="H" then
        if id==S.config.peerID then Control("A","",sender,session); Control("K","",sender,session)
        elseif not S.config.peerID and not S.config.joining then
            S.pending={id=id,sender=sender,session=session}; Status("Pairing request from "..sender..". Approve it in Sync settings.")
        end
        return
    end
    if kind=="A" and S.config.joining and not S.config.peerID then
        S.config.peerID=id; S.config.joining=false; Active(id,session,sender); Control("K","",sender,session)
        Status("Account paired. Syncing saved characters."); return
    end
    if id~=S.config.peerID then return end
    if kind=="K" then
        if S.active and S.active.session==session and tonumber(seq)<=S.active.sequence then return end
        Active(id,session,sender)
        S.active.sequence=tonumber(seq)
        if S.config.joining then S.config.joining=false end
        Notify(); return
    end
    local peer=S.active
    if not peer or peer.session~=session or peer.sender~=sender then return end
    seq=tonumber(seq); if seq<=peer.sequence then return end
    peer.sequence=seq; peer.seen=Clock()
    if kind=="R" then S.fingerprints={}; S.lastScan=-30; S.manual=true; return end
    if kind=="B" then
        local transfer,total,hash=payload:match("^(%x+):(%d+):(%x+)$"); total=tonumber(total)
        if not ValidID(transfer) or not total or total<1 or total>9100 or not hash or #hash~=64 then return end
        if S.completed and S.completed.id==transfer then Control("F",transfer,sender,session); return end
        if not S.rx or S.rx.id~=transfer then S.rx={id=transfer,total=total,hash=hash,parts={},ack=0,progress=Clock()} end
        Control("C",transfer..":"..S.rx.ack,sender,session)
    elseif kind=="C" then
        local transfer,ack=payload:match("^(%x+):(%d+)$"); ack=tonumber(ack)
        local tx=S.tx
        if tx and transfer==tx.id and ack and ack>=0 and ack<=tx.total and ack>=tx.ack then
            if ack>tx.ack then tx.progress=Clock() end
            tx.ack=ack; tx.next=math.max(tx.next,ack+1)
        end
    elseif kind=="D" then
        local transfer,index,part=payload:match("^(%x+):(%d+):([A-Za-z0-9+/=]+)$"); index=tonumber(index)
        local rx=S.rx
        if not rx or rx.id~=transfer or not index or index<1 or index>rx.total or #part>CHUNK then return end
        local duplicate=rx.parts[index]~=nil
        if not duplicate then rx.parts[index]=part; rx.progress=Clock() end
        while rx.parts[rx.ack+1] do rx.ack=rx.ack+1 end
        if index%4==0 or rx.ack==rx.total or duplicate then Control("C",rx.id..":"..rx.ack,sender,session) end
        Status("Receiving "..math.floor(rx.ack/rx.total*100).."% from "..sender)
        if rx.ack==rx.total then
            local encoded=table.concat(rx.parts); S.rx=nil
            if #encoded>1000000 or Crypto.sha256(encoded)~=rx.hash then Status("Sync checksum failed. Retrying."); return end
            local ok,c=pcall(function() return Data.Decode(Crypto.base64_to_bin(encoded)) end)
            local merged=false
            if ok then ok,merged=pcall(Data.Merge,Vault.db,id,c) end
            if ok and merged then
                S.config.lastSync=time(); S.config.lastCharacter=c.name; S.completed={id=rx.id}
                Control("F",rx.id,sender,session); Status("Synced "..c.name..". Waiting for changes.")
                if Vault.UI then Vault.UI.Refresh() end
            else Status("Received an invalid record; existing characters were kept.") end
        end
    elseif kind=="F" and S.tx and payload==S.tx.id then
        S.fingerprints[S.tx.key]={digest=S.tx.digest,sent=Clock()}; S.tx=nil
        S.lastScan=-30; Status("Account connected. Saved records are up to date.")
    end
end
