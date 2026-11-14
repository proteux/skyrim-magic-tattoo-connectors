Scriptname MTF_MainQuest extends Quest Hidden
{Compile-only stub. Never shipped; Magic Tattoos Framework has the real script.
 Only the members that MTF_Plugin.psc and connector plugins call, with the signatures from
 vendor/magic-tattoos-framework/source/scripts/MTF_MainQuest.psc. The real one imports far more
 than connectors need to compile against.}

Form[] Property registeredPlugins Auto
Function RegisterPlugin(MTF_Plugin p)
EndFunction

int Function FindPluginIndex(string pid)
    return -1
EndFunction

MTF_Plugin Function FindPlugin(string pid)
    return None
EndFunction

int Function GetTrackedCount()
    return 0
EndFunction

Actor Function GetTrackedAt(int idx)
    return None
EndFunction

int Function _condIdxFor(MTF_Plugin p, string itemId)
    return -1
EndFunction

int Function _effectIdxFor(MTF_Plugin p, string itemId)
    return -1
EndFunction

int Function GetEvalParam2()
    return 0
EndFunction

int Function GetEvalParam3()
    return 0
EndFunction

string Function GetEvalParamStr()
    return ""
EndFunction

string Function GetEvalParam2Str()
    return ""
EndFunction

string Function GetEvalParam3Str()
    return ""
EndFunction

int Function _getDispatchSlot()
    return -1
EndFunction

int Function _getDispatchEffectIdx()
    return -1
EndFunction

int Function _getDispatchBaseSlot()
    return -1
EndFunction

int Function _getDispatchArea()
    return 0
EndFunction

bool Function _getDispatchUseScratch()
    return false
EndFunction

int Function GetSlotEffectParamNEx(int slot, int effectIdx, int n, bool useScratch)
    return 0
EndFunction

int Function GetSlotEffectParamNExForPreset(int slot, int effectIdx, int n, bool useScratch, string presetName)
    return 0
EndFunction

string Function GetSlotEffectParamNStrExForPreset(int slot, int effectIdx, int n, bool useScratch, string presetName)
    return ""
EndFunction
