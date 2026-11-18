local root = ...
local V={}; local function load(name) assert(loadfile(root.."/WarbandVaultForever/"..name..".lua"))("WVF",V) end
load("Model"); load("Crafting")
local M,F=V.Model,V.Crafting
local db=M.Open(); V.db=db
local a=M.Character(db,"3:a",{name="Aeris",realm="Home",faction="Alliance",class="MAGE",className="Mage",level=20})
local b=M.Character(db,"3:b",{name="Borin",realm="Home",faction="Alliance",class="DRUID",className="Druid",level=30})
local c=M.Character(db,"3:c",{name="Cora",realm="Away",faction="Alliance",class="MAGE",className="Mage",level=40})
a.professions={Alchemy={name="Alchemy",recipes={}}}; b.professions={Cooking={name="Cooking",recipes={}}}
local function item(id,count,bound) return {id=id,count=count,bound=bound,name="Reagent "..id,quality=1} end
M.Save(a,"bags",{item(1,1,false)},16,100)
M.Save(a,"bank",{item(1,4,false)},28,80)
M.Save(b,"bags",{item(2,8,false),item(3,50,true)},16,90)
M.Save(b,"bank",{item(1,10,false)},28,70)
M.Save(c,"bank",{item(2,999,false)},28,70)
local expired=item(2,99,false); expired.expires=10
local cod=item(2,50,false); cod.cod=true
M.Save(b,"mail",{expired,cod,item(2,3,false)},3,60)
local index=F.Inventory(db,100,true)
local bankPlan=F.Plan(index,a,{reagents={{id=1,name="Copper",count=5}}})
assert(bankPlan.bags==0 and bankPlan.personal==1 and bankPlan.account==3,
    "Owner bank and alt bank both contribute, independently from bags")
assert(bankPlan.requirements[1].bank==4 and bankPlan.requirements[1].owners[1].record.character==b,
    "Plan identifies the character with bank materials")
local altPlan=F.Plan(index,a,{reagents={{id=2,count=10}}})
assert(altPlan.account==1 and altPlan.requirements[1].total==11,
    "Alt bags and valid mail count; expired/COD mail and other realms do not")
assert(F.Plan(F.Inventory(db,100,false),a,{reagents={{id=2,count=10}}}).account==0,
    "Mailbox material setting is respected")
assert(F.Plan(index,a,{reagents={{id=3,count=1}}}).account==0, "Soulbound alt materials are not transferable")
local repeated=F.Plan(index,a,{reagents={{id=1,count=3},{id=1,count=3}}})
assert(#repeated.requirements==1 and repeated.personal==0 and repeated.account==2,
    "Repeated reagent requirements are combined before checking stock")
