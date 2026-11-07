Scriptname Actor extends ObjectReference Hidden
{Compile-only stub. Never shipped; the game has the real script.}

Race Function GetRace() native

Function SetActorValue(string asValueName, float afValue) native

Function AddPerk(Perk akPerk) native

bool Function AddSpell(Spell akSpell, bool abVerbose=true) native

Function ClearExpressionOverride() native

float Function GetActorValue(string asValueName) native

Actor Function GetCombatTarget() native

Spell Function GetEquippedSpell(int aiSource) native

int Function GetLevel() native

float Function GetLightLevel() native

ActorBase Function GetLeveledActorBase() native

int Function GetSitState() native

int Function GetSleepState() native

bool Function HasPerk(Perk akPerk) native

bool Function HasSpell(Form akForm) native

bool Function IsDead() native

bool Function IsDetectedBy(Actor akOther) native

bool Function IsHostileToActor(Actor akActor) native

bool Function IsPlayerTeammate() native

bool Function IsSneaking() native

Function ModActorValue(string asValueName, float afAmount) native

Function RemovePerk(Perk akPerk) native

bool Function RemoveSpell(Spell akSpell) native

Function SetExpressionOverride(int aiMood, int aiStrength = 100) native

Function StopCombat() native

Function StopCombatAlarm() native

; SKSE
Int Function GetSpellCount() native

Spell Function GetNthSpell(int n) native

ObjectReference Function GetFurnitureReference() native
