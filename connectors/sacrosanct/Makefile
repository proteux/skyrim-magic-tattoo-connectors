# Build the Sacrosanct connector.
# make / make live        copies straight into the Skyrim Data folder (default)
# make staging            builds the Vortex mod "MTF Plugin - Sacrosanct" (replaces its staging folder contents)
# make package            writes dist/MTF_Plugin_Sacrosanct-<version>.zip for Nexus
# make uninstall-live     deletes the connector's files from the Skyrim Data folder
# make uninstall-staging  deletes the Vortex mod's staging folder
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.PHONY: all live staging package uninstall-live uninstall-staging

all: live

live staging package uninstall-live uninstall-staging:
	bash build.sh $@
