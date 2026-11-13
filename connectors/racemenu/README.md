# MTF Plugin - RaceMenu

Tattoos that change the body and hair wearing them.

## Description

This patch connects [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF) to [RaceMenu](https://www.nexusmods.com/skyrimspecialedition/mods/19080). A tattoo tier can make the actor bigger or smaller, reshape their body with BodySlide sliders, or recolor their hair while it shows, for example a muscular build on a warrior's mark, or frost-white hair on a frost mage's sigil.

It adds a **RaceMenu** plugin to MTF's menu and to [Magic Tattoos UI](https://www.nexusmods.com/skyrimspecialedition/mods/196803). RaceMenu itself is not changed.

## Requirements

- [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) 0.7.0 or later, and its requirements
- [RaceMenu](https://www.nexusmods.com/skyrimspecialedition/mods/19080)
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- For Body shape: a body with BodySlide morphs, such as [CBBE 3BA](https://www.nexusmods.com/skyrimspecialedition/mods/30174), built in BodySlide with **Build Morphs** checked. Outfits need morphs built too, or the body grows through them.
- For Hair color (any wig): [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854).
- Optional: [Magic Tattoos Framework - SKSE UI](https://www.nexusmods.com/skyrimspecialedition/mods/196803), an editor in the SKSE Menu Framework menu, with live previews. It makes setting up tiers with these effects far easier.

## Installation

Install with your mod manager and enable `MTF_Plugin_RaceMenu.esp`. It is ESL-flagged and only lists `Skyrim.esm` and `MagicTattoosFramework.esp` as masters, so it can go anywhere after MTF. RaceMenu is found at runtime; if it isn't loaded, the plugin stays unregistered and does nothing.

## Effects

| Effect | Kind | Does |
| --- | --- | --- |
| Actor scale | while shown | the actor is 50 to 200% of their usual size |
| Body shape | while shown | the body takes one of 23 shapes at 5 to 100% strength |
| Hair color | while shown | the hair is tinted any color; works on the actor's own hair and KS Hairdos wigs |
| Hair color (any wig) | while shown | the hair and any wig are tinted any color; needs powerofthree's Papyrus Extender |

Every effect has a **Transition** setting, 0 to 30 seconds (5 by default). The body or hair eases from how it looks now to the new look over that time instead of changing at once, starting and stopping gently, and eases back the same way when the tier stops. 0 changes it instantly. A change that arrives mid-transition carries on from wherever it is. Loading a save finishes any transition that was under way.

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

**Hair color** sets the tint that Skyrim's hair shader multiplies the hair texture by, the same tint RaceMenu's hair color slider changes. When several Hair color tiers show at once, the one that started last wins, and when it stops the next one takes over. When none are left, the hair goes back to its own color.

Because the tint multiplies the texture, it can darken a color or shift it, but not lighten it. Hair with pale, neutral textures, which is most hair made to be recolored in RaceMenu, takes any color well. Dark or already-colored hair textures only get darker or tinted, so a platinum color on black hair stays dark. For the same reason, brows and beards aren't tinted: their textures are too dark for a tint to show.

Wigs from [KS Hairdos SMP](https://www.nexusmods.com/skyrimspecialedition/mods/31300) (KS Wigs SMP) change too, along with the hair under them. Other wigs worn as armor may not: a script can't list the parts of a wig, so the plugin looks for the part names KS uses, based on the wig's mesh file.

A new hairstyle or wig picks up the color within a few seconds, and so does a wig taken off and put back on, or hair whose physics reset.

**Hair color (any wig)** is the same tint applied a different way, through [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854), for when Hair color misses a wig. It tints every part of the actor drawn with the hair shader, whatever mod it comes from, so it works on any wig. Its Color and Transition settings work like Hair color's, and so does the newest tier winning. The tint isn't saved with the game, so the plugin puts it back when a save loads. An actor who comes into view later, or a wig put on, shows the hair's own color for a few seconds before the tint comes back. Use one hair effect or the other on an actor, not both at once.

Which hair effect to use:
- **Hair color** for the actor's own hairstyle, or a KS Hairdos wig. Its color holds steady through loads.
- **Hair color (any wig)** when the actor wears a wig that Hair color leaves unchanged, such as one from another wig mod or a KS elf wig. Its color can drop for a moment after a wig change or when an actor comes into view.

All the effects work on the player and NPCs. They stay after a load until the tier stops: RaceMenu saves all but Hair color (any wig), which the plugin puts back itself.

## Resetting

If a body, size or hair change ever stays after its tattoo is gone, you can undo everything the plugin has changed. Open the console and enter:

```
setpqv MTF_Plugin_RaceMenu ResetOnLoad 1
```

Then save and load that save. Every actor the plugin has changed goes back to their own shape, size and hair color, and the Papyrus log shows `[MTF_Plugin_RaceMenu] reset N actor(s)`. The setting turns itself off again, so later loads don't reset. Skyrim's console can't run a script directly, which is why it waits for a load.

The reset only touches this plugin's own changes. RaceMenu sliders, OBody presets and other mods' morphs stay as they were. A tier that is still showing comes back the next time it starts.

## Uninstalling

Take off any tattoo whose tiers use these effects, so the body and hair go back to normal, or use the reset above. Then save, quit, and disable the plugin.

If you play on without the plugin and later add it back, its leftover changes are undone on the first load, and any tier still showing applies again a few seconds later.

## Troubleshooting

The Papyrus log (`Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`) should show `[MTF_Main] Registered 'proteux-mtf.racemenu'` a few seconds after loading a save. If it doesn't, check that RaceMenu and MTF are enabled and that `MTF_Plugin_RaceMenu.esp` loads after `MagicTattoosFramework.esp`.

Each Body shape change logs a line such as `[MTF_Plugin_RaceMenu] body morphs on Lydia: Breasts=1.000000` once it finishes (after the transition), so you can tell whether the effect ran. If the line appears but the body doesn't change, the body has no morphs. Rebuild it in BodySlide with **Build Morphs** checked; a `femalebody.tri` file should appear next to `femalebody_0.nif` and `femalebody_1.nif`.

Each Hair color change logs a line such as `[MTF_Plugin_RaceMenu] hair color on Lydia: HairFemaleNord06=#C0392B` once it finishes, listing each hair part it tinted (`none` when the hair goes back to its own color). If the line lists parts but the hair doesn't change, that hair's texture is too dark to show the tint, or it's a wig the plugin can't find parts for.

Hair color (any wig) logs `[MTF_Plugin_RaceMenu] hair tint on Lydia: #C0392B` once each change finishes (`none` when the hair goes back to its own color). If a tier logs `needs powerofthree's Papyrus Extender, which isn't installed` instead, the Papyrus Extender isn't loaded.

[TESTING.md](TESTING.md) walks through checking each effect in game.

## Building from source

Run `make racemenu` from the repository root (or `make` in this folder) to build and copy it straight into the game's Data folder, then restart Skyrim. `make uninstall-live racemenu` removes those files. `make package racemenu` writes the release zip with the same files (it needs a `CHANGELOG.md` entry for the version; the Nexus page is `nexus/description.bbcode`), and `make staging racemenu` builds it as its own Vortex mod, **MTF Plugin - RaceMenu**, instead. See the [repository README](../../README.md) for requirements. The version in `VERSION` must match `MOD_VERSION` in `Scripts/Source/MTF_Plugin_RaceMenu.psc`.

How each effect is applied:

- **Scale and shapes** go through RaceMenu's `NiOverride` script under the key `proteux-mtf.racemenu`: `AddNodeTransformScale` for scale, and `SetBodyMorph` with `UpdateModelWeight` for shapes. Each step of a shape rebuilds the body mesh once per changing actor.
- **Hair color** sets the tint override (key 7) with `AddNodeOverrideInt` on each hair node, which is named after its head part's editor ID (SKSE's `ActorBase.GetNthHeadPart` and `HeadPart.GetPartName`). Transition steps aren't saved (`persist` false); only the final color is.
  - A wig is armor, so its node names are guessed from the mesh of each armor addon in slot 31 or 41 (KS's `Angels_1.nif` holds `KSSMP_Angels`, `KSSMP_Angels_HL` and `Hairline`) and kept if SKSE's `NetImmerse.HasNode` finds them.
  - Node overrides have no key of their own, so the plugin records each node's color before touching it, from another mod's override, the live shader or the NPC's hair color record, and puts it back when it's done.
  - Every 2.5 seconds while the effect shows (`HAIR_CHECK_SECONDS`), a node whose live tint has drifted (a wig re-equipped, SMP physics rebuilding the mesh) gets its color put back.
- **Hair color (any wig)** calls powerofthree's `SetHairColor(Actor, ColorForm)`, which tints every hair-shaded geometry in the actor's 3D from a color record's color, unscaled.
  - That call reads the record when its queued task runs, so each actor borrows its own record from a pool of 32 in the ESP (`COLOR_FORMS` in `build.sh`, FormIDs `0x801` up, matching `HAIR_TINT_FORMS` in the script), set with `ColorForm.SetColor` before each call. Records are handed out in turn, so one just freed isn't reused while its last call may still read it.
  - The tint lives only on the loaded 3D, so the plugin puts it back on load. After that it checks every 2.5 seconds and only puts it back when the items in the hair slots change, the hair head part's live tint differs, or 6 seconds have passed (`HAIR_TINT_REFRESH_SECONDS`), for changes it can't see.
  - The color it goes back to is read from the hair head part's live tint before the first change, or the hair color record doubled.
- **Transitions** step four times a second from a second script, `MTF_Plugin_RaceMenu_Loop`, on the player alias (`ALIAS_SCRIPTS` in `build.sh`), which only runs while some actor is changing.

A new shape needs an id in the catalog menu, a branch in `_shapeIndex`, its slider weights in `_shapeWeight`, and any slider it uses that isn't already in `_sliderNames` added there (a slider missing from that list is never set). Slider names come from the CBBE 3BA reference slider set, `CalienteTools/BodySlide/RefTemplates/CBBE 3BA/CBBE 3BA Reference.osp`.

## Credits

- Proteux, author
- expired6978, for RaceMenu
- Ousnius and Caliente, for BodySlide and CBBE 3BA
- levchimik, for Magic Tattoos Framework

## License

Copyright (C) 2026 Jack Whitehouse (proteux). Released under the [GNU General Public License v3.0 or later](../../LICENSE), with ABSOLUTELY NO WARRANTY. The download includes the license text and a notice in `SKSE/Plugins/MTF_Plugin_RaceMenu`, and the Papyrus source in `Scripts/Source`.
