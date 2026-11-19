Scriptname MagicTattoosUI Hidden
{Compile-only stub. Never shipped; Magic Tattoos UI 1.8.3 and later have the real script.
 1.8.4 lands Aimed spells on the target in place instead of firing a projectile from the caster.
 1.8.6 adds CastAsScaled for Spell aura half-strength fire-and-forget hits.
 1.8.14 adds GetSlotPreset / IsSlotPermanent for Magic Tattoos Spellbook.}

Function CastAs(Actor akCaster, Spell akSpell, ObjectReference akTarget) global native
Function CastAsScaled(Actor akCaster, Spell akSpell, ObjectReference akTarget, float afScale) global native
string Function GetSlotPreset(int slot) global native
bool Function IsSlotPermanent(int slot) global native
