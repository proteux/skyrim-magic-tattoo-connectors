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
#
# Environment overrides: SKYRIM_DIR, VORTEX_MODS, PAPYRUS_COMPILER.
set -euo pipefail

: "${CONNECTOR_DIR:?}" "${ESP_BASE:?}" "${PLUGIN_ID:?}" "${MOD_NAME:?}"
AUTHOR="${AUTHOR:-}"
DESCRIPTION="${DESCRIPTION:-}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-live}"
GAME="${SKYRIM_DIR:-/c/Program Files (x86)/Steam/steamapps/common/Skyrim Special Edition}"
DATA="$GAME/Data"
STAGING="${VORTEX_MODS:-/c/Users/white/AppData/Roaming/Vortex/skyrimse/mods}/$MOD_NAME"
DIST="$CONNECTOR_DIR/dist"
MTF="$REPO_ROOT/vendor/magic-tattoos-framework"
CATALOG_REL="SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins"
CATALOG="$CONNECTOR_DIR/$CATALOG_REL/$PLUGIN_ID.json"
SCRIPT_SRC="$CONNECTOR_DIR/Scripts/Source/$ESP_BASE.psc"

remove_from() {
  local root="$1"
  rm -f "$root/$ESP_BASE.esp" "$root/Seq/$ESP_BASE.seq" "$root/Scripts/$ESP_BASE.pex" \
    "$root/Scripts/Source/$ESP_BASE.psc" "$root/$CATALOG_REL/$PLUGIN_ID.json"
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
  "$COMPILER" "$ESP_BASE.psc" -f="$FLAGS" -i="$IMPORTS" -o="$(cygpath -w "$DIST/Scripts")" -op
)
if [[ ! -f "$DIST/Scripts/$ESP_BASE.pex" ]]; then
  echo "Compile produced no $ESP_BASE.pex" >&2
  exit 1
fi
for pex in "$DIST/Scripts/"*.pex; do
  if [[ "$(basename "$pex")" != "$ESP_BASE.pex" ]]; then
    echo "Removing $(basename "$pex") from dist. Only $ESP_BASE.pex ships; MTF and stub scripts must not be overwritten."
    rm -f "$pex"
  fi
done

echo "=== generating $ESP_BASE.esp ==="
(
  export MSYS_NO_PATHCONV=1
  dotnet run --project "$(cygpath -w "$REPO_ROOT/shared/tools/PluginGen/PluginGen.csproj")" -- \
    --out "$(cygpath -w "$DIST/$ESP_BASE.esp")" --script "$ESP_BASE" --name "$MOD_NAME" \
    --author "$AUTHOR" --description "$DESCRIPTION"
)

# The mod exactly as it ships, laid out as it sits in Data. Staging, live, and the zip all use this folder.
MODROOT="$DIST/mod"
mkdir -p "$MODROOT/Scripts/Source" "$MODROOT/Seq" "$MODROOT/$CATALOG_REL"
cp -f "$DIST/$ESP_BASE.esp" "$MODROOT/"
cp -f "$DIST/Seq/$ESP_BASE.seq" "$MODROOT/Seq/"
cp -f "$DIST/Scripts/$ESP_BASE.pex" "$MODROOT/Scripts/"
cp -f "$SCRIPT_SRC" "$MODROOT/Scripts/Source/"
cp -f "$CATALOG" "$MODROOT/$CATALOG_REL/"

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
    ;;
  live)
    if ! cp -rf "$MODROOT/." "$DATA/"; then
      echo "Couldn't copy everything into $DATA. Skyrim locks loaded plugins while it runs; quit the game and run this again." >&2
      exit 1
    fi
    echo "Copied $VERSION into $DATA"
    echo "Restart Skyrim."
    if [[ -d "$STAGING" ]]; then
      echo "Warning: a Vortex mod for this connector is staged at $STAGING. Disable it, or run uninstall-staging, so a deploy does not replace these files." >&2
    fi
    ;;
  package)
    ZIP="$DIST/$ESP_BASE-$VERSION.zip"
    # Windows bsdtar, not Git Bash's GNU tar, which cannot write zips. Compress-Archive in Windows PowerShell writes backslash paths.
    "$(cygpath -u "$SYSTEMROOT")/System32/tar.exe" -a -cf "$(cygpath -w "$ZIP")" -C "$(cygpath -w "$MODROOT")" "$ESP_BASE.esp" Scripts Seq SKSE
    echo "Packaged $VERSION at $ZIP"
    ;;
esac
