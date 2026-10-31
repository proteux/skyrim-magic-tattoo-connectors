# Connector candidates

Mods in the current Vortex profile (768 mod folders, checked October 2026) that a connector could hook into, with possible **conditions** (when a tier shows) and **effects** (what MTF runs while a tier shows; the events a tattoo can trigger in the other mod). The lists are ideas to scope a connector, not catalogs: check each one against the mod's scripts before writing it.

Left out on purpose:

- Mods MTF already bridges: OStim Standalone (`mtf.ostim`), OSL Aroused (`mtf.sla`), plus vanilla health and attributes, combat, magic, shouts, location, weather and followers (`mtf.attributes`, `mtf.combat`, `mtf.magic`, `mtf.dragonborn`, `mtf.world`). OAroused is superseded by OSL Aroused.
- Mods this repo already connects: Sacrosanct and Wet Function Redux (including the OSweat patch).
- Mods with no state of their own to read or change: textures, meshes, body and skin replacers, animation packs, engine and UI fixes, player homes and town interiors, followers, music, weathers, presets such as CowBred (a BodySlide preset only). Lyru's tattoo packs and the Warrior's Paints and Tribal Combatants overlays are content for MTF presets, not connector targets.

"Access" says how a connector would reach the mod. **Source shipped** means the `.psc` files are in the mod folder. **BSA** means the scripts are packed and need extracting or decompiling first. **DLL** means the logic is in an SKSE plugin, so a connector can only use what it exposes to Papyrus or through StorageUtil.

## Strong candidates

### Bathing in Skyrim (with Wash Me and HC BathAI)

Tracks dirt on the player and NPCs, and has a public API script (`mzinAPI`) plus interface scripts for OStim, OCum and FadeTats. Access: compiled scripts only, no source shipped.

Conditions:
- Dirtiness stage: clean, not dirty, dirty, filthy (exact, or dirtier, or cleaner)
- Dirtiness at least N%
- Bathed within the last N hours
- Currently bathing

Effects:
- Wash the skin (once)
- Dirty the skin by N% (once)
- Dirt build-up rate at N% (while shown)

### Wintersun - Faiths of Skyrim

Worship system with a chosen deity, favor and blessings. Access: BSA.

Conditions:
- Worships a chosen deity (menu)
- Favor or devotion at least N
- Deity's blessing is active
- Shrine prayer on cooldown
- Deity is displeased (in a penalty state)

Effects:
- Grant N favor (once)
- Restore the blessing (once)
- Ward against favor loss (while shown)

### Growl - Werebeasts of Skyrim

Werewolf and werebear overhaul. Pairs naturally with the Sacrosanct connector. Access: BSA.

Conditions:
- Is a werewolf, or a werebear
- Transformed into beast form
- Feeding or hunger stage
- Totem or ritual active (menu)
- Beast form perks earned, at least N

Effects:
- Sate the beast's hunger (once)
- Longer beast form, +N% (while shown)
- Ward against forced transformation (while shown)

### OCum Ascended (with OSquirt)

Stored cum per actor and cum overlays on the body. Access: source shipped. `OCumScript` has `GetCumStoredAmount`, `GetMaxCumStoragePossible`, `AdjustStoredCumAmount` and `CleanCumTexturesFromActor`, and the mod sends an `OCumAppliedCum` event with actor, target, amount and body area.

Conditions:
- Stored amount at least N% of the maximum
- Cum on the body, optionally by area (menu: face, chest, belly, and so on)
- Cum applied within the last N minutes

Effects:
- Refill storage by N% (once)
- Clean cum overlays from the body (once)
- Faster refill, +N% (while shown)

### OVirginity Reflowered

Per-actor virginity. Access: source shipped. `OVirginityScript` has `isVirgin`, `setVirginity` and `BreakHymen`.

Conditions:
- Is a virgin
- Lost virginity to the player

Effects:
- Restore virginity (once)
- Ward virginity: it can't be lost (while shown)

### Fill Her Up - OStim Edition

Inflation, plugging, and the cum-delivery quests. Access: compiled scripts (139 of them, no source shipped). Event manager scripts (`sr_InfEventManager`, `sr_InfEventPlugged`, `sr_InfEventStatus`) suggest it has a clear per-actor state to read.

