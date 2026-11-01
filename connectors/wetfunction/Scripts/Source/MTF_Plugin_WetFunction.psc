; Copyright (C) 2026 Jack Whitehouse (proteux). Licensed under the GNU General Public License v3.0 or later; see LICENSE.
Scriptname MTF_Plugin_WetFunction extends MTF_Plugin
{Magic Tattoos Framework conditions and effects backed by Wet Function Redux SE.
 Soft dependency: Wet Function Redux is looked up at runtime, and the plugin stays unregistered without it.
 Catalog: SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/proteux-mtf.wetfunction.json

 Wet Function Redux keeps each actor's state in StorageUtil floats on the actor (WetFunction_Actor_*)
 and its settings in StorageUtil floats on its MCM quest. This plugin reads and writes those values
 directly, so it works with the original scripts and with patches that replace them, such as OSweat.}

string Property MOD_VERSION = "0.1.0" AutoReadOnly Hidden
string Property WFR_ESP = "WetFunction.esp" AutoReadOnly Hidden
string Property ACTOR_PREFIX = "WetFunction_Actor_" AutoReadOnly Hidden
string Property KEY_PREFIX = "proteux-mtf.wetfunction." AutoReadOnly Hidden

Actor Property PlayerRef Auto Hidden
Quest Property WfrConfig Auto Hidden

string Function GetPluginId()
    return "proteux-mtf.wetfunction"
EndFunction

bool Function _resolveDeps()
    if WfrConfig != None
        return true
    endif
    PlayerRef = Game.GetPlayer()
    ; Set last: it is the "resolved" marker checked above.
    WfrConfig = Game.GetFormFromFile(0x000800, WFR_ESP) as Quest
    return WfrConfig != None
EndFunction

Function _onRegistered()
    Debug.Trace("[MTF_Plugin_WetFunction] " + MOD_VERSION + " registered as " + GetPluginId())
EndFunction

; ── Conditions ──────────────────────────────────────────────────────────────

bool Function checkCondition(Actor target, int param, string cid)
    if target == None || WfrConfig == None
        return false
    endif
    if cid == "active"
        return _hasActor(target, "wetnessRate") && _hasActor(target, "specular")
    elseif cid == "trend"
        if !_hasActor(target, "wetnessRate")
            return false
        endif
        float rate = _getActor(target, "wetnessRate")
        string trend = _host().GetEvalParamStr()
        if trend == "wetter"
            return rate > 0.0
        elseif trend == "drying"
            return rate < 0.0
        endif
        return false
    endif

    ; An actor Wet Function Redux has never run on has no wetness at all, not a dry skin.
    if !_hasActor(target, "wetness")
        return false
    endif
    float wetness = _getActor(target, "wetness")
    if cid == "wetness"
        float cap = _cap()
        return cap > 0.0 && wetness * 100.0 / cap >= param as float
    elseif cid == "stage"
        int want = _stageIndex(_host().GetEvalParamStr())
        if want < 0
            return false
        endif
        int stage = _stageOf(wetness)
        string match = _host().GetEvalParam2Str()
        if match == "or_wetter"
            return stage >= want
        elseif match == "or_drier"
            return stage <= want
        endif
        return stage == want
    endif
    return false
EndFunction

; Same thresholds Wet Function Redux uses to pick its textures, without its drying hysteresis.
int Function _stageOf(float wetness)
    if wetness > _cfg("wetnessSoaked")
        return 2
    elseif wetness > _cfg("wetnessStart")
        return 1
    endif
    return 0
EndFunction

int Function _stageIndex(string stageId) global
    if stageId == "dry"
        return 0
    elseif stageId == "sweaty"
        return 1
    elseif stageId == "soaked"
        return 2
    endif
    return -1
EndFunction

; ── Effects ─────────────────────────────────────────────────────────────────

Function onActivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || WfrConfig == None
        return
    endif
    if eid == "wet.add"
        _bumpWetness(target, param as float)
    elseif eid == "wet.remove"
        _bumpWetness(target, -(param as float))
    elseif eid == "rate.global"
        string rateKey = _instanceKey(eid, slot, effectIdx)
        if target != PlayerRef || param <= 0 || StorageUtil.HasFloatValue(target, rateKey)
            return
        endif
        float factor = param as float / 100.0
        StorageUtil.SetFloatValue(target, rateKey, factor)
        _setCfg("multGlobal", _cfg("multGlobal") * factor)
    endif
EndFunction

Function onDeactivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || WfrConfig == None
        return
    endif
    if eid == "rate.global"
        string rateKey = _instanceKey(eid, slot, effectIdx)
        if !StorageUtil.HasFloatValue(target, rateKey)
            return
        endif
        float factor = StorageUtil.GetFloatValue(target, rateKey)
        StorageUtil.UnsetFloatValue(target, rateKey)
        if factor > 0.0
            _setCfg("multGlobal", _cfg("multGlobal") / factor)
        endif
    endif
EndFunction

; Like Wet Function Redux's own BumpWetness: only actors it tracks, clamped to 0 and its cap.
Function _bumpWetness(Actor target, float percentOfCap)
    if !_hasActor(target, "wetness")
        return
    endif
    float cap = _cap()
    if cap <= 0.0
        return
    endif
    float wetness = _getActor(target, "wetness") + cap * percentOfCap / 100.0
    if wetness < 0.0
        wetness = 0.0
    elseif wetness > cap
        wetness = cap
    endif
    StorageUtil.SetFloatValue(target, ACTOR_PREFIX + "wetness", wetness)
EndFunction

; ── Wet Function Redux storage ──────────────────────────────────────────────

bool Function _hasActor(Actor target, string storeKey)
    return StorageUtil.HasFloatValue(target, ACTOR_PREFIX + storeKey)
EndFunction

float Function _getActor(Actor target, string storeKey)
    return StorageUtil.GetFloatValue(target, ACTOR_PREFIX + storeKey)
EndFunction

float Function _cfg(string storeKey)
    return StorageUtil.GetFloatValue(WfrConfig, storeKey)
EndFunction

Function _setCfg(string storeKey, float value)
    StorageUtil.SetFloatValue(WfrConfig, storeKey, value)
EndFunction

float Function _cap()
    return _cfg("wetnessCap")
EndFunction

string Function _instanceKey(string eid, int slot, int effectIdx)
    return KEY_PREFIX + eid + "." + slot + "." + effectIdx
EndFunction
