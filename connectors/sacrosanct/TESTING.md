# Testing the Sacrosanct connector in game

Console commands for putting the player into each state the connector's conditions read, and for checking what its effects change. Names were read from Sacrosanct 5.17.0 and Dawnguard.

Everything here uses Skyrim's own console commands: `set`/`show` for globals, `sqv`/`setpqv` for quest script variables, and `player.addspell`. Skyrim has no `cqf`/`cgf`/`cf` (those are Fallout 4 commands), so Sacrosanct's script functions can't be called directly. Where the real behaviour matters, the steps use normal play (waiting, sleeping, feeding) instead.

MTF re-evaluates tiers every couple of seconds, so a change shows up shortly after each command.

## Saving the console output

Run this first in each session. Everything the console prints afterwards, including the long `sqv` listings, is also written to `mtf-sacrosanct-console.txt` in the game folder (next to `SkyrimSE.exe`), where it can be read in full instead of scrolled:

```
scof "mtf-sacrosanct-console.txt"
```

Skyrim locks the file while it writes to it, so nothing else can read it until the game lets go. When you want the output read, point `scof` at another file, which closes the first, or quit the game:

```
scof "mtf-sacrosanct-console-2.txt"
```

The Papyrus log, with the connector's registration line and any script errors, is at `Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`.

## Becoming a vampire

Only needed if the test character isn't one yet. This gives Sanguinare Vampiris; wait 3 days (T) and Sacrosanct turns you.

```
player.addspell 000B8780
```

## Thirst stage and Fed recently

```
sqv PlayerVampireQuest                     ; shows VampireStatus (1-4) and LastFeedTime (in game days)
show GameDaysPassed                        ; the current time in game days, to compare with LastFeedTime
```

`sqv` lists the script variables first and ends with "N aliases for quest", so the variables scroll off the top. Read them in the `scof` file, or press Page Up in the console; they may be listed as `::VampireStatus_var` and `::LastFeedTime_var`.

Quick way, for testing conditions only. This changes the stage number the connector reads, but not Sacrosanct's stage abilities, which catch up on its next update:

```
setpqv PlayerVampireQuest VampireStatus 1  ; Sated
setpqv PlayerVampireQuest VampireStatus 2  ; Thirsty
setpqv PlayerVampireQuest VampireStatus 3  ; Parched
setpqv PlayerVampireQuest VampireStatus 4  ; Blood Starved
```

Real way: feed on a sleeping NPC to become Sated. To make thirst advance, move the last feed time back (example: GameDaysPassed is 120.5, set it 2 days earlier), then wait a few hours. Sacrosanct checks every 3 game hours, and each check has a chance to move one stage.

```
setpqv PlayerVampireQuest LastFeedTime 118.5
```

- **Fed recently:** feed, and a tier set to "6 hours" should pass. Set `LastFeedTime` to `GameDaysPassed` minus 0.3 (about 7 hours) and it should fail.
- **Thirst comparison:** try "Parched or worse" at each stage.

## Vampire rank and Rank progress

The connector counts ranks from the rank threshold, which starts at 120 and goes up by 120 at each rank-up. Rank progress is the age value divided by the threshold.

```
show SCS_Mechanics_Global_Age_Threshold        ; note this before changing it
set SCS_Mechanics_Global_Age_Threshold to 240  ; Blooded
set SCS_Mechanics_Global_Age_Threshold to 360  ; Mistwalker
set SCS_Mechanics_Global_Age_Threshold to 480  ; Nightstalker
set SCS_Mechanics_Global_Age_Threshold to 600  ; Nightlord
set SCS_Mechanics_Global_Age_Threshold to 720  ; Nightmaster
set SCS_Mechanics_Global_Age to 60             ; with threshold 120: 50% progress
```

Set the threshold back to the noted value afterwards, because Sacrosanct uses it to decide when the next real rank-up happens.

To test a real rank-up instead, put age just under the threshold and wait a few hours. Sacrosanct adds age on a timer and shows its message once age passes the threshold. Then sleep in a bed without being interrupted: Sacrosanct raises the threshold and opens the perk-choice menu.

```
set SCS_Mechanics_Global_Age to 119
```

## Hemomancy and Wassail

These only change the values the conditions read. They don't grant the spells or other Sacrosanct effects.

```
set SCS_VampireSpells_Hemomancy_Global_Stage to 3
set SCS_Mechanics_Global_Wassail_Current to 50
```

Feeding resets Wassail to 0.

## Vampire Lord

Transform with the Vampire Lord power. If the character doesn't have it, `player.addspell 0200283B` grants it; that ID assumes Dawnguard is load slot 02, which it normally is.

```
set DLC1VampireTotalPerksEarned to 5          ; Vampire Lord perks condition
show DLC1VampireLevitateStateGlobal           ; 2 = levitating; drawing or sheathing toggles it in Lord form
```

## Effects

Put the effect on a tier, make the tier show, then check the value.

```
show SCS_Mechanics_Global_Age                      ; Grant age: goes up by the amount times the age-speed setting
show SCS_Mechanics_Global_Age_GainMult             ; Quicken aging: 100 normally, raised while the tier shows, back to 100 after
show SCS_Mechanics_Global_DisableSunDamage         ; Sun ward: 1 while the tier shows, then back to your setting
show SCS_Mechanics_Global_DisableHate              ; Masquerade ward
show SCS_Mechanics_Global_DisableTrespassingCurse  ; Threshold ward
sqv PlayerVampireQuest                             ; Feed / Deepen thirst: VampireStatus changes
show DLC1VampireBloodPoints                        ; Vampire Lord blood: points go up
show DLC1VampireNextPerk
player.getav VampirePerks                          ; perk points awarded
```

## Start and stop

MTF's lifecycle audit (`DumpLifecycleAudit`) can't be run from Skyrim's console, so check continuous effects by hand. Switch between a tier with the effect and one without a few times, then confirm:

- `SCS_Mechanics_Global_Age_GainMult` is back to 100 (or whatever it was before).
- Each ward global is back to its MCM setting, including with two tiers using the same ward and only one of them stopping.

## Registration

The first session after the plugin is added, the Papyrus log shows `[MTF_Main] Registered 'proteux-mtf.sacrosanct'` and `[MTF_Plugin_Sacrosanct] 0.1.0 registered` a few seconds after loading. The save remembers the registration, so later sessions log nothing; look in the older `Papyrus.N.log` files, or check the connector's state directly:

```
sqv MTF_Plugin_Sacrosanct
```

It should show the quest running, `::_registered_var = True`, and every Sacrosanct global and quest filled in. If MTF lists the plugin as "Catalog Only", the catalog loaded but the script didn't register; check that `MTF_Plugin_Sacrosanct.esp` is enabled in the load order.
