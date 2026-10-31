# MTF Plugin - RaceMenu

Tattoos that change the body wearing them.

## Description

This patch connects [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF) to [RaceMenu](https://www.nexusmods.com/skyrimspecialedition/mods/19080). A tattoo tier can make the actor bigger or smaller, or reshape their body with BodySlide sliders while it shows, for example a muscular build on a warrior's mark.

It adds a **RaceMenu** plugin to MTF's menu and to Magic Tattoos UI. RaceMenu itself is not changed.

## Requirements

- [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) 0.7.0 or later, and its requirements
- [RaceMenu](https://www.nexusmods.com/skyrimspecialedition/mods/19080)
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- For Body shape: a body with BodySlide morphs, such as [CBBE 3BA](https://www.nexusmods.com/skyrimspecialedition/mods/30174), built in BodySlide with **Build Morphs** checked. Outfits need morphs built too, or the body grows through them.

## Installation

Install with your mod manager and enable `MTF_Plugin_RaceMenu.esp`. It is ESL-flagged and only lists `Skyrim.esm` and `MagicTattoosFramework.esp` as masters, so it can go anywhere after MTF. RaceMenu is found at runtime; if it isn't loaded, the plugin stays unregistered and does nothing.

## Effects

| Effect | Kind | Does |
| --- | --- | --- |
| Actor scale | while shown | the actor is 50 to 200% of their usual size |
| Body shape | while shown | the body takes a shape at 5 to 100% strength: Muscular or Bigger bust |

**Actor scale** scales RaceMenu's root `NPC` node, so it multiplies with RaceMenu's own height slider. Several tiers multiply together.

**Body shape** moves BodySlide sliders through RaceMenu's body morphs. It adds to the body's own preset, including one from OBody, rather than replacing it. Muscular at 100% sets the CBBE 3BA sliders `MuscleAbs`, `MuscleArms`, `MuscleBack_v2`, `MuscleButt`, `MuscleLegs`, and `MusclePecs` to 100, and `MuscleMoreAbs_v2`, `MuscleMoreArms_v2`, and `MuscleMoreLegs_v2` to 50. Bigger bust at 100% adds 100 to the single slider `Breasts`. Lower strengths scale all of them down. Several tiers don't add up: each slider takes the strongest value any of them asks for.

Bodies without these sliders don't change. That includes the vanilla male body and BHUNP, which uses different slider names.

Both effects work on the player and NPCs. RaceMenu saves them with the game, so they stay after a load until the tier stops.

## Uninstalling

Take off any tattoo whose tiers use these effects, so the body goes back to normal. Then save, quit, and disable the plugin.

## Troubleshooting

The Papyrus log (`Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`) should show `[MTF_Main] Registered 'proteux-mtf.racemenu'` a few seconds after loading a save. If it doesn't, check that RaceMenu and MTF are enabled and that `MTF_Plugin_RaceMenu.esp` loads after `MagicTattoosFramework.esp`.

Each Body shape change logs a line such as `[MTF_Plugin_RaceMenu] body morphs on Lydia: Breasts=1.000000`, so you can tell whether the effect ran. If the line appears but the body doesn't change, the body has no morphs. Rebuild it in BodySlide with **Build Morphs** checked; a `femalebody.tri` file should appear next to `femalebody_0.nif` and `femalebody_1.nif`.

[TESTING.md](TESTING.md) walks through checking each effect in game.

## Building from source

Run `make racemenu` from the repository root (or `make` in this folder) to build and copy it straight into the game's Data folder, then restart Skyrim. `make uninstall-live racemenu` removes those files. `make package racemenu` writes the release zip with the same files, and `make staging racemenu` builds it as its own Vortex mod, **MTF Plugin - RaceMenu**, instead. See the [repository README](../../README.md) for requirements. The version in `VERSION` must match `MOD_VERSION` in `Scripts/Source/MTF_Plugin_RaceMenu.psc`.

All changes go through RaceMenu's `NiOverride` script under the key `proteux-mtf.racemenu`: `AddNodeTransformScale` for scale, and `SetBodyMorph` with `UpdateModelWeight` for shapes. A new shape needs an id in the catalog menu, a branch in `_shapeIndex`, any new slider names in `_sliderNames` (the `values` array in `_applyShapes` has the same length), and its weights in `_shapeWeight`.

## Credits

- Proteux, author
- expired6978, for RaceMenu
- Ousnius and Caliente, for BodySlide and CBBE 3BA
- levchimik, for Magic Tattoos Framework
