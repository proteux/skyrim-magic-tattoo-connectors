# Testing the RaceMenu connector in game

How to check what each effect changes. MTF re-evaluates tiers every couple of seconds, so a change shows up shortly after the tier starts or stops showing.

The Papyrus log, with the connector's registration line and any script errors, is at `Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`.

## Actor scale

Put Actor scale at 150% on a tier and make it show. The actor should be clearly taller, in third person and first person for the player. Stop the tier and they go back to their usual size.

- With two tiers at 150% and 50%, the actor is 75% of their usual size. Stop the 50% tier and they grow to 150%.
- Change RaceMenu's height slider while the tier shows. Both apply together.
- Save and reload while the tier shows. The size stays.

## Transitions

Set Transition to 10 seconds on a Bigger bust tier at 100%. When the tier starts, the bust should grow smoothly over about 10 seconds, slow at the start and end, and the log line appears when it's done. Stop the tier and it shrinks back the same way. Then:

- Stop the tier halfway through growing. It should turn around from where it is, not jump.
- Set Transition to 0. The change is instant, as before.
- Save mid-transition and reload. The body should land on the final shape within a moment of loading.
- Do the same with Actor scale.

If nothing ever moves gradually but instant changes work, check the log for errors from `MTF_Plugin_RaceMenu_Loop`.

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

## Hair color

Use an actor with pale or neutral hair, such as most KS Hairdos styles, so the tint is easy to see. Every change logs `[MTF_Plugin_RaceMenu] hair color on <name>: <node>=#RRGGBB ...` (or `none` when the hair goes back to its own color) once it finishes.

1. Put Hair color on a tier with a strong color such as pure green, Transition 0, Covers **Hair, brows and beard**. When it shows, the hair, brows and any beard turn green, and the log lists the hair node (and usually a hairline node) by its head part's editor ID. **This is the first thing to check:** if the log lists nodes but nothing changes, the tint isn't reaching the hair shader, and the effect needs a different approach.
2. Stop the tier. The hair, brows and beard go back to exactly their own color.
3. Set Covers to **Hair only**. Only the hair changes; brows and beard keep their color.
4. Set Transition to 10 seconds. The color should fade smoothly from the hair's own color to green and back. If it jumps at the end instead of fading, RaceMenu doesn't show unsaved overrides live, and steps need `ApplyNodeOverrides`; note it.
5. Show two Hair color tiers, red then blue. The hair is blue (the newer one); stop blue and it eases to red; stop red and it eases back to its own color.
6. While a tier shows, change the hairstyle at a barber or in RaceMenu (`showracemenu`). Within a couple of seconds the new hair takes the color too. Stop the tier: the new hair goes back to its own color.
7. Save and reload while the tier shows. The color stays. Reload mid-transition: it lands on the final color within a moment.
8. Equip a KS Wigs SMP wig and start the tier. The wig takes the color, and the `hair color on` line lists its `KSSMP_<name>`, `KSSMP_<name>_HL` and `Hairline` nodes along with the hair under it. Take the wig off and put it back on: within a couple of seconds the log shows `put back` lines and the wig is colored again. Stop the tier: the wig goes back to the actor's own hair color. If it doesn't change, the `hair debug` lines show which node names were tried and whether each exists.
9. Try an NPC follower too. NPC hair comes from their FaceGen head, so the log's node names should still match and the hair should change the same way.

## Hair color (any wig)

Needs powerofthree's Papyrus Extender. Every change logs `[MTF_Plugin_RaceMenu] hair tint on <name>: #RRGGBB` (or `none`) once it finishes. Don't run Hair color on the same actor at the same time.

1. Put Hair color (any wig) on a tier with pure green, Transition 0. When it shows, the hair, brows and beard turn green. **This is the first thing to check:** if the log line appears but nothing changes, `SetHairColor` isn't taking the pool's color record.
2. Stop the tier. The hair goes back to its own color. On the player, compare with RaceMenu's hair color: it should match.
3. Set Transition to 10 seconds. The color fades smoothly to green and back.
4. Show two tiers, red then blue. The hair is blue; stop blue and it eases to red; stop red and it eases back.
5. Equip a wig that Hair color misses (any wig that isn't KS, or a KS elf wig) and start the tier. The wig takes the color. Take it off and put it back on: within a couple of seconds it's green again.
6. Save and reload while the tier shows. The hair shows its own color briefly, then green again within a couple of seconds.
7. Show the tier on the player and two NPCs at once with different colors, Transition 5. Each actor keeps its own color, with no flicker of another's.
8. Uninstall test: disable powerofthree's Papyrus Extender and start the tier. The log shows `needs powerofthree's Papyrus Extender, which isn't installed` and nothing else happens.

## Reset

1. Show a Bigger bust tier and an Actor scale tier at 150% on the player, and a Body shape tier and a Hair color tier on an NPC.
2. Enter `setpqv MTF_Plugin_RaceMenu ResetOnLoad 1`, save, and load that save. Both actors go back to their own shape, size and hair color, and the log shows `[MTF_Plugin_RaceMenu] reset 2 actor(s)`.
3. `sqv MTF_Plugin_RaceMenu` shows `::ResetOnLoad_var = 0`. Load again: nothing resets.
4. Stop the tiers and start them again. The changes come back, and stopping them clears them as usual.

## Registration

The first session after the plugin is added, the Papyrus log shows `[MTF_Main] Registered 'proteux-mtf.racemenu'` and `[MTF_Plugin_RaceMenu] 0.2.0 registered` a few seconds after loading. The save remembers the registration, so later sessions log nothing; check the connector's state directly instead:

```
sqv MTF_Plugin_RaceMenu
```

It should show the quest running, `::_registered_var = True`, and `PlayerRef` filled in. If MTF lists the plugin as "Catalog Only", the catalog loaded but the script didn't register; check that RaceMenu is installed and `MTF_Plugin_RaceMenu.esp` is enabled.
