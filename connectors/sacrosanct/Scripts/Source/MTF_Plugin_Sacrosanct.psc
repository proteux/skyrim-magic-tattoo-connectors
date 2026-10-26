Scriptname MTF_Plugin_Sacrosanct extends MTF_Plugin
{Magic Tattoos Framework conditions and effects backed by Sacrosanct - Vampires of Skyrim.
 Soft dependency: Sacrosanct is looked up at runtime, and the plugin stays unregistered without it.
 Catalog: SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/proteux-mtf.sacrosanct.json

 Sacrosanct's state belongs to the player, so every condition except vampire and vampire.lord
 is false for other actors, and every effect does nothing on them.}

string Property MOD_VERSION = "0.1.0" AutoReadOnly Hidden
string Property SACROSANCT_ESP = "Sacrosanct - Vampires of Skyrim.esp" AutoReadOnly Hidden
string Property KEY_PREFIX = "proteux-mtf.sacrosanct." AutoReadOnly Hidden

Actor Property PlayerRef Auto Hidden
Keyword Property VampireKeyword Auto Hidden
PlayerVampireQuestScript Property VampireQuest Auto Hidden
DLC1PlayerVampireChangeScript Property LordQuest Auto Hidden
SCS_FUtil_Script Property RankQuest Auto Hidden
GlobalVariable Property RankAge Auto Hidden
GlobalVariable Property RankAgeGainMult Auto Hidden
GlobalVariable Property RankThreshold Auto Hidden
GlobalVariable Property RankThresholdIncrement Auto Hidden
GlobalVariable Property HemomancyStage Auto Hidden
GlobalVariable Property WassailCurrent Auto Hidden
GlobalVariable Property DisableSunDamage Auto Hidden
GlobalVariable Property DisableHate Auto Hidden
GlobalVariable Property DisableTrespassingCurse Auto Hidden

string Function GetPluginId()
    return "proteux-mtf.sacrosanct"
EndFunction

bool Function _resolveDeps()
    if RankAge != None && VampireQuest != None
        return true
    endif
    RankAge = Game.GetFormFromFile(0x133B5E, SACROSANCT_ESP) as GlobalVariable
    if RankAge == None
        return false
    endif
    PlayerRef = Game.GetPlayer()
    VampireKeyword = Game.GetFormFromFile(0x0A82BB, "Skyrim.esm") as Keyword
    LordQuest = Game.GetFormFromFile(0x0071D0, "Dawnguard.esm") as DLC1PlayerVampireChangeScript
    RankQuest = Game.GetFormFromFile(0x133B4D, SACROSANCT_ESP) as SCS_FUtil_Script
    RankAgeGainMult = Game.GetFormFromFile(0x133B64, SACROSANCT_ESP) as GlobalVariable
    RankThreshold = Game.GetFormFromFile(0x133B65, SACROSANCT_ESP) as GlobalVariable
    RankThresholdIncrement = Game.GetFormFromFile(0x133B66, SACROSANCT_ESP) as GlobalVariable
    HemomancyStage = Game.GetFormFromFile(0x059BA1, SACROSANCT_ESP) as GlobalVariable
    WassailCurrent = Game.GetFormFromFile(0x136314, SACROSANCT_ESP) as GlobalVariable
    DisableSunDamage = Game.GetFormFromFile(0x10994B, SACROSANCT_ESP) as GlobalVariable
    DisableHate = Game.GetFormFromFile(0x1071A8, SACROSANCT_ESP) as GlobalVariable
    DisableTrespassingCurse = Game.GetFormFromFile(0x133B72, SACROSANCT_ESP) as GlobalVariable
    ; Set last: it is the "resolved" marker checked above.
    VampireQuest = Game.GetFormFromFile(0x0EAFD5, "Skyrim.esm") as PlayerVampireQuestScript
    return VampireQuest != None
EndFunction

Function _onRegistered()
    Debug.Trace("[MTF_Plugin_Sacrosanct] " + MOD_VERSION + " registered as " + GetPluginId())
EndFunction

; ── Conditions ──────────────────────────────────────────────────────────────

