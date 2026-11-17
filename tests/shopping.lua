local root=...
time=function() return 10000 end
local v={}; for _,f in ipairs({"Model.lua","Crafting.lua","Shopping.lua","Professions.lua"}) do assert(loadfile(root.."/WarbandVaultForever/"..f))("WVF",v) end
local function char(key,name,bags,bank)
    return {key=key,name=name,realm="Home",faction="Alliance",snapshots={bags={updated=9000,items=bags},bank={updated=9000,items=bank}},professions={}}
end
local self=char("1:a","Crafter",{{id=1,count=2,bound=false}},{{id=1,count=3,bound=false}})
local alt=char("1:b","Mage",{{id=1,count=99,bound=true}},{{id=1,count=2,bound=false}})
v.db={characters={a=self,b=alt},settings={}}; v.currentKey=self.key
C_Item={GetItemInfo=function(id) return ({[1]="Peacebloom",[2]="Silverleaf",[3]="Empty Vial"})[id] end}
local terms,created
Auctionator={API={v1={GetAuctionPriceByItemID=function(_,id) return id==1 and 100 or id==2 and 200 or nil end,
    GetAuctionAgeByItemID=function() return 3 end,
    ConvertToSearchString=function(_,term) terms=terms or {}; terms[#terms+1]=term; return term.searchString.."x"..term.quantity end,
    CreateShoppingList=function(_,name,strings) created={name=name,terms=strings} end}}}
local result={character=self,profession={name="Alchemy"},recipe={id=123,name="Potion",reagents={{id=1,count=10},{id=2,count=4},{id=3,count=1}}}}
local list=v.Shopping.Build(result)
assert(list.items[1].buy==3,"Own bags, own bank and eligible alt bank reduce buying quantity")
assert(list.items[1].providers[2].name=="Mage" and list.items[1].providers[2].source=="bank","Soulbound alt bags must not be labelled as a supplier")
assert(#list.items[1].holdings==4,"Show own and alt bags and banks, including bound holdings")
local remote=char("1:remote","Linked",{{id=1,count=40,bound=false}},{{id=1,count=60,bound=false}})
remote.realm="Other"; remote.remoteAccount="linked"; v.db.characters.remote=remote
local elsewhere=v.Shopping.Build(result)
assert(#elsewhere.items[1].holdings==6 and elsewhere.items[1].buy==3,"Other realms are visible without reducing purchases")
v.db.characters.remote=nil
assert(list.total==1100 and list.priced==2 and list.buyLines==3,"Price subtotal uses only missing purchase quantities")
local batch=v.Shopping.Build(result,2)
assert(batch.count==2 and batch.items[1].required==20 and batch.items[1].buy==13 and batch.total==2900,"Shopping quantities and estimates scale with the selected batch")
assert(v.Shopping.Estimate(list):find("subtotal",1,true))
assert(v.Shopping.Export(list))
assert(#created.terms==3 and terms[1].quantity==3 and terms[1].isExact==true)
local previous=created.name; assert(v.Shopping.Export(list)); assert(previous~=created.name,"Repeated exports use unique list names")
Auctionator=nil; assert(not v.Shopping.Export(list)); assert(v.Shopping.Build(result).priced==0)
local called=0
local expectedCount,availableCount=1,1
v.Scanner={Refresh=function() end}; v.Professions.open=true
C_TradeSkillUI={GetBaseProfessionInfo=function() return {professionName="Alchemy"} end,
    GetRecipeInfo=function() return {learned=true} end,GetCraftableCount=function() return availableCount end,
    CraftRecipe=function(id,count) assert(id==123 and count==expectedCount); called=called+1 end}
assert(not v.Professions.Craft(result) and called==0,"Missing materials never call the craft API")
self.snapshots.bags.items={{id=1,count=10},{id=2,count=4},{id=3,count=1}}
assert(v.Professions.Craft(result) and called==1)
self.snapshots.bags.items={{id=1,count=30},{id=2,count=12},{id=3,count=3}}
availableCount=3; expectedCount=3
assert(v.Professions.Available(result)==3)
assert(v.Professions.Craft(result,3) and called==2,"Selected batch reaches the craft API")
assert(not v.Professions.Craft(result,4) and called==2,"Batch cannot exceed materials")
assert(not v.Professions.Craft(result,0) and not v.Professions.Craft(result,1.5),"Invalid counts rejected")
v.currentKey="1:other"; assert(not v.Professions.Craft(result) and called==2,"Offline owner cannot craft")
v.currentKey=self.key; v.Professions.open=false; assert(not v.Professions.Craft(result))
v.Professions.open=true; C_TradeSkillUI.IsTradeSkillLinked=function() return true end
assert(not v.Professions.Craft(result),"Foreign profession windows cannot craft")
print("PASS: procurement locations, bound exclusions, Auctionator quantities, partial cached prices, unique lists and guarded craft dispatch")
