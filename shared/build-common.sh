#!/usr/bin/env bash
# Shared build for MTF connectors. Each connector's build.sh sets the variables below and sources this file.
# Usage (through a connector): build.sh [live|staging|package|uninstall-live|uninstall-staging], default live
#
# Required from the connector:
#   CONNECTOR_DIR  the connector folder
#   ESP_BASE       plugin file name without .esp, which is also the plugin script name (MTF_Plugin_<Mod>)
#   PLUGIN_ID      MTF plugin id; the catalog must be plugins/<PLUGIN_ID>.json
#   MOD_NAME       display name, used for the Vortex mod folder and the quest name
# All three must be unique across connectors: each connector releases as its own mod.
# Optional:
#   AUTHOR, DESCRIPTION  written into the ESP header
#   ALIAS_SCRIPTS        space-separated extra scripts attached to the player alias (for player events such
#                        as OnPlayerLoadGame, which quest scripts never receive). Each name must start with
#                        ${ESP_BASE}_ and have a matching Scripts/Source/<name>.psc.
#   COLOR_FORMS          how many color records (CLFM) the ESP carries, FormIDs 0x801 up, for scripts that set
#                        colors at runtime. Default 0.
#
# Environment overrides: SKYRIM_DIR, VORTEX_MODS, PAPYRUS_COMPILER, PLUGINS_TXT.
set -euo pipefail

: "${CONNECTOR_DIR:?}" "${ESP_BASE:?}" "${PLUGIN_ID:?}" "${MOD_NAME:?}"
AUTHOR="${AUTHOR:-}"
DESCRIPTION="${DESCRIPTION:-}"
read -r -a ALIAS_LIST <<< "${ALIAS_SCRIPTS:-}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-live}"
GAME="${SKYRIM_DIR:-/c/Program Files (x86)/Steam/steamapps/common/Skyrim Special Edition}"
DATA="$GAME/Data"
STAGING="${VORTEX_MODS:-/c/Users/white/AppData/Roaming/Vortex/skyrimse/mods}/$MOD_NAME"
DIST="$CONNECTOR_DIR/dist"
MTF="$REPO_ROOT/vendor/magic-tattoos-framework"
CATALOG_REL="SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins"
LICENSE_REL="SKSE/Plugins/$ESP_BASE"
REPO_URL="https://github.com/proteux/skyrim-magic-tattoo-connectors"
CATALOG="$CONNECTOR_DIR/$CATALOG_REL/$PLUGIN_ID.json"
SCRIPT_SRC="$CONNECTOR_DIR/Scripts/Source/$ESP_BASE.psc"
PLUGINS_TXT="${PLUGINS_TXT:-$(cygpath -u "${LOCALAPPDATA:-C:\\Users\\white\\AppData\\Local}")/Skyrim Special Edition/plugins.txt}"

# The game's active load order: "*Name.esp" is enabled, a bare "Name.esp" is listed but off.
warn_if_not_enabled() {
  local esp="$ESP_BASE.esp"
  if [[ ! -f "$PLUGINS_TXT" ]]; then
    echo "Warning: couldn't find $PLUGINS_TXT to check whether $esp is enabled. Set PLUGINS_TXT to its path." >&2
    return
  fi
  local lines
  lines="$(tr -d '\r' < "$PLUGINS_TXT")"
  if grep -qixF "*$esp" <<< "$lines"; then
    echo "$esp is enabled in the load order."
  elif grep -qixF "$esp" <<< "$lines"; then
    echo "Warning: $esp is in the load order but NOT enabled, so its script will never run (MTF still lists the catalog)." >&2
    echo "         Enable it in your mod manager's Plugins tab, then check again: $PLUGINS_TXT" >&2
  else
    echo "Warning: $esp is not in the load order yet, so its script will never run (MTF still lists the catalog)." >&2
    echo "         Enable it in your mod manager's Plugins tab (Vortex may need F5 to see it), then check again: $PLUGINS_TXT" >&2
  fi
}

remove_from() {
  local root="$1"
  rm -f "$root/$ESP_BASE.esp" "$root/Seq/$ESP_BASE.seq" "$root/Scripts/$ESP_BASE.pex" \
    "$root/Scripts/Source/$ESP_BASE.psc" "$root/$CATALOG_REL/$PLUGIN_ID.json"
  rm -rf "${root:?}/$LICENSE_REL"
  local alias
  for alias in "${ALIAS_LIST[@]}"; do
    rm -f "$root/Scripts/$alias.pex" "$root/Scripts/Source/$alias.psc"
  done
}

