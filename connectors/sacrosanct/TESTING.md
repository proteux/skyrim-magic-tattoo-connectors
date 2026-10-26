# Testing the Sacrosanct connector in game

Console commands for putting the player into each state the connector's conditions read, and for checking what its effects change. Names were read from Sacrosanct 5.17.0 and Dawnguard. The `cqf` lines call Sacrosanct's own functions, so the mod reacts as it would in play.

MTF re-evaluates tiers on a timer. To see a change right away, run this after any command:

```
cqf MTF_MainQuest EvalAndDrawActor player
```

## Becoming a vampire

Only needed if the test character isn't one yet:

```
cqf PlayerVampireQuest VampireChange player
```

## Thirst stage and Fed recently

`Devolve 1` moves thirst one stage worse each time, with Sacrosanct's message box each step.

```
cqf PlayerVampireQuest VampireFeed       ; Sated, and counts as fed just now
cqf PlayerVampireQuest Devolve 1         ; run once: Thirsty
cqf PlayerVampireQuest Devolve 1         ; twice: Parched
cqf PlayerVampireQuest Devolve 1         ; three times: Blood Starved (NPCs turn hostile unless hate is disabled)
sqv PlayerVampireQuest                   ; shows VampireStatus (1-4) and LastFeedTime
```

- **Fed recently:** feed, and a tier set to "6 hours" should pass. Wait 7 or more hours with the Wait menu (T) and it should fail. `Devolve 1` from Sated or Thirsty also moves the last feed time back a full day.
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

To test a real rank-up instead:

```
set SCS_Mechanics_Global_Age to 119
cqf SCS_Main500_Quest Age 2       ; age passes the threshold and Sacrosanct shows its message
```

Then sleep in a bed without being interrupted. Sacrosanct raises the threshold and opens the perk-choice menu.

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

## Lifecycle audit

After turning wards and Quicken aging on and off a few times:

```
cqf MTF_MainQuest DumpLifecycleAudit
cqf MTF_MainQuest ResetLifecycleAudit    ; start the count over
```

Any non-zero entry under `proteux-mtf.sacrosanct` in `Papyrus.0.log` means a deactivation missed something. The counters need MTF's Debug mode turned on in its MCM.

## Registration

`Papyrus.0.log` should show `[MTF_Main] Registered 'proteux-mtf.sacrosanct'` a few seconds after loading. If MTF lists the plugin as "Catalog Only", the catalog loaded but the script didn't register; check that `MTF_Plugin_Sacrosanct.esp` is enabled in the load order.