assert(#M.Characters(db,"name",{class="MAGE",minLevel=30})==1, "Class and level filters combine")
assert(M.Characters(db,"name",{profession="Cooking"})[1]==b, "Profession filter")
assert(#M.Characters(db,"name",{query="aeris alchemy",realm="Home",faction="Alliance"})==1,
    "Character search includes professions and combines with realm/faction")
assert(#M.Find(db,nil,"all","",nil,{[a.key]=true})==2, "Item views follow allowed character scope")
local unknown=F.Plan(index,a,{reagents={{count=1,choices={{id=1},{id=2}}}}})
assert(unknown.incomplete and unknown.account==0, "Alternative reagents never produce a false ready result")

time=function() return 200 end
C_Item={GetItemInfo=function(id) return "Item "..id,"item:"..id,1,1,1,"Trade Goods","",20,"",123 end,
    RequestLoadItemDataByID=function() end}
Enum={CraftingReagentType={Basic=1}}
V.Scanner={Identity=function() return a end}
GetProfessions=function() return nil,2 end -- Deliberate empty primary-profession slot.
GetProfessionInfo=function() return "Alchemy",123,15,75,0,0,171 end
load("Professions")
local P=V.Professions
P.Skills(); assert(a.professions.Alchemy.rank==15, "Profession scan handles nil gaps")
local linked=false
C_TradeSkillUI={
    IsTradeSkillLinked=function() return linked end,
    GetBaseProfessionInfo=function() return {professionName="Alchemy",professionID=171,skillLevel=15,maxSkillLevel=75} end,
    GetAllRecipeIDs=function() return {101,102} end,
    GetRecipeInfo=function(id) return {name="Potion "..id,learned=id==101} end,
    GetRecipeSchematic=function() return {outputItemID=201,quantityMin=1,reagentSlotSchematics={
        {reagentType=1,quantityRequired=5,reagents={{itemID=1}}},
        {reagentType=2,quantityRequired=1,reagents={{itemID=2}}}}} end,
    GetRecipeItemLink=function() return "item:201" end,
}
P.open=true; P.Scan()
assert(a.professions.Alchemy.recipes[101] and not a.professions.Alchemy.recipes[102], "Only learned modern recipes are saved")
assert(#a.professions.Alchemy.recipes[101].reagents==1, "Optional reagent slots are not treated as mandatory")
local saved=a.professions.Alchemy.recipes
linked=true; P.Scan(); assert(a.professions.Alchemy.recipes==saved, "Foreign profession links cannot overwrite player recipes")
linked=false
a.professions.Alchemy.recipes[202]={id=202,name="Older potion",reagents={}}
C_TradeSkillUI.GetRecipeInfo=function(id) if id==101 then return {name="Potion",learned=true} end end
P.Scan(); assert(a.professions.Alchemy.recipes[202], "Unloaded learned flags preserve previous recipes")
C_TradeSkillUI=nil
GetTradeSkillLine=function() return "Alchemy",15,75 end
GetNumTradeSkills=function() return 2 end
GetTradeSkillInfo=function(i) if i==1 then return "Potions","header" else return "Potion","optimal" end end
GetTradeSkillRecipeLink=function() return "enchant:101" end
GetTradeSkillItemLink=function() return "item:201" end
GetTradeSkillNumReagents=function() return 1 end
GetTradeSkillReagentInfo=function() return "Copper",123,5 end
GetTradeSkillReagentItemLink=function() return "item:1" end
P.Scan()
assert(a.professions.Alchemy.recipes[202] and a.professions.Alchemy.partial, "Legacy filtered scans merge instead of deleting hidden recipes")
assert(a.professions.Alchemy.recipes[101].reagents[1].id==1, "Legacy reagent links resolve to item IDs")
P.open=false; GetNumTradeSkills=function() return 0 end
P.Scan(); assert(a.professions.Alchemy.recipes[101], "Closing the profession preserves recipes")
print("PASS: profession APIs, learned/foreign guards, character filters, bank/alt materials, binding and mail exclusions")

-- Recreate the module as on relog, with saved recipes but no loaded skill slots.
a.professions.Cooking={name="Cooking",recipes={[303]={id=303,name="Meal",reagents={}}}}
local alchemy=a.professions.Alchemy.recipes
local cooking=a.professions.Cooking.recipes
load("Professions"); P=V.Professions
GetProfessions=function() return nil end
P.Skills()
assert(a.professions.Alchemy.recipes==alchemy and a.professions.Cooking.recipes==cooking,
    "Empty login metadata must preserve every saved profession and recipe")
GetProfessions=function() return 1,2 end
GetProfessionInfo=function(index) if index==1 then return "Alchemy",123,16,75,0,0,171 end end
P.Skills()
assert(a.professions.Alchemy.rank==16 and a.professions.Cooking.recipes==cooking,
    "Partially loaded profession metadata preserves recipes in missing slots")
GetProfessionInfo=function(index)
 if index==1 then return "Alchemy",123,16,75,0,0,171 end
 return "Cooking",456,10,75,0,0,185
end
P.Skills()
assert(a.professions.Alchemy.recipes==alchemy and a.professions.Cooking.recipes==cooking)
assert(#F.Recipes(M.Open(db),a.key,nil,"")>=3,"Saved recipes stay browseable after login without reopening professions")
