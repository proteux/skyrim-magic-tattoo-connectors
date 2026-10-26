# Build Magic Tattoos Framework connectors. Each connector releases as its own mod, named by MOD_NAME in its build.sh.
# make [action...] <connector...>     runs each action, in order, in each named connector; default action is live
# make [action...] all                runs the actions for every connector
# make list                           lists the connectors (also what plain `make` does)
# actions: live staging package uninstall-live uninstall-staging
# Goal order between actions and connectors doesn't matter: make live sacrosanct == make sacrosanct live
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := list

CONNECTORS := $(notdir $(patsubst %/,%,$(wildcard connectors/*/)))
ACTIONS := live staging package uninstall-live uninstall-staging

RESERVED := $(filter all list run $(ACTIONS),$(CONNECTORS))
ifneq ($(RESERVED),)
$(error Connector folder names clash with make goals: $(RESERVED))
endif

SELECTED := $(if $(filter all,$(MAKECMDGOALS)),$(CONNECTORS),$(filter $(CONNECTORS),$(MAKECMDGOALS)))
REQUESTED := $(or $(filter $(ACTIONS),$(MAKECMDGOALS)),live)

.PHONY: list all run $(CONNECTORS) $(ACTIONS)

list:
	@printf '%s\n' $(CONNECTORS)

# Connector and action goals all funnel into one run, so each connector/action pair builds once.
all $(CONNECTORS) $(ACTIONS): run
	@:

run:
	@if [[ -z "$(SELECTED)" ]]; then echo "Name a connector (make list) or 'all', e.g. make $(REQUESTED) sacrosanct" >&2; exit 1; fi
	@for c in $(SELECTED); do for a in $(REQUESTED); do $(MAKE) --no-print-directory -C connectors/$$c $$a; done; done
