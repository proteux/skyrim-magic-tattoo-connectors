# Changelog

## 0.3.15

- Allies nearby no longer counts bleeding-out actors (essential knockdown). Enemy training dummies stay "alive" for IsDead when downed, so a lone hexed dummy kept matching its knocked-out packmate.

## 0.3.14

- Allies nearby also matches actors that share any faction with the wearer. GetFactionReaction alone stayed Neutral for packs such as Enemy training dummies that share a faction, so the condition never fired next to their friends.

## 0.3.13

- Cast a spell and Cast an aura pause while the wearer is bleeding out (essential / protected knockdown), and resume when they stand up. Aura neighbours who are bleeding out are skipped too, same as dead targets.

## 0.3.12

- Added Allies nearby: true while at least one living Ally or Friend of the actor (faction reaction) is within the radius. Dead actors do not count. Needs Papyrus Extender for the radius scan.

## 0.3.11

- When Cast a spell or Cast an aura pays magicka and an applier is recorded (for example a Magic Tattoos Tactical hex or blessing), only that applier is charged. If they are dead or out of magicka, the pulse pauses; the wearer's magicka is never used as a fallback. With no applier recorded, the wearer still pays.

## 0.3.10

- Cast an aura no longer hits the wearer for helpful spells. Helpful and harmful both reach only nearby actors on the wearer's side.

## 0.3.9

- Cast an aura fire-and-forget uses the same pulse spacing as Cast a spell: the longer of effect duration and cast time (at least 0.5 s). Lasting spells such as Fear no longer flash on the aura ring; instant spells such as Firebolt pulse on cast time at half strength. Concentration still pulses every second.

## 0.3.8

- Renamed the Spell aura effect label to Cast an aura so it sits next to Cast a spell in the menu. The effect id (`spell.aura`) is unchanged, so existing presets keep working.

## 0.3.7

- Cast a spell fire-and-forget repeats at the longer of the spell's effect duration and its cast time (at least 0.5 s), so lasting spells such as Fear are not re-applied while they would still be running. Instant spells such as Firebolt still pulse on cast time. Concentration and Cast an aura are unchanged.
- Cast an aura picks targets from the wearer's side for both helpful and harmful spells: anyone nearby who isn't an enemy of the wearer (faction enemies and hostiles still count). Helpful still hits the wearer; harmful never does. Whoever applied the tattoo still gets the damage, aggro, and kill credit.

## 0.3.6

- When Cast a spell or Cast an aura pays magicka, it charges the applier if one is set and alive (for example the caster of a Magic Tattoos Tactical hex or blessing), otherwise the wearer. Concentration still always pays once per second; the optional pay flag still gates fire-and-forget and self buffs.

## 0.3.5

- Concentration Cast a spell and Cast an aura pulses land about ten seconds of the spell each second (needs Magic Tattoos UI 1.8.6 or later for the scaled hit). The wearer always pays one second of magicka per pulse, even when Magicka is set to Free; when they can't afford it the pulse pauses and resumes when magicka recovers. Fire-and-forget and self buffs are unchanged.

## 0.3.4

- Cast an aura finds neighbours with a radius scan instead of `GetActorsByProcessingLevel(0)`. Pinned or restrained actors such as Enemy training dummies can stand next to the wearer and still be missing from high process, so the old scan returned nobody and the aura never hit them.

## 0.3.3

- Cast an aura now treats faction enemies as enemies even when they aren't in combat. `IsHostileToActor` alone skipped Unaggressive targets such as Enemy training dummies and calmed bandits; harmful auras also use `GetFactionReaction == Enemy`, and helpful auras skip those same targets.

## 0.3.2

- Cast a spell repeats on the wearer while the tier is shown: fire-and-forget spells at their cast time (at least 0.5 s), concentration every second. Self buffs such as Oakflesh still land once.
- Cast an aura fire-and-forget hits (Firebolt, Ice Spike) use half strength when Magic Tattoos UI 1.8.6 or later is present; concentration auras stay at full strength per second.

## 0.3.1

- Cast a spell and Cast an aura hit as hard as the applier casting the spell themselves, counting their perks (such as Augmented Flames) and Fortify (School) potions, so a Magic Tattoos Tactical hex with Firebolt does a real Firebolt's damage. This needs Magic Tattoos UI 1.8.3 or later; without it, spells land as before.

## 0.3.0

- New effect, Cast a spell: when the tier shows, any spell from the game or another mod lands on the actor once, free or paid for with their magicka.
- New effect, Cast an aura: while shown, a spell lands every second on actors within 1 to 50 metres. A harmful spell such as Flames hits the actor's enemies; a helpful one such as Healing reaches the actor and their side. It needs Papyrus Extender for anyone but the actor and the player.
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
