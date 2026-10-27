#!/usr/bin/env bash
# Build the Wet Function Redux connector. Usage: build.sh [live|staging|package|uninstall-live|uninstall-staging], default live
# See shared/build-common.sh for the steps and the environment overrides.
set -euo pipefail

CONNECTOR_DIR="$(cd "$(dirname "$0")" && pwd)"
ESP_BASE="MTF_Plugin_WetFunction"
PLUGIN_ID="proteux-mtf.wetfunction"
MOD_NAME="MTF Plugin - Wet Function Redux"
AUTHOR="Proteux"
DESCRIPTION="Magic Tattoos Framework conditions and effects for Wet Function Redux SE: wetness level, stage and trend, plus wetting, drying, and a global wetness rate."

source "$CONNECTOR_DIR/../../shared/build-common.sh" "$@"
