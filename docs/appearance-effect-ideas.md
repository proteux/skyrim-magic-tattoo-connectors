# Appearance effect ideas

Ideas for effects that change how an actor looks, beyond what the RaceMenu connector does now (actor scale and BodySlide body shapes) and the Skyrim connector's Facial mood. Collected November 2026 as a starting point, not a plan: check each one in game before building it.

Every MTF effect runs on whoever wears the preset, so all of these would work on followers as well as the player unless marked otherwise.

## Face shape

### How faces work

Three separate layers make up a face:

1. **Character creation (chargen) morphs**: nose, jaw, brow and cheek sliders and face part presets. The values live on the NPC's base record (`ActorBase`), and the vertex changes come from the `.tri` files that ship with each head mesh.
   - The player's face is rebuilt from those values at runtime.
   - An NPC's face is baked by the Creation Kit into `meshes/actors/character/FaceGenData/FaceGeom/<plugin>/<formID>.nif` with a matching `FaceTint` texture, and the game loads those files. Changing an NPC's slider values does nothing until the head is regenerated, and regenerating it at runtime risks the "dark face" bug, where head and body skin don't match.
2. **RaceMenu's own sliders and sculpts**, saved in its co-save. Its Papyrus API (`NiOverride`) covers body morphs, node transforms and overlays, but has no call to set a face slider on an arbitrary actor.
3. **Expression morphs**: moods, phonemes (speech mouth shapes) and modifiers such as blink and brow raise, in the head's `.tri`. The only layer meant to change while the game runs.

### Options

- **Head node scale.** Another `NiOverride` node transform like the RaceMenu connector's scale effect, on `NPC Head [Head]`. Makes the head bigger or smaller, but can't change individual features. Low risk.
- **Held expression modifiers and phonemes.** A squint, raised brows or a mouth shape held while the tier shows, through MfgFix-style calls, beyond the mood-only `SetExpressionOverride` the Skyrim connector uses. Low risk.
- **Real chargen morphs.** SKSE's `ActorBase.SetFaceMorph(value, index)` / `SetFacePreset`, then `Actor.RegenerateHead`. Unreliable for followers:
  - It edits the base record, so every copy of that NPC changes.
  - It probably needs reapplying after each load.
  - The baked face tint won't match the new head (dark face).

  Not verified against the SKSE API in this repo; there are no stubs for it yet.

For "this tattoo makes my follower look older or fiercer", the practical combination today is the Older body shape, a face overlay texture (wrinkles, warpaint), and a held expression.

## Skin color

### How skin color works

- **Body, hands and feet** use a skin shader that multiplies the skin texture by one tint color, the skin tone. One color recolors the whole mesh.
- **The player's face** color is a tint mask built at runtime from layers (skin tone, warpaint, dirt, lips). `Game.SetTintMaskColor` / `UpdateTintMaskColors` change it, for the player only.
- **An NPC's face** tint is baked into `FaceTint/<plugin>/<formID>.dds`, and there's no runtime API to repaint it. The NPC record's skin tone (`QNAM`) only drives the body.

So a follower's body is easy to recolor; making their face match is the hard part.

### Options

| Option | Covers | Works on |
|---|---|---|
| Full-coverage tinted overlays (recommended) | Body, face, hands and feet | Everyone |
| `NiOverride` skin overrides | Body, hands and feet only; the face won't follow | Everyone |
| Skin tone tint mask | Body and face, properly matched | Player only |
| Effect shaders | A magical aura over the actor, not a skin color | Everyone, but not saved, so replay after load |

**Full-coverage overlays.** MTF already paints tattoos by setting `NiOverride` node overrides on overlay nodes: texture (key 9), tint color (key 7), emissive color (key 0), emissive multiplier (key 1) and alpha (key 8); see `_applyOverlayDeferred` and `clearOverlay` in `vendor/magic-tattoos-framework/source/scripts/MTF_MainQuest.psc`. A plain white texture covering the whole area, tinted and with partial alpha, recolors the whole person, face included: full alpha reads as body paint, partial alpha as a wash (sickly green, frost blue). It uses one overlay slot per area, shared with MTF's tattoos and other overlay mods. This may need no connector at all, just an MTF tattoo pack with full-coverage textures and MTF's existing color and fade settings.

**Skin overrides.** Tint (key 7) or emissive color (key 0, for a glow) on the actor's skin. The head will look like it belongs to someone else.

### What a connector would need

