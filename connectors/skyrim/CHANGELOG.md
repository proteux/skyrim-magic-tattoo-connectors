# Changelog

## 0.2.1

- Fixed effects never applying again after the plugin was disabled for a session and then re-enabled. Changes left from then are undone on the next load, and tiers still showing apply again.
- Fixed no effects or conditions working at all in a save that went through an uninstall and reinstall: MTF kept calling a leftover copy of the plugin that did nothing. The plugin takes that copy's place on the next load.
- New console reset that undoes every change from Shout recovery, Rested bonus, Facial mood, Night vision, No fall damage, and Magic aura: `setpqv MTF_Plugin_Skyrim ResetOnLoad 1`, then save and load.

## 0.2.0

- New effect, Magic aura: while shown, the actor wears one of 80 visual effects from Skyrim, Dawnguard, and Dragonborn that MTF's own Shader effect doesn't offer, such as Oakflesh, enchanted glows, Ice Form, Nightingale shadow, Mistform, and Dragon Aspect. It comes back after a load.

## 0.1.0

- First release: 18 conditions (Statistic, Moon phase, In darkness, Season, Holiday, Bounty in this hold, Wanted anywhere, Hidden, Sitting, Sleeping, At a crafting station, Diseased, Just made a kill, Just leveled up, Spell in hand, Just cast a spell, Spell school in hand, Just cast from a spell school) and 9 effects (Night vision, Shout recovery, Cure disease, Rested bonus, Facial mood, Calm enemies, No fall damage, Change the weather, Grant experience).