Conditions:
- Inflation at least N%
- Plugged
- Belt worn
- Delivery quest active

Effects:
- Inflate by N% (once)
- Expel or deflate (once)
- Slower deflation, N% (while shown)

### OTracker - Thread Actors Recordkeeping

Records who each actor has been in OStim scenes with. Access: source shipped (`OTrackerScript`, small).

Conditions:
- Distinct partners at least N
- Has been with the player
- Has been with a named NPC (text)

Effects: none. It only records.

### OEndurance

Stamina drain and exhaustion during OStim scenes, with settings held in globals. Access: source shipped (`OEnduranceLibs`).

Conditions:
- Exhausted (stamina under OEndurance's exhaustion threshold)

Effects:
- Scene stamina drain at N% (while shown, changes `OEnduranceGlobalMultiplier`)
- Stamina regeneration at N% (while shown)

## Effect-only candidates

These have nothing worth testing as a condition, but give tiers a visible reaction.

### OBlush

Access: source shipped. `OBlushHandle` has `enableBlush(actor)` and `disableBlush(actor, node)`.

Effects:
- Blush (while shown)

### OTooTiredToMove

Access: source shipped. `OTTTMAPI` has global functions `setExpression`, `setFaceExpression`, `showTongue` and `clearExpression`.

Effects:
- Facial expression (while shown; menu of type and category, strength slider)
- Tongue out (while shown)

### OAhegao

Access: compiled script only. Likely just an expression effect, the same as OTooTiredToMove's, so pick one of the two.

## Worth a look

These could work, but the state is harder to reach or the fit is weaker.

### Ordinator, Apocalypse, Odin, Triumvirate

Perk and spell overhauls. Access: BSA, but conditions only need `HasPerk` and `HasSpell` on their forms, so no script access is needed.

Conditions:
- Owns at least N perks from an Ordinator tree (menu of trees)
- Has a named Ordinator perk (menu)
- Knows at least N Apocalypse or Odin spells
- Triumvirate archetype chosen (menu)

Effects:
- Grant a perk while shown (risky: Ordinator perks can carry scripts that don't expect removal)

### Ryn's Standing Stones

Reworked standing stones as abilities. Access: plugin only (no scripts), conditions check the stone abilities.

Conditions:
- Active standing stone (menu)

Effects:
- Swap the active stone (once)

### Devour

Vampire feeding during OStim scenes, with a blood bar. Better folded into the Sacrosanct connector than shipped on its own. Access: source shipped (`DevourLibs`, settings in globals).

Conditions:
- Fed during the current scene

Effects:
- Feeding drain time at N% (while shown)
- Drain is never lethal (while shown)

### Shadow of Skyrim

A nemesis system: enemies who beat you come back stronger. Access: compiled scripts (tracker quests `QF_1NemesisTrackerQuest` to `QF_5NemesisTrackerQuest`).

Conditions:
- Active nemeses at least N
- A nemesis is nearby

Effects: none obvious.

### Legacy of the Dragonborn

Museum collection progress. Access: BSA.

Conditions:
- Museum displays at least N, or N% complete
- Explorer's Guild founded

Effects: none obvious.

### Headhunter - Bounties Redone, and Missives

Bounty and job boards. Access: compiled scripts (Headhunter's `BQScript`, Missives' `_M_Quest*` scripts).

Conditions:
- A bounty or missive is active
- Bounties completed at least N

Effects: none obvious.

### Immersive Wenches for OStim REDUX

Wenches give class-based blessings after a scene (`lalawench_bless_class_*`). Access: compiled scripts.

Conditions:
- Has a wench blessing, optionally by class (menu: mage, archer, tank, and so on)

Effects:
- Grant a wench blessing (once)

### Hearthfire Multiple Adoptions

Access: BSA.

Conditions:
- Adopted children at least N

### Predator Vision

Night eye and thermal vision overhaul. Access: BSA.

Conditions:
- Predator vision active

### OBody NG

Body preset assignment. Access: source shipped. `OBodyNative` has `GetPresetAssignedToActor`, `AssignPresetToActor` and `ApplyPresetByName`, and can send naked and removing-clothes events (`RegisterForOBodyNakedEvent`, `RegisterForOBodyRemovingClothesEvent`).

Conditions:
- Actor has a named body preset (text)
- Naked (from OBody's naked event)

Effects:
- Apply a body preset (once)

### Sanguine's Trade, Body Change NG, Valhalla Combat, Underwear.dll

All four keep their logic in an SKSE DLL, so a connector depends on what each exposes to Papyrus. Check for Papyrus natives or StorageUtil keys before planning one.

- **Sanguine's Trade** (economy and work, with an OStim patch). Possible conditions: working, earnings at least N. Possible effects: earnings at N%.
- **Body Change NG** (body shape that changes over time). Possible conditions: weight or muscle at least N. Possible effects: shift weight or muscle by N.
- **Valhalla Combat** (stamina and stun rework). Possible conditions: stunned, or stun meter at least N%.
- **Underwear.dll** (underwear under armor). Possible condition: down to underwear. This matters for tattoos, since it says whether the skin is visible.

## Base game

Vanilla and DLC state that MTF's own plugins don't cover yet. These need no other mod, so a connector for them works for everyone.

The [base connector](../connectors/base/README.md) (`proteux-mtf.base`, "Base Extended") now covers statistics, moon phase, darkness, season, holidays, bounty, wanted, hidden, sitting, sleeping, crafting, diseased, just made a kill, and just leveled up. Its effects are night vision, shout recovery, cure disease, rested bonuses, facial mood, calm enemies, no fall damage, and weather. Actor scale lives in the [RaceMenu connector](../connectors/racemenu/README.md) (`proteux-mtf.racemenu`), together with BodySlide body shapes. Everything else in this section is still open.

MTF already has health, magicka and stamina, combat and hits, heavy or light cuirass, casting, burning, frozen, shocked and invisible, shouts and dragon souls, location type, weather, time of day, sprinting, sneaking, swimming, riding and bleedout, Lover's Comfort, followers, gold, and nearby factions or named NPCs.

Most of these read with plain Papyrus or SKSE calls; light level, for example, is SKSE's `Actor.GetLightLevel`. A few vanilla checks only exist as condition functions. Reaching those needs an ability spell in the ESP whose magic effect carries the condition, and the script then checks `HasMagicEffect`. That needs PluginGen to emit spell and magic effect records, not just the quest.

### What's visible

The most tattoo-relevant group, since it decides whether a tattoo can be seen at all.

Conditions:
- Naked: nothing in the body slot (`GetWornForm(0x4)` is `None`)
- Slot uncovered: hands, feet, head or body (menu)
- Wearing clothing, not armor
- Wearing gear with a keyword (menu: jewelry, circlet, Daedric, Dragonplate, and so on)
- Wearing a named item (text), for example the Amulet of Mara

### Sky and calendar

Conditions:
- Moon phase: full, new, waxing or waning, from the in-game day count. Good for vampire and werewolf tattoos.
- In darkness: light level below N
- Month or season (menu, from `GameMonth`)
- Day of the week, or a holiday such as the Witching Hour on the 13th of Frostfall (from `GameDay` and `GameMonth`)

### Who the actor is

Conditions:
- Level at least N
- Skill at least N (menu of skills). MTF can change skills but can't test them.
- Has a named perk (text), or at least N perks
- Race (menu)
- Active guardian stone (menu). Ryn's Standing Stones changes the abilities, so the list depends on which stones are installed.
- In werewolf beast form (by race; this works with Growl too)

### Allegiances and deeds

Read through faction ranks and quest stages.

Conditions:
- Guild rank: Companions (Circle), Thieves Guild (Guild Master, Nightingale), Dark Brotherhood (Listener), College of Winterhold (Arch-Mage), Bards College, Blades, Greybeards (menu)
- Civil War side: Imperial or Stormcloak, at least a given rank
- Dawnguard or Volkihar
- Thane of a hold (menu of nine), or thane of at least N holds
- Daedric artifacts owned, at least N, or a chosen Daedric quest done (menu)
- Main quest progress (menu of milestones)
- Married, or spouse nearby

### Crime and stealth

Conditions:
- Bounty in the current hold at least N (MTF can only change bounty)
- Wanted in any hold
- Hidden: sneaking and not detected by anyone nearby

### Statistics

`Game.QueryStat` reads the vanilla stats page, so a single condition covers a long menu.

Conditions:
- Stat at least N (menu: people, animals, undead, Daedra or dragons killed; locations discovered; dungeons cleared; books read; potions mixed; items stolen; pockets picked; locks picked; shouts used; days as a werewolf or vampire, and so on)

### What the actor is doing

Conditions:
- Sitting, or sleeping (`GetSitState`, `GetSleepState`)
- Using a crafting station: forge, enchanter, alchemy lab (menu, by furniture keyword)
- In dialogue
- Over-encumbered
- Diseased, or poisoned (by magic effect keyword)
- A rested or shrine blessing is active (menu)
- Hours awake at least N (tracked from sleep events)
- Just happened, for N seconds: made a kill, leveled up, learned a spell, picked a lock (the same pattern as MTF's `dragonsoul.absorbed`)

### Who is nearby

Conditions:
- An undead, Daedra, dragon or animal within N metres (by actor type keyword; MTF's nearby check only uses factions and names)
- For NPC tattoos: relationship to the player at least lover, ally, friend or acquaintance, or an enemy

### Effects

Effects:
- Night vision (while shown)
- Shout recovery at N% (while shown, `ShoutRecoveryMult`). MTF's Dragonborn plugin has conditions but no effects.
- Reset the shout cooldown, or grant N dragon souls (once)
- Cure disease or poison (once)
- Grant a rested bonus or shrine blessing (while shown)
- Facial mood: happy, angry, sad, and so on (while shown, `SetExpressionOverride`). A vanilla alternative to OBlush and OTooTiredToMove.
- Actor scale at N% (while shown)
- Calm or frighten enemies within N feet (once)
- Feather fall: no fall damage (while shown)
- Change the weather (once)
- Play an idle, such as a bow or a flex (once)
- Give gold or an item (once)

## Quick reference

| Mod | Access | Conditions | Effects |
| --- | --- | --- | --- |
| Bathing in Skyrim | compiled | dirt stage, dirt %, bathed recently, bathing | wash, dirty, dirt rate |
| Wintersun | BSA | deity, favor, blessing, cooldown, displeased | grant favor, restore blessing, favor ward |
| Growl | BSA | werewolf or werebear, transformed, hunger, totem, perks | sate hunger, longer beast form, transformation ward |
| OCum Ascended | source | stored %, on body by area, applied recently | refill, clean, refill rate |
| OVirginity | source | virgin, taken by player | restore, ward |
| Fill Her Up | compiled | inflation %, plugged, belt, quest active | inflate, expel, deflation rate |
| OTracker | source | partner count, with player, with NPC | none |
| OEndurance | source | exhausted | drain rate, regen rate |
| OBlush | source | none | blush |
| OTooTiredToMove | source | none | expression, tongue |
| Ordinator and friends | perks and spells | perk tree count, perk, spell count, archetype | grant perk (risky) |
| Ryn's Standing Stones | plugin | active stone | swap stone |
| Devour | source | fed this scene | drain time, non-lethal |
| Shadow of Skyrim | compiled | nemesis count, nemesis nearby | none |
| Legacy of the Dragonborn | BSA | displays, guild founded | none |
| Headhunter, Missives | compiled | job active, bounties done | none |
| Immersive Wenches | compiled | has blessing | grant blessing |
| Hearthfire Multiple Adoptions | BSA | children count | none |
| Predator Vision | BSA | vision active | none |
| OBody NG | source | has preset, naked | apply preset |
| Sanguine's Trade, Body Change NG, Valhalla Combat, Underwear.dll | DLL | depends on what each exposes | depends on what each exposes |
| Base game | Papyrus and SKSE | naked or slot uncovered, moon phase, darkness, season, level, skill, guild rank, thane, Daedric artifacts, bounty, hidden, stats, activity, nearby creature type | night vision, shout recovery, cure, blessing, mood, scale, calm, feather fall, weather |
