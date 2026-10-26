# Magic Tattoos Framework connectors

Small patch mods that let [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF) use other mods: their state as tattoo tier **conditions**, and their features as tier **effects**. Each connector is its own release and its own mod, with its own version, plugin, and build. Install only the connectors for mods you use; they don't depend on each other.

| Connector | Connects | Mod name | Plugin id |
| --- | --- | --- | --- |
| [sacrosanct](connectors/sacrosanct/README.md) | [Sacrosanct - Vampires of Skyrim](https://www.nexusmods.com/skyrimspecialedition/mods/3928) | MTF Plugin - Sacrosanct | `proteux-mtf.sacrosanct` |

See [docs/mtf-integration.md](docs/mtf-integration.md) for how MTF plugins work.

## Layout

- `connectors/<name>/` holds one connector: `VERSION`, `Makefile`, `build.sh`, its Papyrus source, compile stubs, and its MTF catalog under `SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/`. `build.sh` sets the mod name (`MOD_NAME`), plugin file (`ESP_BASE`), and MTF plugin id (`PLUGIN_ID`); the build refuses to run if another connector uses any of the same three. Connector folder names can't be `all`, `list`, `run`, or an action name, since the root Makefile reads them as goals.
- `shared/build-common.sh` does the work for every connector: validate the catalog, compile, generate the ESP, assemble the mod in `dist/mod`, then copy it into Data, stage it for Vortex, or package it.
- `shared/tools/PluginGen/` generates the ESL-flagged plugin ESP that MTF expects (one Start Game Enabled quest with the plugin script, and a `PluginKickAlias` on the player with `MTF_PluginAliasKick`).
- `shared/stubs/` holds compile-only stubs for scripts MTF imports that aren't installed. They are never shipped.
- `vendor/magic-tattoos-framework/` is MTF's repository as a git submodule, pinned to the commit the docs were checked against. Builds compile against its `source/scripts` and run its catalog validator.

## Building

Clone with `git clone --recursive`, or run `git submodule update --init` after cloning.

```bash
make list                          # connectors (plain `make` does the same)
make live sacrosanct                # build and copy straight into the game's Data folder (plain `make sacrosanct` does the same)
make uninstall-live sacrosanct      # delete the connector's files from Data
make package sacrosanct             # write connectors/sacrosanct/dist/<plugin>-<version>.zip
make live all                       # build every connector into Data
make package all                    # package every connector, one zip each
```

The form is `make [action...] <connector...|all>`; actions run in the order given, so `make uninstall-live live sacrosanct` does a clean reinstall. Order between actions and connectors doesn't matter, so `make sacrosanct live` works too. Actions: `live`, `staging`, `package`, `uninstall-live`, `uninstall-staging`. A new action goes in `ACTIONS` in the root `Makefile`, the connector `Makefile`s, and `shared/build-common.sh`.

The default build copies into `<SKYRIM_DIR>/Data`, so a rebuild only needs a Skyrim restart, with no mod manager deploy. Every target copies the same files, assembled in `dist/mod`, which are exactly what the release zip holds. Enable the connector's ESP in your load order once after the first build.

### Vortex staging (optional)

`make staging <connector>` writes the connector to its own Vortex mod folder instead, `<VORTEX_MODS>/<MOD_NAME>` (for example `.../Vortex/skyrimse/mods/MTF Plugin - Sacrosanct`), with a `meta.ini` holding the version. Enable it in Vortex and deploy after each build; `uninstall-staging` deletes the folder. Don't combine the two: a deploy of an enabled staged mod replaces files that `live` copied, and `live` warns when a staged copy exists.

Requirements: Git Bash, the Papyrus Compiler (the build uses the one Nemesis installs under `Data/Nemesis_Engine/Papyrus Compiler`), `TESV_Papyrus_Flags.flg` in `Data/Source/Scripts` or `Data/Scripts/Source`, the .NET SDK, and Python 3. Scripts compile against the stubs in `shared/stubs` and each connector's `Scripts/CompileStubs`, plus MTF's sources from the submodule, so the game's script sources don't need to be installed. When a connector calls a game, SKSE, or PapyrusUtil function that no stub declares yet, add it to `shared/stubs` with the signature copied from the real source.

The default paths point to the author's machine. Set `SKYRIM_DIR` (the game folder), `VORTEX_MODS` (Vortex's `skyrimse/mods` folder), or `PAPYRUS_COMPILER` to override them.
