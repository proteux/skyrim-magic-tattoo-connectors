Scriptname MagicEffect extends Form Hidden
{Compile-only stub. Never shipped; the game has the real script.}

; SKSE
string Function GetAssociatedSkill() native

bool Function IsEffectFlagSet(int flag) native

; Constant Effect 0, Fire And Forget 1, Concentration 2
int Function GetCastingType() native

; Self 0, Contact 1, Aimed 2, Target Actor 3, Target Location 4
int Function GetDeliveryType() native
