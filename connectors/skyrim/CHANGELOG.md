# Changelog

## 0.3.3

- Spell aura now treats faction enemies as enemies even when they aren't in combat. `IsHostileToActor` alone skipped Unaggressive targets such as Enemy training dummies and calmed bandits; harmful auras also use `GetFactionReaction == Enemy`, and helpful auras skip those same targets.

## 0.3.2

- Cast a spell repeats on the wearer while the tier is shown: fire-and-forget spells at their cast time (at least 0.5 s), concentration every second. Self buffs such as Oakflesh still land once.
- Spell aura fire-and-forget hits (Firebolt, Ice Spike) use half strength when Magic Tattoos UI 1.8.6 or later is present; concentration auras stay at full strength per second.

## 0.3.1

- Cast a spell and Spell aura hit as hard as the applier casting the spell themselves, counting their perks (such as Augmented Flames) and Fortify (School) potions, so a Magic Tattoos Tactical hex with Firebolt does a real Firebolt's damage. This needs Magic Tattoos UI 1.8.3 or later; without it, spells land as before.

## 0.3.0

- New effect, Cast a spell: when the tier shows, any spell from the game or another mod lands on the actor once, free or paid for with their magicka.
- New effect, Spell aura: while shown, a spell lands every second on actors within 1 to 50 metres. A harmful spell such as Flames hits the actor's enemies; a helpful one such as Healing reaches the actor and their side. It needs Papyrus Extender for anyone but the actor and the player.
- Both credit whoever applied the tattoo, read from the shared `mtf.applier.<preset>` key that Magic Tattoos Tactical sets, so a hex's damage and kill credit go to the caster. Without it, the wearer counts as the applier.
- Magic Tattoos UI 1.8.0 picks the spell from a searchable list. In MTF's own menu, type `Plugin.esp|0xFormID` or the name of a spell the player knows.

## 0.2.1

- Fixed effects never applying again after the plugin was disabled for a session and then re-enabled. Changes left from then are undone on the next load, and tiers still showing apply again.
- Fixed no effects or conditions working at all in a save that went through an uninstall and reinstall: MTF kept calling a leftover copy of the plugin that did nothing. The plugin takes that copy's place on the next load.
- New console reset that undoes every change from Shout recovery, Rested bonus, Facial mood, Night vision, No fall damage, and Magic aura: `setpqv MTF_Plugin_Skyrim ResetOnLoad 1`, then save and load.

## 0.2.0

- New effect, Magic aura: while shown, the actor wears one of 80 visual effects from Skyrim, Dawnguard, and Dragonborn that MTF's own Shader effect doesn't offer, such as Oakflesh, enchanted glows, Ice Form, Nightingale shadow, Mistform, and Dragon Aspect. It comes back after a load.

## 0.1.0

- First release: 18 conditions (Statistic, Moon phase, In darkness, Season, Holiday, Bounty in this hold, Wanted anywhere, Hidden, Sitting, Sleeping, At a crafting station, Diseased, Just made a kill, Just leveled up, Spell in hand, Just cast a spell, Spell school in hand, Just cast from a spell school) and 9 effects (Night vision, Shout recovery, Cure disease, Rested bonus, Facial mood, Calm enemies, No fall damage, Change the weather, Grant experience).
