# Testing the RaceMenu connector in game

How to check what each effect changes. MTF re-evaluates tiers every couple of seconds, so a change shows up shortly after the tier starts or stops showing.

The Papyrus log, with the connector's registration line and any script errors, is at `Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`.

## Actor scale

Put Actor scale at 150% on a tier and make it show. The actor should be clearly taller, in third person and first person for the player. Stop the tier and they go back to their usual size.

- With two tiers at 150% and 50%, the actor is 75% of their usual size. Stop the 50% tier and they grow to 150%.
- Change RaceMenu's height slider while the tier shows. Both apply together.
- Save and reload while the tier shows. The size stays.

## Body shape

Use a female actor with a CBBE 3BA body built with morphs. Every change logs `[MTF_Plugin_RaceMenu] body morphs on <name>: <slider>=<value> ...` (or `none` when cleared) in the Papyrus log, so check there first if nothing seems to happen. No line means the effect never ran; a line with no visible change means the body has no morphs.

Start with **Bigger bust** at 100%, which moves the single `Breasts` slider by 100 and is easy to see. Stop the tier and the bust goes back to its preset size. **Smaller bust** at 100% should shrink it the same way, through `BreastsSmall`. With both on two tiers at once, they offset each other. Then try Muscular:

1. Put Body shape, Muscular, at 100% on a tier and make it show. Arms, abs, back, legs, and pecs should firm up within a second or two.
2. Lower the strength to 25% on a second tier, then stop the first. The body should ease down to the lighter build rather than snap back to normal.
3. Stop the last tier. The body goes back to its preset.
4. With an OBody preset assigned, the muscles add to the preset. Also reassign the preset in OBody's menu while the tier shows and note whether the muscles survive; if OBody clears them, they come back the next time the tier starts.
5. Save and reload while the tier shows. The shape stays.

Then go through the rest of the menu at 100%, one tier at a time, and check that each changes the part it names. The README lists the sliders each shape moves, and the log line shows them as they're set. Pregnant and Chubby are the most visible; Perkier and Saggier bust are subtler, so compare against the same pose. If a shape looks wrong for your body, note its log line: the weights are a first guess and easy to adjust.

On a male actor or a BHUNP body, nothing should change, and the Papyrus log should stay free of errors.

## Registration

The first session after the plugin is added, the Papyrus log shows `[MTF_Main] Registered 'proteux-mtf.racemenu'` and `[MTF_Plugin_RaceMenu] 0.1.0 registered` a few seconds after loading. The save remembers the registration, so later sessions log nothing; check the connector's state directly instead:

```
sqv MTF_Plugin_RaceMenu
```

It should show the quest running, `::_registered_var = True`, and `PlayerRef` filled in. If MTF lists the plugin as "Catalog Only", the catalog loaded but the script didn't register; check that RaceMenu is installed and `MTF_Plugin_RaceMenu.esp` is enabled.
