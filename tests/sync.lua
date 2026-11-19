local root=...
local now,elapsed,network=1700000000,0,{}
local clients={}
local function character(name,guid)
    return {key="3:Player-1-"..guid,name=name,ruleset="Legend",class="MAGE",className="Mage",
        race="Human",raceName="Human",sex=2,level=20,faction="Alliance",money=42000,lastSeen=now,
        snapshots={bags={updated=now,capacity=20,items={{id=2447,name="Peacebloom",count=4,quality=1,bound=false}}},
        bank={updated=now,capacity=40,items={{id=2447,name="Peacebloom",count=16,quality=1,bound=false}}}},professions={}}
end
local function client(name,chars)
    local env=setmetatable({},{__index=_G})
    env.time=function() return now end; env.GetTime=function() return elapsed end
    env.UnitGUID=function() return "Player-1-"..name end
    env.C_Timer={NewTicker=function() return {} end}
    env.JoinChannelByName=function(channel) env.joined=channel end
    env.LeaveChannelByName=function() env.joined=nil end
    env.GetChannelName=function(channel) return env.joined==channel and 7 or 0 end
    env.C_ChatInfo={RegisterAddonMessagePrefix=function() return true end,
        SendAddonMessage=function(prefix,message,channel,target)
            assert(#message<=250)
            network[#network+1]={from=name,prefix=prefix,message=message,channel=channel,target=target,joined=env.joined}
        end}
    local v={UI={Refresh=function() end}}
    for _,file in ipairs({"Model.lua","Libs/SHA.lua","SyncData.lua","Sync.lua"}) do
        setfenv(assert(loadfile(root.."/WarbandVaultForever/"..file)),env)("WVF",v)
    end
    v.db=v.Model.Open({characters=chars}); v.Sync.Initialize(); clients[name]={v=v,env=env}; return v
end
local a=client("First-Legend",{a=character("First","aa"),alt=character("FirstAlt","ab")})
local b=client("Second-Legend",{b=character("Second","ba")})
-- Canonical keys, as stored by the scanner.
for _,v in ipairs({a,b}) do local records={}; for _,c in pairs(v.db.characters) do records[c.key]=c end; v.db.characters=records end
assert(a.Crypto.sha256("abc")=="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
assert(a.Crypto.hmac(a.Crypto.sha256,string.rep(string.char(11),20),"Hi There")==
    "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7")
local function steps(n,drop)
    for _=1,n do
        elapsed=elapsed+0.15
        for _,c in pairs(clients) do c.v.Sync.Tick() end
        local batch=network; network={}
        for _,m in ipairs(batch) do
            if not drop or not drop(m) then
                for name,c in pairs(clients) do
                    if name~=m.from and (m.channel=="CHANNEL" and c.env.joined==m.joined or m.channel=="WHISPER" and m.target==name) then
                        c.v.Sync.Receive(m.prefix,m.message,m.channel,m.from)
                    end
                end
            end
        end
    end
end
assert(a.Sync.Create()); assert(not b.Sync.Join("wrong")); assert(b.Sync.Join(a.Sync.Code()))
steps(180)
assert(a.Sync.pending and not next(b.db.characters,"3:Player-1-ba"),"No records shared before approval")
a.Sync.Accept()
local dropped=false
steps(1600,function(m)
    if not dropped and m.message:find("|D|",1,true) then dropped=true; return true end
end)
assert(dropped)
assert(b.db.characters["3:Player-1-aa"] and b.db.characters["3:Player-1-ab"],"Whole account sync")
assert(a.db.characters["3:Player-1-ba"],"Bidirectional sync")
assert(b.db.characters["3:Player-1-aa"].snapshots.bank.items[1].count==16,"Bank contents preserved")
local own=a.db.characters["3:Player-1-aa"]
assert(not a.SyncData.Merge(a.db,b.db.sync.id,character("Overwrite","aa")),"A peer cannot overwrite local characters")
assert(a.db.characters[own.key].name=="First")
-- Malformed/forged packets never add or mutate a record.
local before=a.db.sync.lastSync
a.Sync.Receive("WVF3","3|D|abcdefabcdef|abcdefabcdef|abcdefabcdef|1|bad|"..string.rep("0",32),"WHISPER","Attacker")
assert(a.db.sync.lastSync==before)
assert(not pcall(a.SyncData.Decode,"t99999999:"))
assert(not pcall(a.SyncData.Decode,"s900000:"))
assert(not pcall(a.SyncData.Decode,"n1;garbage"))
local evil=character("Evil","ff"); evil.snapshots.bank.items[1].count=-2
assert(not pcall(a.SyncData.Clean,evil))
-- Preserve newer bank data if an older full record arrives.
local old=character("Second","ba"); old.snapshots.bank.updated=now-100; old.snapshots.bank.items[1].count=1
assert(a.SyncData.Merge(a.db,b.db.sync.id,old))
assert(a.db.characters[old.key].snapshots.bank.items[1].count==16)
-- Reload/switch the active character: account identity, key and trust survive.
local id,key,peer=b.db.sync.id,b.db.sync.key,b.db.sync.peerID
b.Sync.Initialize(); clients["SecondAlt-Legend"]=clients["Second-Legend"]; clients["Second-Legend"]=nil
-- Route outgoing packets from the newly logged-in alt.
clients["SecondAlt-Legend"].env.C_ChatInfo.SendAddonMessage=function(prefix,msg,channel,target)
    network[#network+1]={from="SecondAlt-Legend",prefix=prefix,message=msg,channel=channel,target=target,joined=clients["SecondAlt-Legend"].env.joined}
end
steps(1000)
assert(b.db.sync.id==id and b.db.sync.key==key and b.db.sync.peerID==peer)
assert(a.Sync.active.sender=="SecondAlt-Legend","An account's new character reconnects without pairing")
-- Changes propagate automatically after the character switch.
b.db.characters["3:Player-1-ba"].snapshots.bank.items[1].count=27
b.db.characters["3:Player-1-ba"].snapshots.bank.updated=now+1
steps(1000)
assert(a.db.characters["3:Player-1-ba"].snapshots.bank.items[1].count==27)
-- Automatic pause still permits an explicit manual sync.
b.db.sync.auto=false
b.db.characters["3:Player-1-ba"].money=50000
steps(120)
assert(a.db.characters["3:Player-1-ba"].money==42000)
b.Sync.Now(); steps(1000)
assert(a.db.characters["3:Player-1-ba"].money==50000)
-- Offline peers time out; cached records remain. Unlink removes only imports.
clients["SecondAlt-Legend"]=nil; steps(500)
assert(not a.Sync.active and a.db.characters["3:Player-1-ba"])
a.Sync.Unlink(); assert(not a.db.characters["3:Player-1-ba"] and a.db.characters["3:Player-1-aa"])
assert(not a.db.sync.key)
print("PASS: account pairing, HMAC vectors, two-way bags/bank sync, packet loss, alt reconnect, input guards, merge ownership, offline cache and unlink")

local iconRecord=character("Icons","abc")
iconRecord.snapshots.bags.items[1].icon="Interface\\Icons\\INV_Misc_Herb_02"
assert(a.SyncData.Clean(iconRecord).snapshots.bags.items[1].icon==iconRecord.snapshots.bags.items[1].icon)
iconRecord.snapshots.bags.items[1].icon="Interface\\AddOns\\Bad\\image"
assert(a.SyncData.Clean(iconRecord).snapshots.bags.items[1].icon==134400)
