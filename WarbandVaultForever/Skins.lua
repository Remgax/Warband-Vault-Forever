-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Remgax
local _, Vault = ...
local Skins = {}; Vault.Skins = Skins
local ART = "Interface\\AddOns\\WarbandVaultForever\\Assets\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"
Skins.list = {
    {id="satchel", name="Original Satchel", description="Illustrated leather bag, circular items and opening animation.",
        background=ART.."Leather", edge="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=16,
        colors={stone={0.145,0.102,0.078}, inset={0.29,0.19,0.125}, gold={0.79,0.61,0.30},
            text={0.94,0.89,0.78}, muted={0.72,0.65,0.54}, blue={0.42,0.69,0.81}, selected={0.38,0.25,0.14}},
        border={0.65,0.50,0.29}, buttonBorder={0.40,0.29,0.17}},
    {id="classic", name="Classic Blizzard", description="Traditional dark dialogue panels, gold headings and square item slots.",
        compact=true, background="Interface\\DialogFrame\\UI-DialogBox-Background",
        edge="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=16,
        colors={stone={0.16,0.14,0.11}, inset={0.10,0.09,0.07}, gold={1,0.82,0},
            text={0.96,0.94,0.88}, muted={0.72,0.70,0.65}, blue={0.50,0.75,1}, selected={0.27,0.22,0.11}},
        border={0.72,0.66,0.50}, buttonBorder={0.50,0.45,0.33}},
    {id="minimal", name="Minimal Dark", description="Plain charcoal panels, thin borders and a compact square item grid.",
        compact=true, background=WHITE, edge=WHITE, edgeSize=1,
        colors={stone={0.065,0.065,0.065}, inset={0.035,0.035,0.035}, gold={0.92,0.81,0.48},
            text={0.94,0.94,0.94}, muted={0.66,0.66,0.66}, blue={0.50,0.75,1}, selected={0.19,0.18,0.13}},
        border={0.34,0.34,0.34}, buttonBorder={0.30,0.30,0.30}},
}
local definitions, frames, fonts, textures = {}, {}, {}, {}
for _, skin in ipairs(Skins.list) do definitions[skin.id] = skin end
local active = Skins.list[1]
-- Keep palette tables stable: other UI modules hold references to these colors.
Skins.colors = {}
for key, color in pairs(active.colors) do Skins.colors[key] = {unpack(color)} end

function Skins.Valid(id) return type(id)=="string" and definitions[id]~=nil end
function Skins.Get(id) return id and definitions[id] or active end
function Skins.Current() return active end

function Skins.Style(frame, kind, id)
    local skin = Skins.Get(id) or Skins.list[1]
    local button = kind == "button"
    local inset = not skin.compact and (button and 3 or 5) or (skin.id=="minimal" and 1 or 4)
    frame:SetBackdrop({bgFile=skin.background,
        edgeFile=button and not skin.compact and "Interface\\Tooltips\\UI-Tooltip-Border" or skin.edge,
        edgeSize=button and not skin.compact and 10 or skin.edgeSize,
        tile=true, tileSize=256, insets={left=inset,right=inset,top=inset,bottom=inset}})
    frame:SetBackdropColor(unpack(skin.compact and skin.colors[kind=="inset" and "inset" or "stone"] or {1,1,1,1}))
    frame:SetBackdropBorderColor(unpack(button and skin.buttonBorder or skin.border))
end

function Skins.Register(frame, kind)
    frames[#frames+1]={frame=frame,kind=kind}; Skins.Style(frame,kind)
end

function Skins.Font(font, color)
    fonts[#fonts+1]={font=font,color=color}
end

function Skins.Tint(texture, color)
    textures[#textures+1]={texture=texture,color=color}
    texture:SetVertexColor(unpack(color))
end

function Skins.Apply(id)
    active = definitions[id] or Skins.list[1]
    for key, color in pairs(active.colors) do
        for i=1,3 do Skins.colors[key][i]=color[i] end
    end
    for _, entry in ipairs(frames) do Skins.Style(entry.frame,entry.kind) end
    for _, entry in ipairs(fonts) do entry.font:SetTextColor(unpack(entry.color)) end
    for _, entry in ipairs(textures) do entry.texture:SetVertexColor(unpack(entry.color)) end
end
