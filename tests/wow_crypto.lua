local root=...
-- WoW's bit table does not include LuaBitOp's rotate functions.
local function bits(a,b,mode)
    a,b=a%2^32,b%2^32; local result,place=0,1
    for _=1,32 do
        local x,y=a%2,b%2
        if mode=="and" and x==1 and y==1 or mode=="or" and (x==1 or y==1) or mode=="xor" and x~=y then result=result+place end
        a,b,place=math.floor(a/2),math.floor(b/2),place*2
    end
    return result
end
local function many(mode,a,b,...)
    local value=bits(a,b,mode)
    if select("#",...)>0 then return many(mode,value,...) end
    return value
end
bit={band=function(...) return many("and",...) end,bor=function(...) return many("or",...) end,
    bxor=function(...) return many("xor",...) end,bnot=function(a) return 2^32-1-a%2^32 end,
    lshift=function(a,n) return (a*2^(n%32))%2^32 end,rshift=function(a,n) return math.floor(a%2^32/2^(n%32)) end}
local v={}; assert(loadfile(root.."/WarbandVaultForever/Libs/SHA.lua"))("WVF",v)
assert(v.Crypto.sha256("abc")=="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
assert(v.Crypto.hmac(v.Crypto.sha256,string.rep(string.char(11),20),"Hi There")==
    "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7")
print("PASS: SHA256 and HMAC on WoW's limited bit API")
