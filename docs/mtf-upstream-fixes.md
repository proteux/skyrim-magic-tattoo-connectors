# MTF fixes to make upstream

Bugs found in Magic Tattoos Framework (v0.7.0) while debugging the connectors. The connectors work around them,
but MTF should fix them so every plugin benefits, and the workarounds can then go.

## Dead plugin copies stay in the registry and block re-registration

**Seen:** after the RaceMenu connector was uninstalled for a session and reinstalled, none of its effects applied,
on any actor, including live previews from the SKSE UI. MTF never called `onActivate` or `onTick` on it.

**Cause:** `MTF_MainQuest.registeredPlugins` held a copy of `MTF_Plugin_RaceMenu` whose quest no longer exists
(it logs as `[MTF_Plugin_RaceMenu <None>]`). The script object survives in the save and still answers
`GetPluginId()` with `proteux-mtf.racemenu`, so:

- `FindPluginIndex` / `FindPlugin` return the dead copy, and every dispatch goes to it. It has none of its
  properties (no `PlayerRef`), so it does nothing.
- `RegisterPlugin` sees the id as already registered and returns silently, so the live quest can never take its
  place. Nothing is logged.

**Fix in MTF:** in `FindPluginIndex`, skip entries whose owning form is gone, e.g. check
`(slot as Quest) != None` and that `slot.GetFormID() != 0`, or compare against a fresh `Game.GetFormFromFile` of
the plugin's quest. Better still, have `RegisterPlugin` replace an existing entry with the same id when the caller
is a different object, and log it. Also consider compacting `None` entries out of the registry on load (the
removed `MTF_Plugin_BaseExtended` left one at index 11 in the same save).

**Connector workaround to remove afterwards:** `_replaceStale` and `_checkRegistered` in `MTF_Plugin_RaceMenu.psc`
and `MTF_Plugin_Skyrim.psc`, which overwrite the stale registry slot with `self` on load and registration.

## `_registered` never resets, so a lost plugin never registers again

**Cause:** `MTF_Plugin._tryRegister` returns at once when `_registered` is true. `_registered` lives in the save,
so if MTF's registry loses the plugin (or holds a dead copy, above), the `MTF_PluginKick` re-arm can't help.

**Fix in MTF:** in `_tryRegister`, check `host.FindPlugin(GetPluginId()) == self` instead of trusting the flag
alone, and register again when it isn't.

## Smaller things noticed

- `RegisterPlugin` returns silently when the id is already registered. A `Trace` there would have made the
  above a five-minute diagnosis.
- `MTF_Plugin.psc` line 99, `host.registeredPlugins == None`, logs `Cannot cast from None to Form[]` when called
  from a load event. It's the known array-compare-with-None quirk; compare `pluginCount` or `_arraysReady` instead.
- Saves still reference `MTF_Plugin_BaseExtended` and `MTF_Plugin_BaseExtended_Load`, and the main quest's player
  alias still references `MTF_TestRunner`, which isn't shipped. Each load logs errors for them.
