# MTF Plugin - Base Extended

More of Skyrim for your magic tattoos.

## Description

This patch adds base game conditions and effects to [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF), on top of the ones in MTF's own Base plugin. A tattoo tier can show once the player has picked a hundred locks, under a full moon, on Saturalia, while they have a bounty in the hold they're standing in, while hidden in a shadow, at a forge, with Flames in hand, or for a few seconds after a kill or a cast of Fireball. A tier can also grant night vision, shorten shout cooldowns, cure diseases, keep the Well Rested bonus, set the actor's facial expression, calm nearby enemies, prevent fall damage, change the weather, or grant experience.

It adds a **Base Extended** plugin to MTF's menu and to [Magic Tattoos UI](https://www.nexusmods.com/skyrimspecialedition/mods/196803). It doesn't edit any game records.

## Requirements

- [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) 0.7.0 or later, and its requirements
- [SKSE](https://skse.silverlock.org/) and [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- Optional: [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854) for Hidden, Diseased, Cure disease, and Calm enemies. Without it, those four do nothing.
- Optional: [Magic Tattoos Framework - SKSE UI](https://www.nexusmods.com/skyrimspecialedition/mods/196803), an editor in the SKSE Menu Framework menu, with live previews. It makes setting up tiers with these conditions and effects far easier.

Dawnguard and Dragonborn come with Skyrim Special Edition. The connector uses a few of their forms: the Aetherium Forge, the Staff Enchanter, Solstheim's bounty, and the Black Book perk behind No fall damage.

## Installation

Install with your mod manager and enable `MTF_Plugin_BaseExtended.esp`. It is ESL-flagged and only lists `Skyrim.esm` and `MagicTattoosFramework.esp` as masters, so it can go anywhere after MTF.

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
| Spell in hand | the actor has a named spell equipped in either hand, drawn or not |
| Just cast a spell | for 1 to 120 seconds after the actor casts a named spell |
| School in hand | the actor has an Alteration, Conjuration, Destruction, Illusion, or Restoration spell equipped in either hand, or a spell of any of them |
| Just cast from a school | for 1 to 120 seconds after the actor casts a spell of that school, or of any school |

The General Stats page has no "dragons killed", so use Dragon souls collected for that. The moon phase follows the moons drawn in the sky: a 24-day cycle with three days per phase, starting full. Seasons go by month: Evening Star to Sun's Dawn is winter, First Seed to Second Seed is spring, Midyear to Last Seed is summer, and Hearthfire to Frostfall is autumn.

Bounty in this hold uses the hold of the actor's current location. Unnamed wilderness has no location, so between named places the condition is false even though guards there would arrest you. Just made a kill and Just leveled up learn the current count the first time MTF checks them after a load, so a kill made before that doesn't count.

Spell in hand and Just cast a spell take spell names as they appear in game, in any case, with commas between several: `Flames, Frostbite, Sparks` matches any of the three. A game in another language, or a mod that renames a spell, needs the name it shows. Pair Spell in hand with MTF's Weapon Drawn condition to need the hands raised. For the player, Just cast a spell counts every spell the game casts, powers included, but not scrolls or staffs. For an NPC it counts spells cast from either hand, starting from the first time MTF checks the condition on them, so a cast before that doesn't count.

School in hand and Just cast from a school go by the spell's costliest effect, the same school the game gives the skill experience to, and work with spells from other mods without any setup. Powers have no school, so only Just cast a spell can match them, by name and on the player. The two cast conditions watch NPCs the same way.

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

## Uninstalling

Take off any tattoo whose tiers use Shout recovery, Rested bonus, Facial mood, Night vision, or No fall damage, so their changes are undone. Then save, quit, and disable the plugin.

## Troubleshooting

The Papyrus log (`Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`) should show `[MTF_Main] Registered 'proteux-mtf.base'` a few seconds after loading a save. If it doesn't, check that `MTF_Plugin_BaseExtended.esp` is enabled and loads after `MagicTattoosFramework.esp`. Errors mentioning `PO3_SKSEFunctions` mean Papyrus Extender is missing.

[TESTING.md](TESTING.md) walks through checking each condition and effect in game.

## Building from source

Run `make base` from the repository root (or `make` in this folder) to build and copy it straight into the game's Data folder, then restart Skyrim. `make uninstall-live base` removes those files. `make package base` writes the release zip with the same files (it needs a `CHANGELOG.md` entry for the version; the Nexus page is `nexus/description.bbcode`), and `make staging base` builds it as its own Vortex mod, **MTF Plugin - Base Extended**, instead. See the [repository README](../../README.md) for requirements. The version in `VERSION` must match `MOD_VERSION` in `Scripts/Source/MTF_Plugin_BaseExtended.psc`.

The script isn't called `MTF_Plugin_Base`, because MTF ships a script by that name. A second script, `MTF_Plugin_BaseExtended_Load`, sits on the player alias (`ALIAS_SCRIPTS` in `build.sh`) and restores the night vision and the facial mood after a load. The game doesn't save either one, and MTF doesn't replay effects. It also passes the player's casts to Just cast a spell and Just cast from a school. NPCs' casts come from their `BeginCastLeft` and `BeginCastRight` animation events, read with the spell equipped in that hand.

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

## Credits

- Proteux, author
- levchimik, for Magic Tattoos Framework
- powerofthree, for Papyrus Extender

## License

Copyright (C) 2026 Jack Whitehouse (proteux). Released under the [GNU General Public License v3.0 or later](../../LICENSE), with ABSOLUTELY NO WARRANTY. The download includes the license text and a notice in `SKSE/Plugins/MTF_Plugin_BaseExtended`, and the Papyrus source in `Scripts/Source`.
