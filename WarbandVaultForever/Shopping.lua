-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
local Shop={}; Vault.Shopping=Shop
local CALLER="WarbandVaultForever"
local function API() return Auctionator and Auctionator.API and Auctionator.API.v1 end
local function Read(fn,...)
    if type(fn)~="function" then return end
    local ok,value=pcall(fn,...); if ok then return value end
end
local function Name(id,fallback)
    local name=C_Item and Read(C_Item.GetItemInfo,id)
    return name or fallback or ("Item "..id)
end
function Shop.Build(result)
    local plan=Vault.Crafting.Plan(Vault.Crafting.Inventory(Vault.db,time(),Vault.db.settings.includeMail~=false),result.character,result.recipe)
    local list={name=result.recipe.name,character=result.character.name,items={},incomplete=plan.incomplete,uncertain=plan.uncertain,
        total=0,priced=0,buyLines=0,oldestAge=0}
    local api=API()
    for _,r in ipairs(plan.requirements) do
        local item={id=r.id,name=r.id and Name(r.id,r.name) or r.name,required=r.required,
            bags=r.bags or 0,bank=r.bank or 0,buy=r.accountMissing or r.required,providers={},unresolved=r.unresolved}
        for _,owner in ipairs(r.owners) do
            local record=owner.record
            local own=record.character.key==result.character.key
            if owner.available>0 then
                local remaining=owner.available
                for _,source in ipairs({"bags","bank","mail"}) do
                    local count=math.min(own and record[source] or record.transferableByLocation[source],remaining); remaining=remaining-count
                    if count>0 and (not own or source~="bags") then
                        item.providers[#item.providers+1]={name=record.character.name,source=source,count=count,
                            updated=record.updated[source],uncertain=not own and record.unknown>0}
                    end
                end
            end
        end
        if item.buy>0 then
            list.buyLines=list.buyLines+1
            local price=item.id and api and Read(api.GetAuctionPriceByItemID,CALLER,item.id)
            if type(price)=="number" and price>0 and price<1e13 then
                item.unitPrice=price; item.cost=price*item.buy; list.total=list.total+item.cost; list.priced=list.priced+1
                local age=Read(api.GetAuctionAgeByItemID,CALLER,item.id)
                if type(age)=="number" then item.priceAge=age; list.oldestAge=math.max(list.oldestAge,age) end
            end
        end
        list.items[#list.items+1]=item
    end
    return list
end
function Shop.Estimate(list)
    if list.buyLines==0 then return "No auction-house purchases needed from the saved records." end
    if list.priced==0 then return "No Auctionator prices cached for these materials." end
    return (list.priced<list.buyLines and "Known-price subtotal: " or "Rough AH cost: ")..Vault.Model.Money(list.total)..
        " / "..list.priced.." of "..list.buyLines.." materials priced"..
        (list.oldestAge>0 and " / oldest price "..list.oldestAge.."d" or "")..". Cached prices can change."
end
function Shop.Export(list)
    if list.incomplete then return false,"Open the profession and choose any required reagent options first." end
    local api=API()
    if not api or not api.CreateShoppingList or not api.ConvertToSearchString then return false,"Enable Auctionator with shopping-list API support, then try again." end
    local terms={}
    for _,item in ipairs(list.items) do
        if item.buy>0 then
            local name=item.id and Name(item.id,item.name)
            if not name or name:match("^Item %d+$") then
                if item.id and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(item.id) end
                return false,"Item names are loading. Try the Auctionator button again shortly."
            end
            local term=Read(api.ConvertToSearchString,CALLER,{searchString=name,isExact=true,quantity=item.buy})
            if not term then return false,"Auctionator could not create an item search." end
            terms[#terms+1]=term
        end
    end
    if #terms==0 then return false,"Nothing needs buying. Collect the supplies listed above." end
    -- Use a new list name; never replace an existing personal shopping list.
    Vault.db.shoppingSequence=(Vault.db.shoppingSequence or 0)+1
    local name="WVF "..list.name:sub(1,36).." "..time().."-"..Vault.db.shoppingSequence
    local ok=pcall(api.CreateShoppingList,CALLER,name,terms)
    return ok,ok and ("Created Auctionator list: "..name..". Open the AH and use Shopping to buy the materials.") or
        "Auctionator could not create the list. Check that the addon has finished loading."
end
function Shop.Open(result)
    local W=Vault.UI.widgets
    if not Shop.frame then
        local panel=W.Panel(UIParent,630,550,nil,"WarbandVaultForeverShopping")
        Shop.frame=panel; panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG"); panel:SetClampedToScreen(true)
        table.insert(UISpecialFrames,"WarbandVaultForeverShopping")
        W.Text(panel,"Materials and shopping",22,W.colors.gold):SetPoint("TOPLEFT",22,-20)
        local close=CreateFrame("Button",nil,panel,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() panel:Hide() end)
        local scroll,child=W.Scroll(panel,22,-63,556,350)
        Shop.text=W.Text(child,"",12,nil,545); Shop.text:SetPoint("TOPLEFT")
        Shop.child=child; Shop.scroll=scroll
        Shop.message=W.Text(panel,"",11,W.colors.muted,580); Shop.message:SetPoint("TOPLEFT",22,-432)
        W.Button(panel,"Create Auctionator list",207,30,function()
            local list=Shop.Build(Shop.result); local _,message=Shop.Export(list); Shop.message:SetText(message)
        end):SetPoint("BOTTOMLEFT",22,22)
        W.Button(panel,"Refresh",100,30,function() Shop.Open(Shop.result) end):SetPoint("BOTTOMLEFT",241,22)
        W.Button(panel,"Done",100,30,function() panel:Hide() end):SetPoint("BOTTOMRIGHT",-22,22)
    end
    Shop.result=result
    local list=Shop.Build(result); Vault.db.shoppingList=list
    local lines={list.name.." / "..list.character.." / one craft", "",Shop.Estimate(list),""}
    if list.incomplete then lines[#lines+1]="Recipe details are incomplete. Open the profession first." end
    if list.uncertain then lines[#lines+1]="Some old records have unknown binding. Update those characters before buying." end
    for _,item in ipairs(list.items) do
        lines[#lines+1]=item.name..": "..item.required.." required / Bags "..item.bags.." / Bank "..item.bank
        for _,p in ipairs(item.providers) do
            lines[#lines+1]="  Collect: "..p.name.." / "..p.source.." / "..p.count.." ("..Vault.Model.Age(p.updated,time())..")"..
                (p.uncertain and " / check binding" or "")
        end
        lines[#lines+1]=item.unresolved and "  Reagent choice needs confirmation." or item.buy>0 and
            ("  Buy at AH: "..item.buy..(item.cost and " / about "..Vault.Model.Money(item.cost) or " / price unknown")) or "  No purchase needed."
        lines[#lines+1]=""
    end
    Shop.text:SetText(table.concat(lines,"\n")); Shop.child:SetHeight(math.max(350,Shop.text:GetStringHeight()+25))
    Shop.scroll:SetVerticalScroll(0); Shop.message:SetText("Counts use saved bags, banks and eligible mail across local and linked accounts.")
    Shop.frame:Show()
end