bool Function checkCondition(Actor target, int param, string cid)
    if target == None || VampireQuest == None
        return false
    endif
    if cid == "vampire"
        if target == PlayerRef
            return _isPlayerVampire()
        endif
        return VampireKeyword != None && target.HasKeyword(VampireKeyword)
    elseif cid == "vampire.lord"
        return LordQuest != None && target.GetRace() == LordQuest.VampireLordRace
    endif

    if target != PlayerRef || !_isPlayerVampire()
        return false
    endif
    if cid == "thirst"
        int status = VampireQuest.VampireStatus
        int want = _thirstStage(_host().GetEvalParamStr())
        if status < 1 || status > 4 || want < 1
            return false
        endif
        string match = _host().GetEvalParam2Str()
        if match == "or_worse"
            return status >= want
        elseif match == "or_better"
            return status <= want
        endif
        return status == want
    elseif cid == "fed.recent"
        float hoursSinceFeed = (Utility.GetCurrentGameTime() - VampireQuest.LastFeedTime) * 24.0
        return hoursSinceFeed >= 0.0 && hoursSinceFeed <= param as float
    elseif cid == "rank"
        int want = _rankIndex(_host().GetEvalParamStr())
        return want >= 0 && _ranksGained() >= want
    elseif cid == "rank.progress"
        if RankThreshold == None || RankThreshold.GetValue() <= 0.0
            return false
        endif
        return RankAge.GetValue() * 100.0 / RankThreshold.GetValue() >= param as float
    elseif cid == "hemomancy"
        return HemomancyStage != None && HemomancyStage.GetValue() >= param as float
    elseif cid == "wassail"
        return WassailCurrent != None && WassailCurrent.GetValue() >= param as float
    elseif cid == "lord.perks"
        return LordQuest != None && LordQuest.DLC1VampireTotalPerksEarned.GetValue() >= param as float
    elseif cid == "lord.levitating"
        return LordQuest != None && LordQuest.DCL1VampireLevitateStateGlobal.GetValue() == 2.0
    endif
    return false
EndFunction

bool Function _isPlayerVampire()
    return VampireQuest.PlayerIsVampire != None && VampireQuest.PlayerIsVampire.GetValue() == 1.0
EndFunction

int Function _thirstStage(string stageId) global
    if stageId == "sated"
        return 1
    elseif stageId == "thirsty"
        return 2
    elseif stageId == "parched"
        return 3
    elseif stageId == "starved"
        return 4
    endif
    return -1
EndFunction

int Function _rankIndex(string rankId) global
    if rankId == "fledgeling"
        return 0
    elseif rankId == "blooded"
        return 1
    elseif rankId == "mistwalker"
        return 2
    elseif rankId == "nightstalker"
        return 3
    elseif rankId == "nightlord"
        return 4
    elseif rankId == "nightmaster"
        return 5
    endif
    return -1
EndFunction

int Function _ranksGained()
    ; Sacrosanct raises the threshold by one increment per rank and resets the age to 0,
    ; so the threshold counts ranks: one increment at Fledgeling, two at Blooded, ...
    if RankThreshold == None || RankThresholdIncrement == None || RankThresholdIncrement.GetValue() <= 0.0
        return 0
    endif
    int ranks = Math.Floor(RankThreshold.GetValue() / RankThresholdIncrement.GetValue() + 0.5) - 1
    if ranks < 0
        return 0
    endif
    return ranks
EndFunction

; ── Effects ─────────────────────────────────────────────────────────────────

Function onActivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || target != PlayerRef || VampireQuest == None || !_isPlayerVampire()
        return
    endif
    if eid == "thirst.feed"
        VampireQuest.VampireFeed()
    elseif eid == "thirst.worsen"
        VampireQuest.Devolve(true)
    elseif eid == "age.grant"
        if RankQuest != None
            RankQuest.Age(param as float)
        endif
    elseif eid == "age.rate"
        string rateKey = _instanceKey(eid, slot, effectIdx)
        if RankAgeGainMult == None || StorageUtil.HasFloatValue(target, rateKey)
            return
        endif
        StorageUtil.SetFloatValue(target, rateKey, param as float)
        RankAgeGainMult.Mod(param as float)
    elseif eid == "ward.sun"
        _wardOn(target, eid, slot, effectIdx, DisableSunDamage)
    elseif eid == "ward.hate"
        if _wardOn(target, eid, slot, effectIdx, DisableHate)
            VampireQuest.StopHate(target, true)
        endif
    elseif eid == "ward.trespass"
        _wardOn(target, eid, slot, effectIdx, DisableTrespassingCurse)
    elseif eid == "lord.bloodpoints"
        _grantBloodPoints(param)
    endif
EndFunction

