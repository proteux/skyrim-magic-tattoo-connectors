# Integrating another mod with Magic Tattoos Framework

How to extend an existing Skyrim mod so Magic Tattoos Framework (MTF) can use it: its state as **conditions** that decide which tier of a tattoo shows, and its features as **effects** (MTF's word for actions) that run while a tier is showing. It also covers the lighter options, which are listening to MTF's events and applying presets from your own scripts.

Sources, checked against MTF commit [`1df07d2`](https://github.com/levchimik/magic-tattoos-framework/tree/1df07d2e) (July 2026):

- [`docs/INTEGRATION_PLUGINS.md`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/docs/INTEGRATION_PLUGINS.md), MTF's own guide. Read it, but parts of it are older than the code. See [Where MTF's guide is out of date](#where-mtfs-guide-is-out-of-date).
- [`source/scripts/MTF_Plugin.psc`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/source/scripts/MTF_Plugin.psc), the base class. Its docstrings are the authoritative API reference, and it is where this document gets the current signatures.
- [`source/scripts/MTF_MainQuest.psc`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/source/scripts/MTF_MainQuest.psc), the host: registration, condition evaluation, the event API.
- The shipped plugins in [`source/scripts/MTF_Plugin_*.psc`](https://github.com/levchimik/magic-tattoos-framework/tree/1df07d2e/source/scripts), their catalogs in [`data/.../plugins/`](https://github.com/levchimik/magic-tattoos-framework/tree/1df07d2e/data/SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins), and their ESPs in [`spriggit/`](https://github.com/levchimik/magic-tattoos-framework/tree/1df07d2e/spriggit).
- [`tools/validate_catalogs.py`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/tools/validate_catalogs.py) and the [web preset validator](https://github.com/levchimik/magic-tattoos-framework/tree/1df07d2e/tools/web-preset-validator).

---

## Pick the kind of integration

| You want to | Use | Needs an ESP and a script? |
|---|---|---|
| Let tattoos react to your mod's state, or let tattoos trigger your mod's features | An **MTF plugin** (most of this document) | Yes |
| React when a tattoo tier or effect changes | MTF's **outbound mod events** | Only a listener in your existing scripts |
| Put a preset on an actor, or take it off, from your mod | MTF's **inbound mod events** | Only `ModEvent` calls in your existing scripts |

The two event routes need no dependency on MTF at all: if MTF isn't installed, nothing listens and nothing fires. A plugin is the only way to add conditions and effects.

---

## What an MTF plugin is made of

Three files, shipped as their own small mod that depends on `MagicTattoosFramework.esp`. MTF itself never needs to change.

1. **A catalog**, `Data/SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/<pluginId>.json`. It declares every condition and effect, their parameters, labels and descriptions. MTF's menu, this UI's editor, and SkyrimNet all build their screens from it.
2. **A Papyrus script** that `extends MTF_Plugin`. It returns the plugin id and implements the behaviour: `checkCondition` for conditions, and `onActivate`, `onDeactivate`, `onTick`, `onGameTime` for effects.
3. **A tiny ESL-flagged ESP** with one quest that carries the script, plus a reference alias that carries MTF's `MTF_PluginAliasKick` script.

### Put it in a separate patch, not in the original mod

You could attach the plugin quest to the existing mod's own ESP, but don't. The script extends `MTF_Plugin`, so the original mod would then throw script errors for everyone who doesn't run MTF. Ship a separate patch named like `MTF_Plugin_<YourMod>.esp`, the same way MTF ships its FMR, SLA, OStim and other bridges. The patch looks up your mod at runtime with `Game.GetFormFromFile`, so it doesn't need your mod as a master either, and it simply stays unregistered if your mod isn't loaded.

### How it runs

1. On a new game or on first load with the patch, the quest starts and `MTF_Plugin.OnInit` schedules `_tryRegister` 0.5 s later.
2. `_tryRegister` calls your `_resolveDeps()`. Until that returns true it retries every 2 s. It then waits for MTF's host quest (FormID `0x803` in `MagicTattoosFramework.esp`), retrying every 1 s, and calls `host.RegisterPlugin(self)`, then your `_onRegistered()`.
3. MTF's slow tick also sends `MTF_PluginKick` every cycle. The kick alias catches it and calls `_tryRegister` again. That covers saves where Papyrus dropped the queued `OnUpdate`, which happens after a script is rebuilt mid-save. `_tryRegister` returns at once if the plugin is already registered.
4. Every evaluation tick (about every 2 s), for each tracked actor and each tier with one of your conditions, MTF calls `checkCondition`. The lowest tier number whose conditions pass wins, and Default shows when none do.
5. When a tier starts winning, MTF calls `onActivate` for each effect on it, then `onTick` every evaluation tick and `onGameTime` once per in-game hour while it stays on, and `onDeactivate` when it stops.

Everything is addressed by string: a condition or effect is `"<pluginId>:<itemId>"` in presets and save data. Order in the catalog never matters, and ids must never change once released.

---

## Checklist

- [ ] Choose a **plugin id**, for example `mtf.yourmod` or `yourname.yourmod`. Lowercase, no colon. The catalog file name must be exactly `<pluginId>.json`.
- [ ] Choose a **stable form in your mod** to probe for: a script quest or a global is best, since those don't get renumbered.
- [ ] Write the **catalog**, with all keys in lowercase ASCII and `"schemaversion": 2`.
- [ ] Write the **script**, `extends MTF_Plugin`, with `GetPluginId()`, `_resolveDeps()`, `checkCondition` and the effect hooks using the 10-argument signatures below.
- [ ] Write a matching `onDeactivate` for every effect that changes persistent state, or mark the effect `"kind": "burst"`.
- [ ] Build an **ESL-flagged ESP**: one Start Game Enabled quest with your script, and one reference alias forced to the player (`Skyrim.esm` `0x14`) with `MTF_PluginAliasKick`.
- [ ] Compile against MTF's script sources and PapyrusUtil's (`StorageUtil`, `JsonUtil`), with `MagicTattoosFramework.esp` as the ESP's master.
- [ ] Run `tools/validate_catalogs.py` from MTF's repo on your catalog, or check it by hand against [Catalog rules](#catalog-rules).
- [ ] Test in game. See [Testing](#testing).
- [ ] List MTF, PapyrusUtil SE, and your own mod as requirements on the patch's page.

---

## The catalog

```json
{
  "schemaversion": 2,
  "pluginid": "mtf.yourmod",
  "pluginlabel": "Your Mod",
  "conditions": [
    {
      "id": "corruption",
      "label": "Corruption",
      "description": "Triggers when the actor's corruption is at least {param1}%.",
      "param": { "label": "Min corruption", "min": 0, "max": 100, "default": 50, "format": "{0}%" }
    },
    {
      "id": "pact.sworn",
      "label": "Pact sworn",
      "description": "Triggers while the actor has sworn the {param1} pact.",
      "param": {
        "label": "Pact",
        "default": "any",
        "menu": [
          { "id": "any", "label": "Any pact" },
          { "id": "shadow", "label": "Shadow" },
          { "id": "flame", "label": "Flame" }
        ]
      }
    }
  ],
  "effects": [
    {
      "id": "corruption.slow",
      "label": "Slow corruption",
      "kind": "continuous",
      "description": "While shown, corruption rises {param1}% slower.",
      "param1": { "label": "Reduction", "min": 0, "max": 100, "default": 25, "format": "{0}%" }
    },
    {
      "id": "corruption.purge",
      "label": "Purge corruption",
      "kind": "burst",
      "description": "When shown, removes {param1} corruption once.",
      "param1": { "label": "Amount", "min": 1, "max": 100, "default": 10 }
    }
  ]
}
```

### Top level

- `schemaversion`: `2`. MTF registers a catalog with a different number anyway, but shows a warning in game and in the Papyrus log.
- `pluginid`: the same string `GetPluginId()` returns, and the file's base name.
- `pluginlabel`: the name shown on the Plugins page of MTF's menu and of this UI.
- `conditions`, `effects`: arrays. Either may be empty.

### Conditions

- `id`: unique within the plugin's conditions, lowercase, no spaces, no colon. Dots are fine and common (`trigger.ovulation`).
- `label`: the name in the condition picker.
- `description`: a plain sentence. `{param1}` and `{param2}` are replaced with the tier's values. SkyrimNet reads it so NPCs can explain when a tattoo shows, and this UI uses it for its tier summaries.
- `param`, `param2`, `param3`: optional, at most three. `param2` needs `param`. `param3` can be a slider or text, never a menu.

### Effects

- `id`, `label`, `description`: as for conditions.
- `kind`: `"burst"` or `"continuous"` (the default).
  - A burst runs once, in `onActivate`. MTF never calls `onDeactivate`, `onTick` or `onGameTime` for it, and its menu adds a `[!]` badge to the label. Don't put the badge in the label yourself.
  - A continuous effect lasts while the tier is showing, and **you must undo it in `onDeactivate`**. MTF's lifecycle audit counts its activations and deactivations.
- `param1` to `param5`: optional and contiguous, so no `param3` without `param2`. MTF only shows a parameter whose `label` is not empty.

### Parameter types

Every parameter needs a `label` and a `default`. The type is set by which other keys are present:

| Type | Keys | Value your script gets |
|---|---|---|
| Slider | `min`, `max`, optional `step` and `format` (`"{0}"`, `"{0}%"`, `"{0} s"`) | an int |
| Menu | `menu: [{ "id", "label" }]`, and `default` is one of the ids | a string id |
| Text | `"text": true` | a string |
| Color (effects only) | `"color": 1` | an int, `0xRRGGBB` |

The types don't mix: a menu or text parameter can't also have `min`, `max`, `step` or `format`.

### Catalog rules

- **Every key must be lowercase ASCII.** PapyrusUtil lowercases keys when it loads the file, so `"pluginLabel"` reads back as empty, with no error.
- Menu ids match `[a-z0-9_]+` and are unique within their menu. Presets store the id, so reordering a menu or adding options is safe, but **renaming or reusing an id breaks every preset that used it**. To retire an option, drop it from the menu and keep its branch in your script.
- Condition and effect ids follow the same rule: never rename one after release.
- For sliders, `min <= default <= max`.
- Keep the total under 128 conditions or 128 effects per plugin, Papyrus's array limit.
- Unknown keys are ignored without a warning, so a typo silently does nothing.
- MTF has no per-plugin settings page any more. If your plugin needs global options, read them from your own JSON file or your own mod's MCM.

---

## The script

```papyrus
Scriptname MTF_Plugin_YourMod extends MTF_Plugin

YourModQuest Property YourMod Auto Hidden

string Function GetPluginId()
    return "mtf.yourmod"
EndFunction

bool Function _resolveDeps()
    if YourMod != None
        return true
    endif
    YourMod = Game.GetFormFromFile(0x000D62, "YourMod.esp") as YourModQuest
    return YourMod != None
EndFunction

bool Function checkCondition(Actor target, int param, string cid)
    if target == None || YourMod == None
        return false
    endif
    if cid == "corruption"
        return YourMod.GetCorruption(target) >= param
    elseif cid == "pact.sworn"
        string pact = _host().GetEvalParamStr()
        if pact == "any"
            return YourMod.HasAnyPact(target)
        endif
        return YourMod.HasPact(target, pact)
    endif
    return false
EndFunction

Function onActivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || YourMod == None
        return
    endif
    if eid == "corruption.slow"
        string key = "mtf.yourmod.slow." + slot + "." + effectIdx
        StorageUtil.SetFloatValue(target, key, param as float)
        YourMod.AddCorruptionResist(target, param as float)
    elseif eid == "corruption.purge"
        YourMod.ModCorruption(target, -param)
    endif
EndFunction

Function onDeactivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || YourMod == None
        return
    endif
    if eid == "corruption.slow"
        string key = "mtf.yourmod.slow." + slot + "." + effectIdx
        if StorageUtil.HasFloatValue(target, key)
            float applied = StorageUtil.GetFloatValue(target, key)
            StorageUtil.UnsetFloatValue(target, key)
            YourMod.AddCorruptionResist(target, -applied)
        endif
    endif
EndFunction
```

The base class provides everything else: reading the catalog, registration, the menu, saving presets, and calling your hooks.

### Conditions

```papyrus
bool Function checkCondition(Actor target, int param, string cid)
```

- `param` is the first parameter when it's a slider.
- Every other value comes from the host, and is only valid during this call:

| Value | Read with |
|---|---|
| Parameter 2 or 3 as a slider | `_host().GetEvalParam2()`, `_host().GetEvalParam3()` |
| Parameter 1, 2 or 3 as a menu id or text | `_host().GetEvalParamStr()`, `GetEvalParam2Str()`, `GetEvalParam3Str()` |

- It runs every 2 s for every tracked actor, so keep it cheap. Resolve forms once in `_resolveDeps` and cache them in `Auto Hidden` properties, and don't call `GetFormFromFile` here.
- MTF combines several conditions on one tier with AND or OR itself. Each `checkCondition` only answers for one.

### Effects

```papyrus
Function onActivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
Function onDeactivate(...)   ; same arguments
Function onTick(...)         ; every evaluation tick while showing, continuous effects only
Function onGameTime(...)     ; once per in-game hour while showing, continuous effects only
```

- `param` and `param2` are parameters 1 and 2 as sliders or colors.
- For parameters 3 to 5, and for any menu or text parameter, pass the hook's own arguments to the base class helpers:

```papyrus
int    p3   = _paramNEx(slot, effectIdx, useScratch, presetName, 3)
string mode = _paramNStrEx(slot, effectIdx, useScratch, presetName, 1)
```

  Don't use `_host()._getDispatchSlot()` or `_getDispatchEffectIdx()`. They read shared state that another script can overwrite while yours waits on a native call. The hook's own arguments can't change under you.
- Key any per-actor state on `slot` and `effectIdx` as well as the actor (`"mtf.yourmod.slow." + slot + "." + effectIdx`), so the same effect on two tiers or two presets doesn't collide.
- `onDeactivate` may be called without a matching `onActivate`, so it must be safe when nothing was stored.

### Undo what you change

The default `onDeactivate` does nothing. If `onActivate` changes something that lasts (`ModActorValue`, `AddSpell`, a flag in your mod, a shader that keeps playing) and you don't undo it, taking the tattoo off leaves the change in place, with no error anywhere. Only two kinds of effect may skip it:

1. One-shot effects (an item, a stagger, a message). Mark these `"kind": "burst"`.
2. Changes that are meant to decay on their own in your mod's systems, where reversing them would be wrong.

### Write state before any call that waits

Calls on forms (`ModActorValue`, `AddSpell`, most calls into another script) pause your script for a frame, and a second activation can run in that gap. Store what you applied in `StorageUtil` **before** that call, so a second run sees it:

```papyrus
float prev = StorageUtil.GetFloatValue(target, key, 0.0)
if prev == newDelta
    return
endif
StorageUtil.SetFloatValue(target, key, newDelta)
target.ModActorValue("CarryWeight", newDelta - prev)
```

### Optional hooks

- `_resolveDeps()`: return false until your mod's forms resolve. The default returns true, for a plugin with no dependency.
- `_onRegistered()`: runs once per session, after MTF accepts the plugin. Put things that must happen on every load in an alias's `OnPlayerLoadGame` instead, as [`MTF_Plugin_SkyrimNet`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/source/scripts/MTF_Plugin_SkyrimNet.psc) does.
- `_host()._condIdxFor(self, cid)` and `_effectIdxFor(self, eid)`: the catalog position, if you need to read other catalog fields.

### Script variables after release

Adding new `Auto` properties to a script that's already in players' saves doesn't always work: on old saves, writes to them can silently do nothing. Put any state you add after the first release in `StorageUtil`. Keep script-level variables few in general. MTF learned this when it added about 30 to its base class and save loading hung.

---

## The ESP

Copy one of MTF's plugin ESPs rather than making one from scratch. In MTF's repo, [`spriggit/MTF_Plugin_BFNG/`](https://github.com/levchimik/magic-tattoos-framework/tree/1df07d2e/spriggit/MTF_Plugin_BFNG) is the whole ESP as YAML:

- ESL-flagged, with FormIDs from `0x800`.
- Master: `MagicTattoosFramework.esp`, plus `Skyrim.esm` for the player reference. Your own mod should *not* be a master.
- **One quest**, flagged Start Game Enabled, with your `MTF_Plugin_<YourMod>` script attached.
- **One reference alias** on that quest, `PluginKickAlias`, forced to `PlayerRef` (`Skyrim.esm` `0x14`), with `MTF_PluginAliasKick` attached. Without it, a plugin whose first registration attempt was lost stays unregistered for the whole session.
- Nothing else: no spells, perks or NPCs.

To build it from MTF's repo: copy the folder to `spriggit/MTF_Plugin_<YourMod>/`, set `ModKey` in `spriggit-meta.json`, rename the quest YAML and change its `EditorID`, `Name` and script name, then run `bash tools/build_esps.sh MTF_Plugin_<YourMod>`. In the Creation Kit or xEdit, make the same records by hand.

### Compiling

The compiler needs these sources on its import path:

- MTF's `source/scripts` (at least `MTF_Plugin.psc` and `MTF_MainQuest.psc`, and whatever `MTF_MainQuest.psc` imports)
- PapyrusUtil SE's sources (`StorageUtil`, `JsonUtil`)
- SKSE's and the base game's sources
- your mod's scripts, for the types you cast to

Don't ship any `MTF_*.pex` other than your own. `MTF_Plugin.pex` and `MTF_PluginAliasKick.pex` come with MTF.

### What the patch contains

```
MTF_Plugin_YourMod.esp
Scripts/MTF_Plugin_YourMod.pex
SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/mtf.yourmod.json
```

---

## Listening to MTF without a plugin

MTF sends these mod events. Register for them from a reference alias or active magic effect, since a quest script can't call `RegisterForModEvent`. All of them use the `(string strArg, float numArg, Form sender)` signature.

| Event | `strArg` | `numArg` | `sender` |
|---|---|---|---|
| `MTF_FrameworkReady` | `"<version>|<pluginCount>"` | plugin count | MTF's host quest |
| `MTF_TierChanged` | `"<scope>|<presetName>|<prevTier>|<newTier>"`, where scope is `player` or `preset` and tier `-1` means none | new tier | the actor |
| `MTF_EffectActivated` | `"<pluginId>:<effectId>|<slot>"` | slot | the actor |
| `MTF_EffectDeactivated` | same | slot | the actor |

`MTF_TierChanged` is sent after the new tier's effects have run. The effect events are sent once per effect, so a tier with three effects sends three. These are a good fit for a mod that only needs to know a tattoo appeared, such as dialogue or comments, and they need no ESP for MTF.

```papyrus
Event OnInit()
    RegisterForModEvent("MTF_EffectActivated", "OnMtfEffectOn")
EndEvent

Event OnPlayerLoadGame()
    RegisterForModEvent("MTF_EffectActivated", "OnMtfEffectOn")
EndEvent

Event OnMtfEffectOn(string strArg, float numArg, Form sender)
    if StringUtil.Find(strArg, "mtf.yourmod:") == 0
        ; ...
    endif
EndEvent
```

## Applying presets from your mod

Send these to MTF. `strArg` is the preset's file name without `.json`, not its display name. `sender` is the target actor, and `None` means the player.

| Event | Does | Answer event |
|---|---|---|
| `MTF_ApplyPreset` | applies the preset | `MTF_ApplyPresetResult`: `"<name>|<rc>"`, `numArg` = rc |
| `MTF_RemovePreset` | removes it, but only if this API applied it | `MTF_RemovePresetResult`: `"<name>|<status>"`, `numArg` 1 if removed |
| `MTF_RemoveAllPresets` | removes every preset this API applied to the actor | `MTF_RemoveAllPresetsResult`: `"<count>"` |
| `MTF_StopAllShaders` | stops every shader MTF can play on the actor | none |

Apply result codes: `1` applied, `0` already on (and not tracked, so the API won't remove it later), `-2` no target, `-3` too many presets on that NPC, `-4` empty name, `-5` invalid preset, `-6` no free overlay slots, `-7` would be cut short. Remove statuses: `removed`, `not-tracked-by-api`, `no-target`, `no-name`.

```papyrus
int h = ModEvent.Create("MTF_ApplyPreset")
if h
    ModEvent.PushString(h, "my_mark_preset")
    ModEvent.PushFloat(h, 0.0)
    ModEvent.PushForm(h, someActor)
    ModEvent.Send(h)
endif
```

The API keeps its own list per actor (`StorageUtil` string list `mtf.api.applied`), so it never removes a preset the player put on by hand. To ship presets with your mod, put them in `Data/SKSE/Plugins/StorageUtilData/MagicTattoosFramework/presets/`, or in `presets_builtin/` if players shouldn't be able to overwrite them, and check them with MTF's web preset validator.

---

## Testing

1. Install the patch, load a save with your mod and MTF running, and wait a few seconds.
2. The Papyrus log (`Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`) should show `[MTF_Main] Registered 'mtf.yourmod' (Your Mod, N conditions, M effects)`. A `catalog schema` warning means `schemaversion` is wrong.
3. Your plugin should appear on the Plugins page of MTF's menu, and its conditions and effects in the tier pickers. Magic Tattoos UI reads the same catalog folder, so it shows them too: on its Plugins tab, and in the Condition and Effects tabs of the tier editor, with your sliders, menus and descriptions.
4. Put one of your conditions on a tier, apply the preset, and make the condition true. The tier should switch within about 2 s.
5. Add your effects to that tier and watch them start and stop. Temporary `Debug.Trace("MTF.YourMod: onActivate " + eid)` lines help.
6. For continuous effects, switch tiers back and forth, then run `cqf MTF_MainQuest DumpLifecycleAudit` in the console (the counters need Debug mode on in MTF's menu). Any non-zero entry in the log under `mtf.yourmod.<effectId>` means `onDeactivate` missed something. `cqf MTF_MainQuest ResetLifecycleAudit` starts the count over.

If it never registers:

- Check that the catalog's file name, its `pluginid`, and `GetPluginId()` are all the same string, and that the catalog has only lowercase keys.
- Check that `_resolveDeps()` returns true. A temporary `Debug.Notification` showing the resolved form helps, and a wrong FormID or a wrong cast both return `None`.
- Check that the ESP is enabled and the quest is Start Game Enabled. For a save that already ran without the kick alias, the quest may need `stopquest` and `startquest` in the console.
- MTF holds 32 plugins, and its own use about 15. When the list is full, the log says `RegisterPlugin REJECTED: registry full`.
- A player can turn a whole plugin, or single items, off in MTF's menu. Turned-off items disappear from the pickers.

---

## Where MTF's guide is out of date

`docs/INTEGRATION_PLUGINS.md` in MTF's repo disagrees with the code in these places. Go by the code.

- **Effect hook signatures.** The guide shows `onActivate(Actor target, int param, int param2, string eid)`. Since v0.2.10 and v0.2.12 all four hooks take ten arguments: `..., string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName`. A script with the old four-argument signature defines a different function, so MTF's calls never reach it.
- **Reading parameters 3 to 5 and menu values in effects.** The guide uses `_host()._getDispatchSlot()` and `GetSlotEffectParamNStr(slot, eff, n)`. The base class says that shared context is unsafe and to use `_paramNEx` and `_paramNStrEx` with the hook's own arguments.
- **The ESP.** The guide says the quest needs nothing but the plugin script. Every plugin ESP MTF ships also has the `PluginKickAlias` reference alias with `MTF_PluginAliasKick`, which is what recovers registration after a lost update.
- **Parameter types.** The guide lists sliders and menus, and at most two condition parameters. The code also supports `text` parameters (conditions and effects), `color` parameters (effects), and a third condition parameter (`param3`, slider or text) read with `GetEvalParam3()` and `GetEvalParam3Str()`.
- **Validator.** `validate_catalogs.py` still describes only sliders and menus, so it may not know the text and color types.

## Shipped plugins worth reading

| Plugin | Shows |
|---|---|
| [`MTF_Plugin_BFNG`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/source/scripts/MTF_Plugin_BFNG.psc) | The basic shape: quest probe, menu conditions, bursts, continuous effects that save and restore a flag, hourly upkeep. Start here. |
| [`MTF_Plugin_SLA`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/source/scripts/MTF_Plugin_SLA.psc) | `param2`, `onGameTime`, a menu value in parameter 3, writing state before a call that waits. |
| [`MTF_Plugin_OStim`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/source/scripts/MTF_Plugin_OStim.psc) | A global as the dependency probe, text parameters. |
| [`MTF_Plugin_SkyrimNet`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/source/scripts/MTF_Plugin_SkyrimNet.psc) | No conditions or effects, `_onRegistered`, setup on every load. |
| [`MTF_Plugin_Base`](https://github.com/levchimik/magic-tattoos-framework/blob/1df07d2e/source/scripts/MTF_Plugin_Base.psc) | Every catalog feature and every way of calling hooks. Large, so use it as a reference. |
