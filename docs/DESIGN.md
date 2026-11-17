# Visual direction (alpha 2)

The inventory sits inside an illustrated open leather satchel. Brass clasps,
stitched hide, carved borders, and inset item pockets give it the feel of an
object in the game. Keep the portrait roster visible beside the bag.

Palette: dark hide `#251A14`, leather `#4A3020`, worn brass `#C99B4C`,
ivory text `#EFE2C6`, muted parchment `#B8A58A`, rune blue `#6BB1CE`.
Friz Quadrata carries the title and character names. Use the standard game font
for quantities and instructions. Text stays left aligned.

The satchel is the focal point. Keep the header shallow, use small native-style
controls, and remove the slogan and repeated explanations. Put setup and storage
limits behind Help. Empty banks should say whose bank to visit.

Opening uses a short fade and a rising leather flap, accompanied by WoW's
backpack sound. Item hover uses a warm rim glow; the selected character has a
brass marker. Effects stop when the window closes. Sound and motion can be
disabled separately. No perpetual particle effects or moving item targets.

The vault button attaches beside the Blizzard bags bar without changing bag
buttons or their bindings. It opens the same window as the minimap shortcut.

Review: the old flat dashboard panels do not fit this brief. The bag silhouette
and hardware now carry the design; labels stay plain and short.

## Original layout reference

Warband Vault Forever is an in-game account inventory ledger. A character roster
stays visible while the selected character's possessions occupy the main pane.
The illustration is confined to the title strip so items remain easy to read.

Palette: vault stone `#101D2B`, inset stone `#172838`, aged gold `#D3AD68`,
parchment text `#EEE6D4`, secondary text `#A8BCCB`, cold blue `#59B9DE`.
WoW's built-in Friz Quadrata carries titles; its default readable game font
carries names and quantities. Class colors identify characters and item quality
colors frame items, with text labels and tooltips supplying the same information.

Layout, left aligned:

```
+---------------------------------------------------------------------+
| vault emblem / Warband Vault Forever             illustrated chamber |
| recorded gold / characters / recorded stacks                         |
+------------------------+--------------------------------------------+
| All characters         | portrait / name / level / realm / gold      |
| Name or gold sort      | All / Bags / Bank / Equipment / Mail         |
|                        | search                           quality     |
| portrait / name / gold | item grid with quantities and quality edges |
| portrait / name / gold |                                            |
| ... scrollable roster  | freshness / missing-data guidance            |
+------------------------+--------------------------------------------+
| Snapshot explanation                        Refresh / UI scale       |
+---------------------------------------------------------------------+
```

Review against the brief: use the generated vault art as the single focal point,
without decorative animation or repeated stat cards. Maintain useful row density
and generous item targets. Preserve native item tooltips and Escape behavior.
Scale the window to the screen and provide a user scale control.
