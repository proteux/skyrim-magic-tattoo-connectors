# MTF Plugin - Sacrosanct

Let your magic tattoos feel the thirst.

## Description

This patch connects [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF) to [Sacrosanct - Vampires of Skyrim](https://www.nexusmods.com/skyrimspecialedition/mods/3928). A tattoo tier can show only when you are Blood Starved, when you have just fed, once you reach a vampire rank, or while you soar as a Vampire Lord. A tier can also do vampiric things while it shows: sate your thirst, ward you from the sun, or speed your path to the next rank.

It adds a **Sacrosanct** plugin to MTF's menu and to Magic Tattoos UI. Sacrosanct itself is not changed.

## Requirements

- [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) 0.7.0 or later, and its requirements
- [Sacrosanct - Vampires of Skyrim](https://www.nexusmods.com/skyrimspecialedition/mods/3928). Built against 5.17.0.
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- Dawnguard

## Installation

Install with your mod manager and enable `MTF_Plugin_Sacrosanct.esp`. It is ESL-flagged and only lists `Skyrim.esm` and `MagicTattoosFramework.esp` as masters, so it can go anywhere after MTF. Sacrosanct is found at runtime; if it isn't loaded, the plugin stays unregistered and does nothing.

## Conditions

| Condition | Shows the tier while |
| --- | --- |
| Is a vampire | the actor is a vampire. Works on NPCs too. |
| Vampire Lord form | the actor is a Vampire Lord. Works on NPCs too. |
| Thirst stage | your thirst is Sated, Thirsty, Parched, or Blood Starved, matched exactly, "or thirstier", or "or better fed" |
| Fed recently | you fed within the last 1 to 72 hours |
| Vampire rank | your rank is at least Fledgeling, Blooded, Mistwalker, Nightstalker, Nightlord, or Nightmaster |
| Rank progress | you are at least 0 to 100% of the way to your next rank |
| Hemomancy stage | you have learned at least 1 to 7 Hemomancy stages |
| Wassail | you have at least 1 to 100 Wassail |
| Vampire Lord perks | you have earned at least 1 to 34 Vampire Lord perks |
| Levitating | you are levitating in Vampire Lord form |

Apart from the first two, conditions describe the player vampire and are false for other actors and for a player who isn't a vampire.

## Effects

Effects work on the player while they are a vampire, and do nothing on NPCs.

| Effect | Kind | Does |
| --- | --- | --- |
| Sate thirst | once | sets your thirst to Sated, as feeding does |
| Deepen thirst | once | worsens your thirst by one stage |
| Grant rank age | once | adds 1 to 120 hours toward your next rank (scaled by Sacrosanct's Age Speed setting) |
| Quicken aging | while shown | you gain rank age 10 to 500% faster |
| Sun ward | while shown | the sun doesn't harm you |
| Masquerade ward | while shown | being Blood Starved doesn't turn people hostile, and any current hostility from it ends |
| Threshold ward | while shown | no Trespassing Curse |
| Grant Vampire Lord blood | once | adds 1 to 20 Vampire Lord blood points, earning perks the same way feeding does |

The three wards switch on the matching option in Sacrosanct's MCM while the tier shows, and put your own setting back when the last tier using that ward stops showing. Avoid changing those three options in the MCM while a ward tier is showing.

## Uninstalling

Take off any tattoo whose tiers use the wards or Quicken aging, so their changes are undone, then save, quit, and disable the plugin.

## Troubleshooting

The Papyrus log (`Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`) should show `[MTF_Main] Registered 'proteux-mtf.sacrosanct'` a few seconds after loading a save. If it doesn't, check that Sacrosanct and MTF are enabled and that `MTF_Plugin_Sacrosanct.esp` loads after `MagicTattoosFramework.esp`.

[TESTING.md](TESTING.md) lists console commands that put you into each thirst stage, rank, and Vampire Lord state, and check what each effect changes.

## Building from source

Run `make sacrosanct` from the repository root (or `make` in this folder) to build and copy it straight into the game's Data folder, then restart Skyrim. `make uninstall-live sacrosanct` removes those files. `make package sacrosanct` writes the release zip with the same files, and `make staging sacrosanct` builds it as its own Vortex mod, **MTF Plugin - Sacrosanct**, instead. See the [repository README](../../README.md) for requirements. The version in `VERSION` must match `MOD_VERSION` in `Scripts/Source/MTF_Plugin_Sacrosanct.psc`.

Sacrosanct FormIDs used (all in `Sacrosanct - Vampires of Skyrim.esp`): rank age `0x133B5E`, age speed `0x133B64`, rank threshold `0x133B65` and increment `0x133B66`, rank quest `0x133B4D`, hemomancy stage `0x059BA1`, Wassail `0x136314`, sun damage `0x10994B`, hate `0x1071A8`, and trespassing `0x133B72` toggles. Thirst and feeding go through vanilla `PlayerVampireQuest` (`Skyrim.esm` `0x0EAFD5`), and Vampire Lord state through `DLC1PlayerVampireQuest` (`Dawnguard.esm` `0x0071D0`).

## Credits

- Proteux, author
- Enai Siaion, for Sacrosanct
- levchimik, for Magic Tattoos Framework
