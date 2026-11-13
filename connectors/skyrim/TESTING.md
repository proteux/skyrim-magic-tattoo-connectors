# Testing the Skyrim connector in game

How to put the player or an NPC into each state the connector's conditions read, and how to check what its effects change. MTF re-evaluates tiers every couple of seconds, so a change shows up shortly after closing the console.

The Papyrus log, with the connector's registration line and any script errors, is at `Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`.

## Statistic

The values are on the **General Stats** page of the journal. Set a tier one above a current value, then raise it in game: pick a lock for **Locks picked**, take a red-named item for **Items stolen**, or eat something for **Food eaten**. The tier should show once the journal shows the new value.

## Moon phase, Season, Holiday

All three come from the date, which the console can set:

```
set gamemonth to 11
set gameday to 25
set gamedayspassed to 24.6
```

That date is Saturalia (Evening Star 25), in winter. Days passed of 24.6 puts the moons at day 0 of their cycle, which is full. Each 3 days moves one phase: 27.6 is waning gibbous, 36.6 is new, 45.6 is waxing gibbous. After changing `gamedayspassed`, wait an hour so the sky catches up.

## In darkness and Hidden

**In darkness:** stand in a dark dungeon corner. A tier at 40 should show while the sneak eye is mostly closed, and stop when you light a torch or cast Candlelight.

**Hidden:** sneak behind an NPC who hasn't seen you; the tier shows while the eye is closed. Step in front of them and it should stop once the eye opens. A follower watching you doesn't count. Without Papyrus Extender, the tier never shows.

## Bounty in this hold and Wanted anywhere

In Whiterun, steal something in front of a guard, or set a bounty with Whiterun's crime faction:

```
player.setcrimegold 100 000267ea
```

Inside Whiterun city or Dragonsreach, a 40-gold Bounty tier should show. Travel to Riverwood (still Whiterun Hold) and it should still show. In Falkreath it should stop, while a Wanted anywhere tier keeps showing. Pay the fine and both stop.

## Sitting, Sleeping, and At a crafting station

- **Sitting:** sit on a chair or bench.
- **Sleeping:** check an NPC asleep in their bed at night, or the player in a bed with a sleep mod that keeps them lying down.
- **At a crafting station:** use a forge, a workbench, a grindstone, a smelter, a tanning rack, a cooking pot, an alchemy lab, or an arcane enchanter, and check the matching menu option plus "Any crafting station". Leaving the station ends it.

## Diseased and Cure disease

Get a disease from a mudcrab or a wolf, or add one directly:

```
player.addspell 000b8782
```

That's Rockjoint. **Diseased** should show. A tier with **Cure disease** removes it (and any others); check the Active Effects page.

## Just made a kill and Just leveled up

- **Just made a kill:** kill a chicken or a wolf. A 10-second tier shows right away and stops 10 real seconds later.
- **Several kills:** set At least to 3 and Seconds to 30. Kill two chickens: nothing shows. Kill a third within 30 seconds of the first and the tier shows, then stops 30 seconds after the first of those three kills, unless more kills keep three inside the last 30 seconds.
- **Just leveled up:** `player.advlevel` raises the level. On an NPC, `advlevel` on a selected NPC works too. The first check after a load only learns the current level and never fires.

## Spell in hand and Just cast a spell

Set the spell names to `Flames, Healing`. `player.addspell 00012fcd` adds Flames and `player.addspell 00012fcc` adds Healing if the character lacks them.

- **Spell in hand:** equip Flames in either hand and the tier shows, with the hands lowered too. Swap both hands to Sparks or a weapon and it stops. Typing `flames` in lower case still matches. With Match on is, `Flame` doesn't match; switch it to contains and it does, and `FLAME` should too.
- **Just cast a spell (player):** with Seconds at 10, cast Flames once; the tier shows and stops 10 real seconds after the last cast. Hold Flames for a while to see whether a long cast keeps it lit. Casting Sparks does nothing. A Flames scroll doesn't count. Try a power (Highborn, Battle Cry) with its name in the list: it counts.
- **Just cast a spell (follower):** give a follower Flames in one hand and Healing in the other (`addspell` on the selected follower, then let them equip it, or use an outfit mod). Put the preset on the follower and start a fight. The tier shows once they cast either. With only `Healing` in the list, a Flames cast should not show it, which checks that the hand read matches the hand cast. Save and reload during the tier: it stops, and comes back on the follower's next cast.

## Spell school in hand and Just cast from a spell school

- **Spell school in hand:** with Destruction picked, equip Flames and the tier shows; swap to Healing and it stops, until Restoration is picked. "Any spell school" shows for either, but not with only a power or a weapon.
- **Just cast from a spell school:** with Destruction and 10 seconds, cast Flames, Sparks, or Frostbite and the tier shows for 10 seconds; casting Healing does nothing. A spell from another mod counts under its own spell school. A power (Highborn) never counts, even with "Any spell school".
- **On a follower:** the same steps as Just cast a spell, with Destruction picked. Casting Healing from the other hand should not show it.

