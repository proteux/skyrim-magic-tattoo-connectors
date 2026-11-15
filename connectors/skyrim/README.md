# MTF Plugin - Skyrim

More of Skyrim for your magic tattoos.

## Description

This patch adds base game conditions and effects to [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF), on top of the ones built into MTF. A tattoo tier can show once the player has picked a hundred locks, under a full moon, on Saturalia, while they have a bounty in the hold they're standing in, while hidden in a shadow, at a forge, with Flames in hand, or for a few seconds after a kill or a cast of Fireball. A tier can also grant night vision, shorten shout cooldowns, cure diseases, keep the Well Rested bonus, set the actor's facial expression, calm nearby enemies, prevent fall damage, change the weather, grant experience, wrap the actor in one of 80 magic auras, cast any spell on the actor, or give them a spell aura that burns their enemies or heals their side every second.

It adds a **Skyrim** plugin to MTF's menu and to [Magic Tattoos UI](https://www.nexusmods.com/skyrimspecialedition/mods/196803). It doesn't edit any game records.

## Requirements

- [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) 0.7.0 or later, and its requirements
- [SKSE](https://skse.silverlock.org/) and [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- Optional: [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854) for Hidden, Diseased, Cure disease, Calm enemies, and the nearby actors of Spell aura. Without it, the first four do nothing, and Spell aura only reaches the actor and the player.
- Optional: [Magic Tattoos Framework - SKSE UI](https://www.nexusmods.com/skyrimspecialedition/mods/196803), an editor in the SKSE Menu Framework menu, with live previews. It makes setting up tiers with these conditions and effects far easier, and 1.8.0 or later picks the spell for Cast a spell and Spell aura from a searchable list. With 1.8.3 or later, those spells are as strong as if whoever applied the tattoo cast them. With 1.8.6 or later, Spell aura fire-and-forget hits land at half strength, and the picker hides awkward spells unless you turn them back on.

Dawnguard and Dragonborn come with Skyrim Special Edition. The connector uses a few of their forms: the Aetherium Forge, the Staff Enchanter, Solstheim's bounty, the Black Book perk behind No fall damage, and some of the magic auras.

## Installation

Install with your mod manager and enable `MTF_Plugin_Skyrim.esp`. It is ESL-flagged and only lists `Skyrim.esm` and `MagicTattoosFramework.esp` as masters, so it can go anywhere after MTF.

## Conditions

Conditions marked "player" are always false on an NPC, because the game keeps that information for the player only.

| Condition | Shows the tier while |
| --- | --- |
| Statistic | (player) a General Stats value has reached 1 to 10,000. There are 88 to pick from, such as locks picked, items stolen, days as a vampire, and dragon souls collected |
| Moon phase | the moons are in one of the eight phases, or in any waxing or any waning phase |
| In darkness | the light on the actor is below a level, 40 by default |
| Season | it is winter, spring, summer, or autumn |
| Holiday | it is one of the 22 holidays on the in-game calendar, or any of them |
| Bounty in this hold | (player) the player has at least this much bounty in the hold they are in |
| Wanted anywhere | (player) the player has at least this much bounty in any hold, Solstheim included |
| Hidden | the actor is sneaking and no one nearby has detected them. The player's followers don't count |
| Sitting | the actor sits in furniture |
| Sleeping | the actor is asleep |
| At a crafting station | the actor is using a forge, workbench, grindstone, smelter, tanning rack, cooking pot, alchemy lab, enchanter, or any of them |
| Diseased | the actor has any disease, Sanguinare Vampiris included |
| Just made a kill | (player) the player has killed at least 1 to 20 people, animals, creatures, undead, daedra, or automatons in the last 1 to 120 seconds |
| Just leveled up | for 1 to 600 seconds after the actor gains a level |
| Spell in hand | the actor has a spell equipped in either hand, drawn or not, whose name is or contains one of a list |
| Just cast a spell | for 1 to 120 seconds after the actor casts a spell whose name is or contains one of a list |
| Spell school in hand | the actor has an Alteration, Conjuration, Destruction, Illusion, or Restoration spell equipped in either hand, or a spell of any of them |
| Just cast from a spell school | for 1 to 120 seconds after the actor casts a spell of that spell school, or of any spell school |

The General Stats page has no "dragons killed", so use Dragon souls collected for that. The moon phase follows the moons drawn in the sky: a 24-day cycle with three days per phase, starting full. Seasons go by month: Evening Star to Sun's Dawn is winter, First Seed to Second Seed is spring, Midyear to Last Seed is summer, and Hearthfire to Frostfall is autumn.

Bounty in this hold uses the hold of the actor's current location. Unnamed wilderness has no location, so between named places the condition is false even though guards there would arrest you. Just made a kill and Just leveled up learn the current count the first time MTF checks them after a load, so a kill made before that doesn't count.

Spell in hand and Just cast a spell take spell names as they appear in game, in any case, with commas between several: `Flames, Frostbite, Sparks` matches any of the three. Match picks whether the name must be the whole spell name (is) or only part of it (contains): with contains, `fire` matches Fireball, Firebolt, and Fire Rune, and also any spell from another mod with "fire" anywhere in its name. A game in another language, or a mod that renames a spell, needs the name it shows. Pair Spell in hand with MTF's Weapon Drawn condition to need the hands raised. For the player, Just cast a spell counts every spell the game casts, powers included, but not scrolls or staffs. For an NPC it counts spells cast from either hand, starting from the first time MTF checks the condition on them, so a cast before that doesn't count.

Spell school in hand and Just cast from a spell school go by the spell's costliest effect, the same spell school the game gives the skill experience to, and work with spells from other mods without any setup. Powers have no spell school, so only Just cast a spell can match them, by name and on the player. The two cast conditions watch NPCs the same way.

## Effects

| Effect | Kind | Does |
| --- | --- | --- |
| Night vision | while shown | (player) the Night Eye vision |
| Shout recovery | while shown | shout cooldowns last 10 to 300% as long as usual |
| Cure disease | once | cures every disease the actor has |
| Rested bonus | while shown | keeps Rested, Well Rested, or Lover's Comfort on the actor |
| Facial mood | while shown | holds a neutral, angry, fearful, happy, sad, surprised, puzzled, or disgusted expression at 0 to 100% strength |
| Calm enemies | once | everyone within 5 to 100 metres who is hostile to the actor, or fighting them, stops fighting |
| No fall damage | while shown | (player) falling does no harm |
| Change the weather | once | (player) the weather turns clear, cloudy, foggy, rainy, stormy, snowy, or to a blizzard |
| Grant experience | once | (player) gains 1 to 100% of the experience their current level needs |
| Magic aura | while shown | the actor wears one of 80 visual effects, listed below |
| Cast a spell | while shown | any spell lands on the actor (fire-and-forget at the spell's cast time, concentration every second; self buffs once), optionally paid for with their magicka |
| Spell aura | while shown | every second, a spell lands on actors within 1 to 50 metres: enemies for a harmful spell, the actor and their side for a helpful one; fire-and-forget hits at half strength |

How the effects behave:

- **Night vision.** Casting Night Eye while the tattoo shows and then letting it run out also ends the tattoo's vision until the next load. Toggling the tier back on restores it.
- **Shout recovery.** Several tiers add up, and the multiplier never goes below 5%.
- **Cure disease.** Like a Cure Disease potion, it also cures Sanguinare Vampiris before it turns into vampirism.
- **Rested bonus.** The bonus is put back every few seconds if sleeping replaces it or it expires. A bonus the actor already had when the tier appeared stays when the tier goes.
- **Facial mood.** The most recently shown mood wins, and it is put back after dialogue or combat changes the face.
- **Calm enemies.** Bandits, draugr, and other enemies that are always hostile may attack again.
- **No fall damage.** This uses the perk from the Black Book "The Hidden Twilight". If the player has already earned that perk, it stays when the tier goes.
- **Change the weather.** The new weather lasts until the climate changes it again on its own.
- **Grant experience.** The amount is a share of the current level, so 10% is always a tenth of a level, at level 5 or level 50. It goes to the character level, not to any skill, and is granted each time the tier appears.
- **Magic aura.** These are the game's own spell and power visuals, picked from the ones MTF's Shader effect doesn't already offer. Different auras stack. Two tiers with the same aura show it once, and it stays until both stop. The game doesn't save auras, so after a load each one comes back within a few seconds. When the tier stops it removes its aura from the actor, including the same visual from a real spell: Oakflesh cast while an Oakflesh tier shows loses its glow early when the tier goes.
- **Cast a spell and Spell aura.** These work with any spell, from the game or from other mods. Pick it from the searchable list in Magic Tattoos UI (awkward spells such as cloaks, wards, and summons are hidden unless you turn on Show awkward spells). In MTF's own menu, type it as `Plugin.esp|0xFormID`, such as `Skyrim.esm|0x012FCD` for Flames, or as the name of a spell the player knows. Magic Tattoos Tactical's own spells are left out, since a tier casting one could keep putting its tattoo back on. The spell's effects land straight on the target, with no casting animation or projectile, so pair a Magic aura with it for something to see. With Magic Tattoos UI 1.8.3 or later, the spell is as strong as if whoever applied the tattoo cast it, with their perks and Fortify (School) potions; without it, those may not count. Cast a spell keeps hitting the wearer while the tier is shown: fire-and-forget spells such as Firebolt at the spell's cast time (at least half a second), concentration such as Flames every second; self buffs such as Oakflesh land once. Spell aura pulses every second on nearby actors; fire-and-forget hits use half strength when UI 1.8.6 or later is present, and concentration stays at full strength per second. A spell counts as harmful when its main effect is hostile, as with Flames or Frostbite. A harmful aura hits everyone nearby who is hostile to whoever applied the tattoo, never the actor wearing it or the player's followers; a helpful one heals or buffs the actor and everyone nearby who isn't hostile to whoever applied it. The tattoo's own wearer counts as having applied it, unless a mod says otherwise (see For mod authors below). The game treats the applier as the caster, so the damage, the anger it causes, kill credit, and skill experience go to them. With Wearer pays, each cast or pulse costs the wearer the spell's magicka, and is skipped when they can't afford it. [Magic Tattoos Tactical](https://github.com/proteux/skyrim-magic-tattoo-tactical#spell-like-tattoos) has examples of spells that suit these effects, and some that don't.

The auras, by group:

| Group | Auras |
| --- | --- |
| Armor and elements | Oakflesh, Ironflesh, Shield spell, Shield Charge, Lightning cloak, Frost (light), Frost spikes, Ice Form, Steam, Webbed, Chaurus poison |
| Enchantments | Enchanted glow (red, blue, purple, green), Fire, Frost, and Shock enchantment, Elemental Fury, Bound weapon, Potion glow (fire, frost, magicka, shock, poison) |
| Illusion | Illusion (positive, negative), Fear, Paralysis, Berserker rage, Nightmare, Kyne's Peace, Animal Allegiance, Disguise |
| Absorb | Absorb magicka, Absorb stamina, Dragon soul absorb, Greybeard power |
| Ghosts and shadows | Ghost (violet), Wolf spirit, Call of Valor, Ghost (College of Winterhold), Nightingale spirit, Nightingale (corrupted), Nightingale shadow, Boethiah's shadow |
| Racial powers and healing | Dragonskin, Highborn, Command Animal, Ancestor's Wrath, Histskin, Adrenaline Rush, Healing circle, Mystic healing, Water breathing |
| Daedra and legends | Azura (radiant, corrupted), Boethiah, Sovngarde, Ancano's power, Flame Atronach |
| Dawnguard | Sun fire cloak, Sun fire, Soul Cairn ghost, Soul Cairn, Mistform, Drain Vitality, Auriel's fire |
| Dragonborn | Miraak's magic, Miraak's smoke, Dragon Aspect 1 to 3, Ash Shell, Ash Guardian, Whirlwind cloak, Mora's Grasp, Omen of danger, Apocrypha magic, Seeker |

Some were made for one creature or scene and may look different on a person; [TESTING.md](TESTING.md) has a quick way to preview them.

## Resetting

If a change from Shout recovery, Rested bonus, Facial mood, Night vision, No fall damage, Magic aura, or Spell aura ever stays after its tattoo is gone, you can undo everything those effects have changed. Open the console and enter:

```
setpqv MTF_Plugin_Skyrim ResetOnLoad 1
```

Then save and load that save. The player and every actor MTF tracks lose those changes, and the Papyrus log shows `[MTF_Plugin_Skyrim] reset N actor(s)`. The setting turns itself off again, so later loads don't reset. A tier that is still showing comes back the next time it starts.

## Uninstalling

Take off any tattoo whose tiers use Shout recovery, Rested bonus, Facial mood, Night vision, No fall damage, Magic aura, or Spell aura, so their changes are undone, or use the reset above. Then save, quit, and disable the plugin.

If you play on without the plugin and later add it back, its leftover changes are undone on the first load, and any tier still showing applies again a few seconds later.

## Troubleshooting

The Papyrus log (`Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`) should show `[MTF_Main] Registered 'proteux-mtf.skyrim'` a few seconds after loading a save. If it doesn't, check that `MTF_Plugin_Skyrim.esp` is enabled and loads after `MagicTattoosFramework.esp`. Errors mentioning `PO3_SKSEFunctions` mean Papyrus Extender is missing.

[TESTING.md](TESTING.md) walks through checking each condition and effect in game.

## For mod authors

A mod that puts presets on actors can say who applied each one, so Cast a spell and Spell aura credit that actor:

- **Where it lives:** a PapyrusUtil StorageUtil form on the wearer, under the key `mtf.applier.<preset>`, with the preset's name as MTF knows it.
- **What to do with it:** set it to the actor that applied the preset, with `StorageUtil.SetFormValue(wearer, "mtf.applier." + preset, applier)`, and unset it when the preset comes off.
- **What it changes:** who the game treats as the caster of these effects' spells, which decides who gets the anger, kill credit, skill experience, and any crime, and which side a Spell aura picks: a harmful aura hits actors hostile to the applier, and a helpful one actors who aren't.
- **When it's missing,** or the applier is dead, the wearer counts as the applier.

## Building from source

Run `make skyrim` from the repository root (or `make` in this folder) to build and copy it straight into the game's Data folder, then restart Skyrim. `make uninstall-live skyrim` removes those files. `make package skyrim` writes the release zip with the same files (it needs a `CHANGELOG.md` entry for the version; the Nexus page is `nexus/description.bbcode`), and `make staging skyrim` builds it as its own Vortex mod, **MTF Plugin - Skyrim**, instead. See the [repository README](../../README.md) for requirements. The version in `VERSION` must match `MOD_VERSION` in `Scripts/Source/MTF_Plugin_Skyrim.psc`.

A second script, `MTF_Plugin_Skyrim_Load`, sits on the player alias (`ALIAS_SCRIPTS` in `build.sh`) and restores the night vision and the facial mood after a load. The game doesn't save either one, and MTF doesn't replay effects. It also counts loads as sessions: each aura remembers the session it was played in, and the effect's tick plays it again when that is an earlier one. A new aura needs a menu id in the catalog and a branch in `_auraSkyrimId`, `_auraDawnguardId`, or `_auraDragonbornId`; never rename an id once released. It also passes the player's casts to Just cast a spell and Just cast from a spell school. NPCs' casts come from their `BeginCastLeft` and `BeginCastRight` animation events, read with the spell equipped in that hand. Finally, it runs the Spell cast and Spell aura tick through its own `OnUpdate` every 0.25 s while either is shown (auras still pulse once a second; casts use each spell's cast time), since the quest's updates belong to MTF's registration. A lost update is noticed by the effect's tick, which starts it again.

Game forms used, all looked up at runtime:

| What | Forms |
| --- | --- |
| Calendar | the `GameMonth`, `GameDay`, and `GameDaysPassed` globals |
| Bounty | the nine hold crime factions and hold locations, plus Solstheim's `DLC2CrimeRavenRockFaction` and `DLC2SolstheimLocation` |
| Crafting | the `CraftingSmithing*`, `CraftingSmelter`, `CraftingTanningRack`, `CraftingCookpot`, `isCookingSpit`, `isSmallCookingPot`, `isAlchemy`, and `isEnchanting` keywords, plus Dawnguard's Aetherium forge and Dragonborn's Staff Enchanter |
| Night vision | the `MagicNightEyeMainFX` image space modifier |
| Rested bonus | the `Rested`, `WellRested`, and `MarriageRested` abilities |
| No fall damage | the Dragonborn perk `DLC2BlackBookNoFallingDamagePerk` |
| Weather | the `SkyrimClear`, `SkyrimCloudy`, `SkyrimFog`, `SkyrimOvercastRain`, `SkyrimStormRain`, `SkyrimOvercastSnow`, and `SkyrimStormSnow` weathers |
| Magic aura | 80 effect shaders from Skyrim, Dawnguard, and Dragonborn, each named next to its FormID in `_auraSkyrimId`, `_auraDawnguardId`, and `_auraDragonbornId` |
| Cast a spell, Spell aura | whatever spell the tier names |

## Credits

- Proteux, author
- levchimik, for Magic Tattoos Framework
- powerofthree, for Papyrus Extender

## License

Copyright (C) 2026 Jack Whitehouse (proteux). Released under the [GNU General Public License v3.0 or later](../../LICENSE), with ABSOLUTELY NO WARRANTY. The download includes the license text and a notice in `SKSE/Plugins/MTF_Plugin_Skyrim`, and the Papyrus source in `Scripts/Source`.
