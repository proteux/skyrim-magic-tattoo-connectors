# MTF Plugin - Wet Function Redux

Let your magic tattoos glisten.

## Description

This patch connects [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF) to [Wet Function Redux SE](https://www.nexusmods.com/skyrimspecialedition/mods/78804). A tattoo tier can show only when the skin is soaked, once a sweat has built up, or while someone is drying off after a swim. A tier can also wet or dry the skin when it appears, or make everyone sweat and dry faster while it shows.

It adds a **Wet Function Redux** plugin to MTF's menu and to Magic Tattoos UI. Wet Function Redux itself is not changed.

## Requirements

- [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) 0.7.0 or later, and its requirements
- [Wet Function Redux SE](https://www.nexusmods.com/skyrimspecialedition/mods/78804). Built against 1.0 (script version 39). Works with the [OSweat](https://www.nexusmods.com/skyrimspecialedition/mods/108511) patch too.
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)

## Installation

Install with your mod manager and enable `MTF_Plugin_WetFunction.esp`. It is ESL-flagged and only lists `Skyrim.esm` and `MagicTattoosFramework.esp` as masters, so it can go anywhere after MTF. Wet Function Redux is found at runtime; if it isn't loaded, the plugin stays unregistered and does nothing.

## Conditions

Conditions work on any actor Wet Function Redux tracks, the player or NPCs. An actor it has never run on has no wetness, so every condition is false for them.

| Condition | Shows the tier while |
| --- | --- |
| Wetness | wetness is at least 0 to 100% of Wet Function's maximum ("cap" in its MCM) |
| Wetness stage | the skin is Dry, Sweaty, or Soaked, matched exactly, "or wetter", or "or drier" |
| Wetness trend | the actor is getting wetter, or drying off |
| Wet Function running | Wet Function's effect is running on the actor |

The stages use Wet Function's own "start" and "soaked" points. Wet Function holds its sweaty look a little longer while drying, so the visuals can lag slightly behind the stage condition. The trend is only known while Wet Function's effect runs on the actor.

## Effects

| Effect | Kind | Does |
| --- | --- | --- |
| Wet the skin | once | raises wetness by 1 to 100% of the maximum |
| Dry the skin | once | lowers wetness by 1 to 100% of the maximum |
| Wetness rate | while shown | Wet Function's global rate runs at 10 to 500%, for getting wet and drying alike |

Wetting and drying work on the player and NPCs, but only on actors Wet Function tracks. A forced wetness (the Force slider in Wet Function's MCM) overrides them, as it overrides Wet Function's own sources.

Wetness rate changes Wet Function's "Global rate multiplier", which applies to everyone, so it only does something on a player tier. Several tiers with it multiply together, and each puts its share back when it stops. Avoid moving the Global rate multiplier slider while such a tier is showing.

## Uninstalling

Take off any tattoo whose tiers use Wetness rate, so the multiplier is put back, then save, quit, and disable the plugin.

## Troubleshooting

The Papyrus log (`Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`) should show `[MTF_Main] Registered 'proteux-mtf.wetfunction'` a few seconds after loading a save. If it doesn't, check that Wet Function Redux and MTF are enabled and that `MTF_Plugin_WetFunction.esp` loads after `MagicTattoosFramework.esp`.

[TESTING.md](TESTING.md) walks through checking each condition and effect in game.

## Building from source

Run `make wetfunction` from the repository root (or `make` in this folder) to build and copy it straight into the game's Data folder, then restart Skyrim. `make uninstall-live wetfunction` removes those files. `make package wetfunction` writes the release zip with the same files (it needs a `CHANGELOG.md` entry for the version; the Nexus page is `nexus/description.bbcode`), and `make staging wetfunction` builds it as its own Vortex mod, **MTF Plugin - Wet Function Redux**, instead. See the [repository README](../../README.md) for requirements. The version in `VERSION` must match `MOD_VERSION` in `Scripts/Source/MTF_Plugin_WetFunction.psc`.

Wet Function Redux forms used: its MCM quest `WetFunctionMCM` (`WetFunction.esp` `0x800`), whose StorageUtil floats hold the settings (`wetnessStart`, `wetnessSoaked`, `wetnessCap`, `multGlobal`). Per-actor state comes from the StorageUtil floats `WetFunction_Actor_wetness`, `WetFunction_Actor_wetnessRate`, and `WetFunction_Actor_specular` on each actor.

## Credits

- Proteux, author
- The Wet Function Redux authors, and the OSweat author
- levchimik, for Magic Tattoos Framework