## Effects

Put the effect on a tier, make the tier show, then check:

- **Night vision:** the screen gets the Night Eye tint. It fades out when the tier stops, and comes back after a save and reload while the tier is still showing.
- **Shout recovery:** `player.getav shoutrecoverymult` reads 1.0 normally and 0.5 with a 50% tier. It goes back when the tier stops, including with two tiers and only one of them stopping.
- **Rested bonus:** the bonus appears on the Active Effects page. Sleep to replace it and it comes back within a few seconds. A bonus that was there before the tier stays when the tier goes.
- **Facial mood:** look at the actor's face, or the player's in third person. Talk to them and the expression comes back after the conversation.
- **Calm enemies:** hit a guard to start a fight, then show the tier. Nearby fighters stop. Bandits may attack again.
- **No fall damage:** jump off a cliff that would normally kill you. `player.hasperk xx01e801` (Dragonborn's load order index in place of `xx`) reads 1 while the tier shows.
- **Change the weather:** the sky changes to the chosen weather over a few seconds outdoors. It does nothing on an NPC tier.
- **Grant experience:** the bar under the level on the Skills menu grows by the chosen share each time the tier appears. `player.advlevel` empties the bar first so it's easy to read. At 100% the bar fills, and the level-up shows on the Skills menu. It does nothing on an NPC tier.
- **Magic aura:** see below.

## Magic aura

1. Put Enchanted glow, blue on a tier and show it. The actor glows; in first person, check in third person (F). It goes when the tier stops.
2. **Stacking:** show two tiers, both with Enchanted glow, blue. The glow should look the same as with one tier, not brighter. Stop one tier: the glow stays. Stop the other: it goes.
3. **Different auras:** one tier with Enchanted glow, blue and another with Steam. Both show, and stopping one leaves the other.
4. **After a load:** save and reload while the aura shows. It should come back within a few seconds, and only once (not brighter than before). Reload a second time and check again.
5. **On a follower:** put the preset on a follower and repeat steps 1 and 4.
6. **Leaving and coming back:** with the aura on a follower, wait in another cell until they're unloaded, then come back. Note whether the aura is still there; the game may drop it when the actor unloads, and the effect only replays it after a load.
7. **DLC auras:** try one Dawnguard aura (Mistform) and one Dragonborn aura (Dragon Aspect 1).

To preview an aura without a tier, select an actor in the console and use `pms` (play magic shader) with its FormID, from the list in `_auraSkyrimId`, `_auraDawnguardId`, or `_auraDragonbornId`, then `sms` with the same FormID to stop it. Dawnguard and Dragonborn FormIDs need their load order index in front, usually `02` and `04`:

```
pms 0005d608
sms 0005d608
```

## Reset

1. Show Shout recovery at 50%, Night vision, and a Magic aura on the player, and Facial mood on an NPC. Note `getav ShoutRecoveryMult` on the player.
2. Enter `setpqv MTF_Plugin_Skyrim ResetOnLoad 1`, save, and load that save. `getav ShoutRecoveryMult` is back to its value before the tier, Night vision and the aura are gone, the NPC's face relaxes, and the log shows `[MTF_Plugin_Skyrim] reset 2 actor(s)`.
3. `sqv MTF_Plugin_Skyrim` shows `::ResetOnLoad_var = 0`. Load again: nothing resets.
4. Stop the tiers and start them again. The changes come back, and stopping them clears them as usual.

## Reinstalling

1. Show Shout recovery at 50% and No fall damage on the player, and Facial mood on an NPC. Note `getav ShoutRecoveryMult`.
2. Disable `MTF_Plugin_Skyrim.esp`, load the save, stop the NPC's tier but leave the player's showing, and save again.
3. Enable the plugin and load that save. The log shows `had changes left from a load without this plugin, so they're undone first` for both actors. The NPC's face relaxes and stays. Within a few seconds the player's tiers apply again: `getav ShoutRecoveryMult` matches the noted value, not double it.
4. Stop the player's tiers. Shout recovery goes back to where it was before step 1, and falling hurts again.

## Upgrading

1. With 0.2.0 installed, show Shout recovery at 50% and a Magic aura on the player, and save. Note `getav ShoutRecoveryMult`.
2. Install this version and load that save. The aura plays as usual, `getav ShoutRecoveryMult` is unchanged, and the log has no `had changes left` line.
3. Stop the tiers. Both changes go back as usual.

## Registration

The first session after the plugin is added, the Papyrus log shows `[MTF_Main] Registered 'proteux-mtf.skyrim'` and `[MTF_Plugin_Skyrim] 0.2.1 registered` a few seconds after loading. The save remembers the registration, so later sessions log nothing; check the connector's state directly instead:

```
sqv MTF_Plugin_Skyrim
```

It should show the quest running, `::_registered_var = True`, and `ResolvedVersion` set to `0.2.1`. If MTF lists the plugin as "Catalog Only", the catalog loaded but the script didn't register; check that `MTF_Plugin_Skyrim.esp` is enabled in the load order.
