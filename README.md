# Magic Tattoos Framework connectors

Small patch mods that let [Magic Tattoos Framework](https://www.nexusmods.com/skyrimspecialedition/mods/180775) (MTF) use other mods: their state as tattoo tier **conditions**, and their features as tier **effects**. Each connector is its own release and its own mod, with its own version, plugin, and build. Install only the connectors for mods you use; they don't depend on each other.

| Connector | Connects | Mod name | Plugin id |
| --- | --- | --- | --- |
| [base](connectors/base/README.md) | Skyrim itself, beyond MTF's own Base plugin | MTF Plugin - Base Extended | `proteux-mtf.base` |
| [racemenu](connectors/racemenu/README.md) | [RaceMenu](https://www.nexusmods.com/skyrimspecialedition/mods/19080) and BodySlide morphs | MTF Plugin - RaceMenu | `proteux-mtf.racemenu` |
| [sacrosanct](connectors/sacrosanct/README.md) | [Sacrosanct - Vampires of Skyrim](https://www.nexusmods.com/skyrimspecialedition/mods/3928) | MTF Plugin - Sacrosanct | `proteux-mtf.sacrosanct` |
| [wetfunction](connectors/wetfunction/README.md) | [Wet Function Redux SE](https://www.nexusmods.com/skyrimspecialedition/mods/78804) | MTF Plugin - Wet Function Redux | `proteux-mtf.wetfunction` |

See [docs/mtf-integration.md](docs/mtf-integration.md) for how MTF plugins work.

## Layout

- `connectors/<name>/` holds one connector: `VERSION`, `CHANGELOG.md`, `Makefile`, `build.sh`, its Nexus page in `nexus/`, its Papyrus source, compile stubs, and its MTF catalog under `SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/`. `build.sh` sets the mod name (`MOD_NAME`), plugin file (`ESP_BASE`), and MTF plugin id (`PLUGIN_ID`); the build refuses to run if another connector uses any of the same three. Connector folder names can't be `all`, `list`, `run`, or an action name, since the root Makefile reads them as goals.
- `shared/build-common.sh` does the work for every connector: validate the catalog, compile, generate the ESP, assemble the mod in `dist/mod`, then copy it into Data, stage it for Vortex, or package it.
- `shared/tools/PluginGen/` generates the ESL-flagged plugin ESP that MTF expects (one Start Game Enabled quest with the plugin script, and a `PluginKickAlias` on the player with `MTF_PluginAliasKick`). A connector that needs player events, such as `OnPlayerLoadGame`, which quest scripts never receive, lists extra alias scripts in `ALIAS_SCRIPTS` in its `build.sh`. Each one is named `<ESP_BASE>_<Something>`, and the build compiles it, attaches it to the same alias, and ships it.
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

## Releasing on Nexus Mods

Each connector is its own Nexus page. To release one:

1. Bump `VERSION` and `MOD_VERSION` in the plugin script together, and add a `## <version>` section with `- ` entries to the connector's `CHANGELOG.md`. `make package` refuses to run without one.
2. If the README changed, make the same change in the connector's `nexus/description.bbcode`.
3. Run the checks in the connector's `TESTING.md` against a build made with `make live <connector>`.
4. Run `make package <connector>`.
5. On Nexus, upload `dist/<plugin>-<version>.zip` as a Main file, paste `nexus/summary.txt` into the summary (350 characters at most) and `nexus/description.bbcode` into the Description tab, add the changelog lines, and link the requirements. Archive the previous file when updating.
6. Tag the commit `<connector>-v<version>`, for example `sacrosanct-v0.1.0`, and push the tag.

`nexus/description.bbcode` is the Nexus page, written by hand in Nexus BBCode. It follows the README, but Nexus has no tables, so table rows are list items, and links to repository files are full GitHub URLs. "Building from source" is left out in favour of a link to this repository, and the page ends with the license and source notice.

The Nexus permissions can't be stricter than the GPL, so set every one of them to allowed: upload, modification, conversion, and asset use (each with credit, which the GPL's notice requirement already asks for), including in mods that are sold or earn donation points. Leave "Other user's assets" off, since nothing from other authors ships. Put this in the author notes:

```
Licensed under the GNU General Public License v3.0 or later. Where these settings and the license differ, the license applies. Full source: https://github.com/proteux/skyrim-magic-tattoo-connectors
```

## License

Copyright (C) 2026 Jack Whitehouse (proteux). Everything in this repository outside `vendor/` is released under the GNU General Public License v3.0 or later; see [LICENSE](LICENSE). Magic Tattoos Framework, which the connectors extend, is GPL-3.0-or-later too, and Mutagen, which `PluginGen` uses, is GPL-3.0. Each release zip carries the license text and a notice with the source location in `SKSE/Plugins/<plugin>/`.
