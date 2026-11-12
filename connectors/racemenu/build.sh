#!/usr/bin/env bash
# Build the RaceMenu connector. Usage: build.sh [live|staging|package|uninstall-live|uninstall-staging], default live
# See shared/build-common.sh for the steps and the environment overrides.
set -euo pipefail

CONNECTOR_DIR="$(cd "$(dirname "$0")" && pwd)"
ESP_BASE="MTF_Plugin_RaceMenu"
PLUGIN_ID="proteux-mtf.racemenu"
MOD_NAME="MTF Plugin - RaceMenu"
AUTHOR="Proteux"
DESCRIPTION="Magic Tattoos Framework effects backed by RaceMenu: actor scale, BodySlide body shapes, and hair color."
ALIAS_SCRIPTS="MTF_Plugin_RaceMenu_Loop"
# One per actor tinted at once by the Hair color (whole model) effect; see _hairTintForm.
COLOR_FORMS=32

source "$CONNECTOR_DIR/../../shared/build-common.sh" "$@"
