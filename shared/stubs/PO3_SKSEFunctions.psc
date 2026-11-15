Scriptname PO3_SKSEFunctions Hidden
{Compile-only stub. Never shipped; powerofthree's Papyrus Extender provides the real script.}

Actor[] Function GetActorsByProcessingLevel(int aiLevel) global native

; FormType 62 = Actor (Character). Finds loaded refs of that type within afRadius of akRef.
ObjectReference[] Function FindAllReferencesOfFormType(ObjectReference akRef, int formType, float afRadius) global native

int Function GetSpellType(Spell akSpell) global native

Function SetHairColor(Actor akActor, ColorForm akColor) global native
