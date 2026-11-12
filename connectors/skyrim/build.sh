#!/usr/bin/env bash
# Build the base game connector. Usage: build.sh [live|staging|package|uninstall-live|uninstall-staging], default live
# See shared/build-common.sh for the steps and the environment overrides.
set -euo pipefail

CONNECTOR_DIR="$(cd "$(dirname "$0")" && pwd)"
ESP_BASE="MTF_Plugin_Skyrim"
PLUGIN_ID="proteux-mtf.skyrim"
MOD_NAME="MTF Plugin - Skyrim"
AUTHOR="Proteux"
DESCRIPTION="More Magic Tattoos Framework conditions and effects for the base game: stats, moon and calendar, crime and stealth, what the actor is doing, spells and spell schools in hand and just cast, plus night vision, shout recovery, rested bonuses, moods, calm, weather, experience, and magic auras."
ALIAS_SCRIPTS="MTF_Plugin_Skyrim_Load"

source "$CONNECTOR_DIR/../../shared/build-common.sh" "$@"
