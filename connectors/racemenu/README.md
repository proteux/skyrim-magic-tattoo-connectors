# MTF Plugin - RaceMenu

Tattoos that change the body wearing them.

## Description

This patch connects [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF) to [RaceMenu](https://www.nexusmods.com/skyrimspecialedition/mods/19080). A tattoo tier can make the actor bigger or smaller, or reshape their body with BodySlide sliders while it shows, for example a muscular build on a warrior's mark.

It adds a **RaceMenu** plugin to MTF's menu and to [Magic Tattoos UI](https://www.nexusmods.com/skyrimspecialedition/mods/196803). RaceMenu itself is not changed.

## Requirements

- [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) 0.7.0 or later, and its requirements
- [RaceMenu](https://www.nexusmods.com/skyrimspecialedition/mods/19080)
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- For Body shape: a body with BodySlide morphs, such as [CBBE 3BA](https://www.nexusmods.com/skyrimspecialedition/mods/30174), built in BodySlide with **Build Morphs** checked. Outfits need morphs built too, or the body grows through them.
- Optional: [Magic Tattoos Framework - SKSE UI](https://www.nexusmods.com/skyrimspecialedition/mods/196803), an editor in the SKSE Menu Framework menu, with live previews. It makes setting up tiers with these effects far easier.

## Installation

Install with your mod manager and enable `MTF_Plugin_RaceMenu.esp`. It is ESL-flagged and only lists `Skyrim.esm` and `MagicTattoosFramework.esp` as masters, so it can go anywhere after MTF. RaceMenu is found at runtime; if it isn't loaded, the plugin stays unregistered and does nothing.

## Effects

| Effect | Kind | Does |
| --- | --- | --- |
| Actor scale | while shown | the actor is 50 to 200% of their usual size |
| Body shape | while shown | the body takes one of 23 shapes at 5 to 100% strength |

Both effects have a **Transition** setting, 0 to 30 seconds (5 by default). The body eases from its current shape to the new one over that time instead of changing at once, starting and stopping gently, and eases back the same way when the tier stops. 0 changes it instantly. A change that arrives mid-transition carries on from wherever the body is. Loading a save finishes any transition that was under way.

**Actor scale** scales RaceMenu's root `NPC` node, so it multiplies with RaceMenu's own height slider. Several tiers multiply together.

**Body shape** moves CBBE 3BA BodySlide sliders through RaceMenu's body morphs. It adds to the body's own preset, including one from OBody, rather than replacing it, so the same strength changes any body by the same amount. At 100% strength, each shape adds this much to its sliders; lower strengths scale them down:

| Shape | Sliders at 100% strength |
| --- | --- |
| Muscular | `MuscleAbs`, `MuscleArms`, `MuscleBack_v2`, `MuscleButt`, `MuscleLegs`, `MusclePecs` +100; `MuscleMoreAbs_v2`, `MuscleMoreArms_v2`, `MuscleMoreLegs_v2` +50 |
| Bigger bust | `Breasts` +100 |
| Smaller bust | `BreastsSmall` +100 |
| Perkier bust | `BreastPerkiness` +100, `PushUp` +50 |
| Saggier bust | `BreastGravity2` +100 |
| Perkier nipples | `NipplePerkiness` +100, `NippleLength` +50 |
| Bigger butt | `Butt` +100, `BigButt` +50 |
| Smaller butt | `ButtSmall` +100 |
| Rounder butt | `RoundAss` +100, `AppleCheeks` +50 |
| Wider hips | `Hips` +100, `HipUpperWidth` +50 |
| Narrower hips | `HipNarrow_v2` +100 |
| Thicker thighs | `Thighs` +100, `ThighFBThicc_v2` and `ThighOutsideThicc_v2` +50 |
| Thinner thighs | `SlimThighs` +100, `LegsThin` +50 |
| Slender | `SlimThighs` +100, `LegsThin` and `ButtNarrow_v2` +50 |
| Chubby | `ChubbyArms`, `ChubbyButt`, `ChubbyLegs`, `ChubbyWaist` +100; `BigBelly` +50 |
| Pregnant | `PregnancyBelly` +100 |
| Older | `BreastGravity2`, `ButtSaggy_v2` +100; `ButtUnderFold` +50 |
| Younger | `BreastPerkiness` +100, `NipplePerkiness` +50 |
| Longer schlong | `Length`, `SOS - SchlongLength` +100 |
| Thicker schlong | `Thickness`, `SOS - SchlongGirth` +100 |
| Larger glans | `Head`, `SOS - GlansSize` +100 |
| Larger balls | `SOS - BallsSize` +100 (futanari addon only) |
| Smaller balls | `SOS - BallsSmall` +100 (futanari addon only) |

Older and Younger only change the body. RaceMenu can't reshape a face from a script, so for an aged face, pair Older with an MTF face tattoo carrying a wrinkle texture.

Shrinking uses the bodies' own shrink sliders (`BreastsSmall`, `ButtSmall`, `HipNarrow_v2`, `SlimThighs`, `SOS - BallsSmall`) rather than taking away from the size sliders, which would push past the flat shape on a small preset. TNG and the futanari addon have no shrink sliders for length, girth or the glans, so those shapes only grow.

Several Body shape tiers combine: different shapes stack, so Muscular and Pregnant together give both. Two tiers that move the same slider don't add up; that slider takes the strongest value either asks for. Opposites such as Bigger and Smaller bust move different sliders, so they partly cancel.

Bodies without these sliders don't change. That includes the vanilla male body and BHUNP, which uses different slider names.

The schlong, glans and balls shapes move the genital meshes from [TNG](https://www.nexusmods.com/skyrimspecialedition/mods/104215), which RaceMenu morphs alongside the body. Each mesh only responds to its own slider names:
- TNG's male meshes (the `[TNG]` slider sets) use `Length`, `Thickness` and `Head`. They have no balls slider.
- The ERF Futanari addon uses the old SOS names, such as `SOS - SchlongLength`.

Either kind needs to be built in BodySlide with **Build Morphs** checked. You'll see `.tri` files next to the meshes, for example `actors/character/character assets/TNG/m_genitals.tri`.

Both effects work on the player and NPCs. RaceMenu saves them with the game, so they stay after a load until the tier stops.

## Uninstalling

Take off any tattoo whose tiers use these effects, so the body goes back to normal. Then save, quit, and disable the plugin.

## Troubleshooting

The Papyrus log (`Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`) should show `[MTF_Main] Registered 'proteux-mtf.racemenu'` a few seconds after loading a save. If it doesn't, check that RaceMenu and MTF are enabled and that `MTF_Plugin_RaceMenu.esp` loads after `MagicTattoosFramework.esp`.

Each Body shape change logs a line such as `[MTF_Plugin_RaceMenu] body morphs on Lydia: Breasts=1.000000` once it finishes (after the transition), so you can tell whether the effect ran. If the line appears but the body doesn't change, the body has no morphs. Rebuild it in BodySlide with **Build Morphs** checked; a `femalebody.tri` file should appear next to `femalebody_0.nif` and `femalebody_1.nif`.

[TESTING.md](TESTING.md) walks through checking each effect in game.

## Building from source

Run `make racemenu` from the repository root (or `make` in this folder) to build and copy it straight into the game's Data folder, then restart Skyrim. `make uninstall-live racemenu` removes those files. `make package racemenu` writes the release zip with the same files (it needs a `CHANGELOG.md` entry for the version; the Nexus page is `nexus/description.bbcode`), and `make staging racemenu` builds it as its own Vortex mod, **MTF Plugin - RaceMenu**, instead. See the [repository README](../../README.md) for requirements. The version in `VERSION` must match `MOD_VERSION` in `Scripts/Source/MTF_Plugin_RaceMenu.psc`.

All changes go through RaceMenu's `NiOverride` script under the key `proteux-mtf.racemenu`: `AddNodeTransformScale` for scale, and `SetBodyMorph` with `UpdateModelWeight` for shapes. Transitions step four times a second from a second script, `MTF_Plugin_RaceMenu_Loop`, on the player alias (`ALIAS_SCRIPTS` in `build.sh`), which only runs while some actor is changing. Each step of a shape rebuilds the body mesh once per changing actor. A new shape needs an id in the catalog menu, a branch in `_shapeIndex`, its slider weights in `_shapeWeight`, and any slider it uses that isn't already in `_sliderNames` added there (a slider missing from that list is never set). Slider names come from the CBBE 3BA reference slider set, `CalienteTools/BodySlide/RefTemplates/CBBE 3BA/CBBE 3BA Reference.osp`.

## Credits

- Proteux, author
- expired6978, for RaceMenu
- Ousnius and Caliente, for BodySlide and CBBE 3BA
- levchimik, for Magic Tattoos Framework

## License

Copyright (C) 2026 Jack Whitehouse (proteux). Released under the [GNU General Public License v3.0 or later](../../LICENSE), with ABSOLUTELY NO WARRANTY. The download includes the license text and a notice in `SKSE/Plugins/MTF_Plugin_RaceMenu`, and the Papyrus source in `Scripts/Source`.