Function onDeactivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    ; Not gated on still being a vampire: a cure while the tier shows must still undo the change.
    if target == None || target != PlayerRef || VampireQuest == None
        return
    endif
    if eid == "age.rate"
        string rateKey = _instanceKey(eid, slot, effectIdx)
        if !StorageUtil.HasFloatValue(target, rateKey)
            return
        endif
        float applied = StorageUtil.GetFloatValue(target, rateKey)
        StorageUtil.UnsetFloatValue(target, rateKey)
        if RankAgeGainMult != None
            RankAgeGainMult.Mod(-applied)
        endif
    elseif eid == "ward.sun"
        _wardOff(target, eid, slot, effectIdx, DisableSunDamage)
    elseif eid == "ward.hate"
        if _wardOff(target, eid, slot, effectIdx, DisableHate) && _isPlayerVampire() && VampireQuest.VampireStatus == 4
            ; StartHate checks the restored setting and Sacrosanct's own Masquerade reward itself.
            VampireQuest.StartHate(target)
        endif
    elseif eid == "ward.trespass"
        _wardOff(target, eid, slot, effectIdx, DisableTrespassingCurse)
    endif
EndFunction

string Function _instanceKey(string eid, int slot, int effectIdx)
    return KEY_PREFIX + eid + "." + slot + "." + effectIdx
EndFunction

; A ward holds one of Sacrosanct's "disable" settings at 1 while any tier with it is showing.
; The count and the player's own setting live in global StorageUtil values, so overlapping
; tiers share one change and the player's MCM choice comes back when the last one ends.
; Returns true when this call switched the ward on.
bool Function _wardOn(Actor target, string eid, int slot, int effectIdx, GlobalVariable setting)
    string instKey = _instanceKey(eid, slot, effectIdx)
    if setting == None || StorageUtil.HasIntValue(target, instKey)
        return false
    endif
    StorageUtil.SetIntValue(target, instKey, 1)
    string countKey = KEY_PREFIX + eid + ".count"
    int count = StorageUtil.AdjustIntValue(None, countKey, 1)
    if count != 1
        return false
    endif
    StorageUtil.SetFloatValue(None, KEY_PREFIX + eid + ".prev", setting.GetValue())
    setting.SetValue(1.0)
    return true
EndFunction

; Returns true when this call restored the player's setting.
bool Function _wardOff(Actor target, string eid, int slot, int effectIdx, GlobalVariable setting)
    string instKey = _instanceKey(eid, slot, effectIdx)
    if !StorageUtil.HasIntValue(target, instKey)
        return false
    endif
    StorageUtil.UnsetIntValue(target, instKey)
    string countKey = KEY_PREFIX + eid + ".count"
    int count = StorageUtil.AdjustIntValue(None, countKey, -1)
    if count > 0
        return false
    endif
    StorageUtil.UnsetIntValue(None, countKey)
    string prevKey = KEY_PREFIX + eid + ".prev"
    float prev = StorageUtil.GetFloatValue(None, prevKey, 0.0)
    StorageUtil.UnsetFloatValue(None, prevKey)
    if setting != None
        setting.SetValue(prev)
    endif
    return true
EndFunction

; Same award rules as Dawnguard's bite and drain scripts, applied once per point.
Function _grantBloodPoints(int points)
    if LordQuest == None
        return
    endif
    GlobalVariable bloodPoints = LordQuest.DLC1VampireBloodPoints
    GlobalVariable nextPerk = LordQuest.DLC1VampireNextPerk
    GlobalVariable perkPoints = LordQuest.DLC1VampirePerkPoints
    GlobalVariable totalEarned = LordQuest.DLC1VampireTotalPerksEarned
    GlobalVariable maxPerks = LordQuest.DLC1VampireMaxPerks
    if bloodPoints == None || nextPerk == None || perkPoints == None || totalEarned == None || maxPerks == None
        return
    endif
    int i = 0
    while i < points
        bloodPoints.Mod(1.0)
        if totalEarned.GetValue() < maxPerks.GetValue() && bloodPoints.GetValue() >= nextPerk.GetValue()
            bloodPoints.Mod(-nextPerk.GetValue())
            perkPoints.Mod(1.0)
            totalEarned.Mod(1.0)
            nextPerk.Mod(1.0)
        endif
        i += 1
    endwhile
    if nextPerk.GetValue() > 0.0
        PlayerRef.SetActorValue("VampirePerks", bloodPoints.GetValue() / nextPerk.GetValue() * 100.0)
    endif
EndFunction