case "$TARGET" in
  staging|live|package) ;;
  uninstall-live)
    remove_from "$DATA"
    echo "Removed $MOD_NAME from $DATA"
    exit 0
    ;;
  uninstall-staging)
    if [[ -d "$STAGING" ]]; then
      rm -rf "$STAGING"
      echo "Removed $STAGING"
      echo "Vortex will list the mod as missing. Remove it there, then deploy."
    else
      echo "Nothing staged at $STAGING"
    fi
    exit 0
    ;;
  *)
    echo "Unknown target '$TARGET'. Use live, staging, package, uninstall-live, or uninstall-staging." >&2
    exit 1
    ;;
esac

if [[ ! -f "$MTF/source/scripts/MTF_Plugin.psc" ]]; then
  echo "MTF sources are missing. Run: git submodule update --init" >&2
  exit 1
fi

for other in "$REPO_ROOT"/connectors/*/build.sh; do
  [[ "$(cd "$(dirname "$other")" && pwd)" == "$CONNECTOR_DIR" ]] && continue
  for var in MOD_NAME ESP_BASE PLUGIN_ID; do
    if grep -qxF "$var=\"${!var}\"" "$other"; then
      echo "$var \"${!var}\" is also set in $other. Each connector needs its own Vortex mod, plugin, and id." >&2
      exit 1
    fi
  done
done

VERSION="$(tr -d '[:space:]' < "$CONNECTOR_DIR/VERSION")"
if ! grep -q "MOD_VERSION = \"$VERSION\"" "$SCRIPT_SRC"; then
  echo "MOD_VERSION in $SCRIPT_SRC does not match VERSION ($VERSION)" >&2
  exit 1
fi
if [[ "$TARGET" == package ]] && ! grep -qxF "## $VERSION" "$CONNECTOR_DIR/CHANGELOG.md" 2> /dev/null; then
  echo "$CONNECTOR_DIR/CHANGELOG.md has no '## $VERSION' section. Add the release notes before packaging." >&2
  exit 1
fi
if ! grep -q "return \"$PLUGIN_ID\"" "$SCRIPT_SRC"; then
  echo "GetPluginId() in $SCRIPT_SRC does not return \"$PLUGIN_ID\"" >&2
  exit 1
fi
if [[ ! -f "$CATALOG" ]]; then
  echo "Catalog not found: $CATALOG" >&2
  exit 1
fi
if ! grep -q "\"pluginid\": \"$PLUGIN_ID\"" "$CATALOG"; then
  echo "pluginid in $CATALOG is not \"$PLUGIN_ID\"" >&2
  exit 1
fi
for alias in "${ALIAS_LIST[@]}"; do
  if [[ "$alias" != "${ESP_BASE}_"* ]]; then
    echo "Alias script $alias must start with ${ESP_BASE}_ so it cannot collide with another mod's script" >&2
    exit 1
  fi
  if [[ ! -f "$CONNECTOR_DIR/Scripts/Source/$alias.psc" ]]; then
    echo "Alias script source not found: $CONNECTOR_DIR/Scripts/Source/$alias.psc" >&2
    exit 1
  fi
done

echo "=== validating catalog ==="
python "$(cygpath -w "$MTF/tools/validate_catalogs.py")" "$(cygpath -w "$CONNECTOR_DIR/$CATALOG_REL")"

echo "=== compiling $ESP_BASE ==="
COMPILER="$(cygpath -w "${PAPYRUS_COMPILER:-$DATA/Nemesis_Engine/Papyrus Compiler/PapyrusCompiler.exe}")"
FLAGS=""
for flg in "$DATA/Source/Scripts/TESV_Papyrus_Flags.flg" "$DATA/Scripts/Source/TESV_Papyrus_Flags.flg"; do
  if [[ -f "$flg" ]]; then
    FLAGS="$(cygpath -w "$flg")"
    break
  fi
done
if [[ -z "$FLAGS" ]]; then
  echo "TESV_Papyrus_Flags.flg not found in $DATA/Source/Scripts or $DATA/Scripts/Source" >&2
  exit 1
fi
IMPORTS="$(cygpath -w "$CONNECTOR_DIR/Scripts/Source")"
# Stubs only, never the game's Data sources: installs rarely have the full vanilla set, and a partial set
# fails on whatever it is missing. Stubs come before MTF so the stub MTF_MainQuest wins over the real one.
for dir in "$CONNECTOR_DIR/Scripts/CompileStubs" "$REPO_ROOT/shared/stubs" "$MTF/source/scripts"; do
  [[ -d "$dir" ]] && IMPORTS="$IMPORTS;$(cygpath -w "$dir")"
done
rm -rf "$DIST"
mkdir -p "$DIST/Scripts"
(
  cd "$CONNECTOR_DIR/Scripts/Source"
  export MSYS_NO_PATHCONV=1
  for script in "$ESP_BASE" "${ALIAS_LIST[@]}"; do
    "$COMPILER" "$script.psc" -f="$FLAGS" -i="$IMPORTS" -o="$(cygpath -w "$DIST/Scripts")" -op
  done
)
SHIPPED=("$ESP_BASE" "${ALIAS_LIST[@]}")
for script in "${SHIPPED[@]}"; do
  if [[ ! -f "$DIST/Scripts/$script.pex" ]]; then
    echo "Compile produced no $script.pex" >&2
    exit 1
  fi
done
for pex in "$DIST/Scripts/"*.pex; do
  name="$(basename "$pex" .pex)"
  if [[ " ${SHIPPED[*]} " != *" $name "* ]]; then
    echo "Removing $name.pex from dist. Only ${SHIPPED[*]} ship; MTF and stub scripts must not be overwritten."
    rm -f "$pex"
  fi
done

echo "=== generating $ESP_BASE.esp ==="
(
  export MSYS_NO_PATHCONV=1
  dotnet run --project "$(cygpath -w "$REPO_ROOT/shared/tools/PluginGen/PluginGen.csproj")" -- \
    --out "$(cygpath -w "$DIST/$ESP_BASE.esp")" --script "$ESP_BASE" --name "$MOD_NAME" \
    --author "$AUTHOR" --description "$DESCRIPTION" --alias-scripts "$(IFS=,; echo "${ALIAS_LIST[*]}")" \
    --color-forms "${COLOR_FORMS:-0}"
)

# The mod exactly as it ships, laid out as it sits in Data. Staging, live, and the zip all use this folder.
MODROOT="$DIST/mod"
mkdir -p "$MODROOT/Scripts/Source" "$MODROOT/Seq" "$MODROOT/$CATALOG_REL"
cp -f "$DIST/$ESP_BASE.esp" "$MODROOT/"
cp -f "$DIST/Seq/$ESP_BASE.seq" "$MODROOT/Seq/"
for script in "${SHIPPED[@]}"; do
  cp -f "$DIST/Scripts/$script.pex" "$MODROOT/Scripts/"
  cp -f "$CONNECTOR_DIR/Scripts/Source/$script.psc" "$MODROOT/Scripts/Source/"
done
cp -f "$CATALOG" "$MODROOT/$CATALOG_REL/"
# GPL-3.0 needs the license text and the source location to travel with the binaries.
mkdir -p "$MODROOT/$LICENSE_REL"
cp -f "$REPO_ROOT/LICENSE" "$MODROOT/$LICENSE_REL/LICENSE.txt"
cat > "$MODROOT/$LICENSE_REL/README.txt" << EOF
$MOD_NAME $VERSION
An add-on for Magic Tattoos Framework.

Copyright (C) 2026 Jack Whitehouse (proteux)

This program is free software: you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version. It comes with ABSOLUTELY NO WARRANTY; see
LICENSE.txt in this folder for the full terms.

The Papyrus source ships in Scripts/Source. The full source, including the build that produces
$ESP_BASE.esp, is at $REPO_URL
EOF

case "$TARGET" in
  staging)
    # The staging folder belongs to this connector alone, so clear it to drop files an older build shipped.
    mkdir -p "$STAGING"
    find "$STAGING" -mindepth 1 -maxdepth 1 ! -name meta.ini -exec rm -rf {} +
    cp -rf "$MODROOT/." "$STAGING/"
    if [[ ! -f "$STAGING/meta.ini" ]]; then
      cat > "$STAGING/meta.ini" << EOF
[General]
gameName=SkyrimSE
modid=0
version=$VERSION
installationFile=$MOD_NAME
repository=local
EOF
    fi
    sed -i "s/^version=.*/version=$VERSION/" "$STAGING/meta.ini"
    echo "Staged $VERSION at $STAGING"
    echo "In Vortex, enable the mod '$MOD_NAME' (it appears on its own; press F5 in the Mods tab if not), deploy, then restart Skyrim."
    warn_if_not_enabled
    ;;
  live)
    if ! cp -rf "$MODROOT/." "$DATA/"; then
      echo "Couldn't copy everything into $DATA. Skyrim locks loaded plugins while it runs; quit the game and run this again." >&2
      warn_if_not_enabled
      exit 1
    fi
    echo "Copied $VERSION into $DATA"
    echo "Restart Skyrim."
    if [[ -d "$STAGING" ]]; then
      echo "Warning: a Vortex mod for this connector is staged at $STAGING. Disable it, or run uninstall-staging, so a deploy does not replace these files." >&2
    fi
    warn_if_not_enabled
    ;;
  package)
    ZIP="$DIST/$ESP_BASE-$VERSION.zip"
    # Windows bsdtar, not Git Bash's GNU tar, which cannot write zips. Compress-Archive in Windows PowerShell writes backslash paths.
    "$(cygpath -u "$SYSTEMROOT")/System32/tar.exe" -a -cf "$(cygpath -w "$ZIP")" -C "$(cygpath -w "$MODROOT")" "$ESP_BASE.esp" Scripts Seq SKSE
    echo "Packaged $VERSION at $ZIP"
    ;;
esac