- `NiOverride` stubs in `shared/stubs/NiOverride.psc` for `AddSkinOverrideInt`/`Float` or `AddNodeOverrideInt`/`Float`, and the matching `Remove...` calls so `onDeactivate` can undo them. The stub only has the body morph and node scale functions today.
- A `"color": 1` effect parameter in the catalog, which hands the script a `0xRRGGBB` int.

## Effect shaders

Done: the shaders in the tables below shipped in the Skyrim connector 0.2.0 as the Magic aura effect (`aura`), except the six `EnchArmor*FXS` ones, which showed nothing on an actor in game. The notes are kept for reference.

MTF's `shader.play` effect offers 21 `Skyrim.esm` shaders, hardcoded in `_shaderFormIdById` in `vendor/magic-tattoos-framework/source/scripts/MTF_Plugin_Base.psc`: fire cloak, fire burst, frost, Chillrend frost, shock, shock storm, Stoneflesh, Ebonyflesh, Dragonhide, soul trap, ethereal ghost, red ghost, invisibility, muffle, ward, reanimate, turn undead flames, heal, absorb health, vampire change, werewolf transform and detect life.

The installed `Skyrim.esm`, `Dawnguard.esm` and `Dragonborn.esm` hold 276 effect shader records. The ones below look useful as tattoo effects. They were chosen by editor ID, not seen in game, so the notes are what the names suggest. Dawnguard and Dragonborn IDs are given without the load-order byte, as `Game.GetFormFromFile` wants them.

### Skyrim.esm

Magic armor and auras:

| Editor ID | FormID | Notes |
|---|---|---|
| `MagicArmorOakFleshFXS` | `0x094160` | Completes the flesh set with MTF's Stoneflesh, Ebonyflesh, Dragonhide |
| `MagicArmorIronFleshFXS` | `0x094163` | |
| `ShieldSpellFXS` | `0x056AC9` | |
| `PerkShieldChargeFXShader` | `0x10F803` | |
| `ShockPlayerCloakFXShader` | `0x10F9A6` | |
| `FrostShortFXShader` | `0x0435A3` | No frost cloak record by that name; these are the frost options |
| `FrostSpikeFXShader` | `0x0647B9` | |
| `FrostIceFormFXShader` | `0x0DC20D` | Ice Form shout freeze |
| `SteamFXShader` | `0x10FDF9` | |
| `WebbedFXS` | `0x02E1CD` | |
| `ChaurusPoisonFXShader` | `0x10CC64` | |

Enchantment glows, the closest to a "magic tattoo" glow:

| Editor ID | FormID |
|---|---|
| `EnchRedFXShader` | `0x0D7661` |
| `EnchBlueFXShader` | `0x05D608` |
| `EnchPurpleFXShader` | `0x05D607` |
| `EnchGreenFXShader` | `0x05D606` |
| `EnchFireFXShader` | `0x04E810` |
| `EnchFrostFXShader` | `0x04FA1D` |
| `EnchShockFXShader` | `0x059EDA` |
| `EnchElementalFuryFXS` | `0x0510D3` |
| `EnchBoundSwordFXS` | `0x069CE8` |
| `EnchArmorFireFXS`, `EnchArmorFrostFXS`, `EnchArmorShockFXS` | `0x092DE7`, `0x092DE8`, `0x092DE9` |
| `EnchArmorHealthFXS`, `EnchArmorMagickaFXS`, `EnchArmorStaminaFXS` | `0x092DEC`, `0x092DED`, `0x092DEE` |
| `AlchArmorFireFXS`, `AlchArmorFrostFXS`, `AlchArmorMagickaFXS`, `AlchArmorShockFXS`, `AlchArmorPoisonFXS` | `0x10BEA9` to `0x10BEAD` |

Illusion and mind:

| Editor ID | FormID |
|---|---|
| `IllusionPositiveFXS` | `0x073321` |
| `IllusionNegativeFXS` | `0x074799` |
| `IllusionFearFXS` | `0x07D450` |
| `ParalyzeFxShader` | `0x06DE84` |
| `BerserkerFXS` | `0x0FD7D9` |
| `NightmareFXShader` | `0x0BF743` |
| `KynesPeaceFXS` | `0x084B39` |
| `AnimalAllyFXS` | `0x084B3A` |
| `Disguise01FXS` | `0x07876B` |

Absorb and drain:

| Editor ID | FormID | Notes |
|---|---|---|
| `AbsorbBlueFXS` | `0x0ABF08` | Magicka version of MTF's absorb health |
| `AbsorbGreenFXS` | `0x0ABF07` | Stamina version |
| `DragonPowerAbsorbFXS` | `0x0280C0` | Dragon soul absorb |
| `GreybeardPowerAbsorbFXS` | `0x09186F` | |

