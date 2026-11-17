# Visual direction

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
