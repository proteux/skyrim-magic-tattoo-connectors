# Changelog

## 0.2.0

- New Hair color effect: tints the actor's hair any color while a tier shows, with a gradual transition. Their own color comes back when the tier stops, and the console reset undoes it too. Works on KS Hairdos SMP wigs, and puts the color back if a wig is re-equipped or hair physics reset it.
- New Hair color (any wig) effect: the same tint through powerofthree's Papyrus Extender, which reaches every part drawn as hair, so it works on any wig. Needs powerofthree's Papyrus Extender.
- Log lines name the player instead of leaving the name blank.
- Fixed effects never applying again after the plugin was disabled for a session and then re-enabled. Changes left from then are undone on the next load, and tiers still showing apply again. The console reset now also reaches every NPC MTF tracks.
- Fixed no effects applying at all in a save that went through an uninstall and reinstall: MTF kept calling a leftover copy of the plugin that did nothing. The plugin takes that copy's place on the next load.

## 0.1.0

- First release: the Actor scale effect, and the Body shape effect with 23 CBBE 3BA and TNG shapes, both with gradual transitions, and a console reset that undoes every change on the next load.