Ghosts and spirits:

| Editor ID | FormID |
|---|---|
| `GhostVioletFXShader` | `0x103129` |
| `GhostWolfSpiritFXShader` | `0x0FE68D` |
| `GhostCallValorFXShader` | `0x01A1E9` |
| `MGGhostFXShader` | `0x06A155` |
| `GhostFXShaderNightingale` | `0x0C5EF7` |
| `GhostFXShaderNightingaleCorrupt` | `0x0C7908` |
| `InvisFXShaderNightingale` | `0x000E5C` |
| `DA02ArmorShadow` | `0x081180` |

Racial powers, perks and healing:

| Editor ID | FormID |
|---|---|
| `PowerRacialBretonFXShader` | `0x10F566` |
| `PowerRacialHighbornFXS` | `0x10CC48` |
| `PowerRacialCommandAnimalFXShader` | `0x10F927` |
| `DarkElfAncestorsWrathFXShader` | `0x10F56C` |
| `ArgonianHistHealFXS` | `0x10F4A9` |
| `AdrenalineRushFXS` | `0x10F4A8` |
| `HealCircleFXS` | `0x10CDC9` |
| `HealMysticFXS` | `0x04E220` |
| `WaterBreathingFXS` | `0x0BCF27` |

Daedric and quest effects:

| Editor ID | FormID |
|---|---|
| `AzuraGood` | `0x08CA2F` |
| `AzuraEvil` | `0x050F02` |
| `DA02BoethiahFXS` | `0x0CC6E6` |
| `SovengardeFXS01` | `0x10B2DF` |
| `MGAncanoEffectShader` | `0x025226` |
| `AtronachFlameGlowFXS` | `0x078ED3` |

### Dawnguard.esm

| Editor ID | FormID |
|---|---|
| `DLC1SunFireCloakFXShader` | `0x00A3BC` |
| `DLC1SunFireFXShader` | `0x00A3BB` |
| `DLC1SoulCairnGhostFXShader` | `0x019AB3` |
| `DLC01SoulCairnFXShader` | `0x00939B` |
| `DLC1VampireMistform01FXS` | `0x01AA2E` |
| `DLC1DrainVital01FXS` | `0x00CBC1` |
| `DLC1AurielsBowFireFXShader` | `0x00AEB3` |

### Dragonborn.esm

| Editor ID | FormID |
|---|---|
| `DLC2MiraakMagicFXS` | `0x03D30E` |
| `DLC2MiraakSmokeFXS` | `0x03D30D` |
| `DLC2DragonbornAspectFXS01`, `02`, `03` | `0x021735`, `0x021734`, `0x021733` |
| `DLC2AshShellFXS` | `0x027E34` |
| `DLC2AshGuardianFXS` | `0x027E33` |
| `DLC2WhirlWindCloakFXS` | `0x02502A` |
| `DLC2MorasGraspFXShader` | `0x03A299` |
| `DLC2OmenOfDangerFXS` | `0x0324C1` |
| `DLC2ApocryphaSpellFXS` | `0x03CD84` |
| `DLC2HMDaedraFXS` | `0x023F87` |

### Left out

- One-off transitions that don't hold on an actor: `*Death*`, `*Disintegrate*`, `*Emerge*`, `*Trans*`, `*Summon*`, `RieklingAmbush*`, and the Alduin and dragon-hole effects. These could still suit a burst effect.
- Test and leftover records: `test*`, `*OLD`, `*COPY*`, `holesTest`, `NFXS`.
- Effects made for specific objects or creatures: Azura's crystals, `MG02WallShader`, the expedition spider shaders.

### Building it

Copy MTF's `shader.play` pattern:

- A menu parameter of shader ids, and a lookup from id to FormID and file, resolved with `Game.GetFormFromFile`. A DLC shader resolves to `None` when its DLC isn't loaded, so skip it.
- `EffectShader.Play` in `onActivate`, `Stop` in `onDeactivate`.
- Replay after each load, since the engine doesn't save shader playback. MTF does it from `onTick` (`_tickShaderRow`).
- Track what's playing, because MTF's `MTF_StopAllShaders` event only stops MTF's own shaders.

To list the records again (for example after adding a mod with its own shaders), walk the `EFSH` group of each master and read each record's `EDID`; compressed records (flag `0x40000`) need zlib after their 4-byte size.
