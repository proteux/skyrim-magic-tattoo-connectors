Scriptname MTF_Plugin_RaceMenu extends MTF_Plugin
{Magic Tattoos Framework effects backed by RaceMenu: actor scale and BodySlide body shapes.
 Soft dependency: RaceMenu's skee plugin is checked at runtime, and the plugin stays unregistered without it.
 Catalog: SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/proteux-mtf.racemenu.json

 Everything goes through NiOverride under this plugin's own key, so it adds to RaceMenu's sliders, OBody
 presets, and other mods instead of overwriting them, and clearing the key undoes only this plugin's part.
 RaceMenu saves node transforms and body morphs in its co-save, so nothing needs replaying after a load.}

string Property MOD_VERSION = "0.1.0" AutoReadOnly Hidden
string Property KEY_PREFIX = "proteux-mtf.racemenu." AutoReadOnly Hidden
string Property NI_KEY = "proteux-mtf.racemenu" AutoReadOnly Hidden

Actor Property PlayerRef Auto Hidden

string Function GetPluginId()
    return "proteux-mtf.racemenu"
EndFunction

bool Function _resolveDeps()
    if PlayerRef != None
        return true
    endif
    if SKSE.GetPluginVersion("skee") <= 0
        return false
    endif
    ; Set last: it is the "resolved" marker checked above.
    PlayerRef = Game.GetPlayer()
    return true
EndFunction

Function _onRegistered()
    Debug.Trace("[MTF_Plugin_RaceMenu] " + MOD_VERSION + " registered as " + GetPluginId())
EndFunction

; ── Effects ─────────────────────────────────────────────────────────────────

Function onActivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None
        return
    endif
    string instKey = _instanceKey(eid, slot, effectIdx)
    if eid == "scale"
        if param <= 0 || StorageUtil.HasFloatValue(target, instKey)
            return
        endif
        StorageUtil.SetFloatValue(target, instKey, param as float / 100.0)
        StorageUtil.StringListAdd(target, KEY_PREFIX + "scale.instances", instKey, false)
        _applyScale(target)
    elseif eid == "shape"
        int shape = _shapeIndex(_paramNStrEx(slot, effectIdx, useScratch, presetName, 1))
        if shape < 0 || param2 <= 0 || StorageUtil.HasIntValue(target, instKey)
            return
        endif
        StorageUtil.SetIntValue(target, instKey, shape * 1000 + _clampInt(param2, 0, 100))
        StorageUtil.StringListAdd(target, KEY_PREFIX + "shape.instances", instKey, false)
        _applyShapes(target)
    endif
EndFunction

Function onDeactivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None
        return
    endif
    string instKey = _instanceKey(eid, slot, effectIdx)
    if eid == "scale"
        if !StorageUtil.HasFloatValue(target, instKey)
            return
        endif
        StorageUtil.UnsetFloatValue(target, instKey)
        StorageUtil.StringListRemove(target, KEY_PREFIX + "scale.instances", instKey, true)
        _applyScale(target)
    elseif eid == "shape"
        if !StorageUtil.HasIntValue(target, instKey)
            return
        endif
        StorageUtil.UnsetIntValue(target, instKey)
        StorageUtil.StringListRemove(target, KEY_PREFIX + "shape.instances", instKey, true)
        _applyShapes(target)
    endif
EndFunction

; ── Scale ───────────────────────────────────────────────────────────────────

; A keyed scale on the root "NPC" node, which multiplies with RaceMenu's own height. Stacked instances multiply.
Function _applyScale(Actor target)
    string listKey = KEY_PREFIX + "scale.instances"
    int n = StorageUtil.StringListCount(target, listKey)
    float factor = 1.0
    int i = 0
    while i < n
        factor *= StorageUtil.GetFloatValue(target, StorageUtil.StringListGet(target, listKey, i), 1.0)
        i += 1
    endwhile
    bool isFemale = _isFemale(target)
    _setNodeScale(target, false, isFemale, n > 0, factor)
    if target == PlayerRef
        _setNodeScale(target, true, isFemale, n > 0, factor)
    endif
EndFunction

Function _setNodeScale(Actor target, bool firstPerson, bool isFemale, bool apply, float factor)
    if apply
        NiOverride.AddNodeTransformScale(target, firstPerson, isFemale, "NPC", NI_KEY, factor)
    else
        NiOverride.RemoveNodeTransformScale(target, firstPerson, isFemale, "NPC", NI_KEY)
    endif
    NiOverride.UpdateNodeTransform(target, firstPerson, isFemale, "NPC")
EndFunction

bool Function _isFemale(Actor target)
    ActorBase base = target.GetLeveledActorBase()
    return base != None && base.GetSex() == 1
EndFunction

; ── Body shapes ─────────────────────────────────────────────────────────────

; Each slider gets the strongest value any shown instance asks for, so stacked tiers don't add up past
; what one tier at full strength would do. Morph values are slider fractions: 1.0 is 100 in BodySlide.
Function _applyShapes(Actor target)
    string listKey = KEY_PREFIX + "shape.instances"
    int n = StorageUtil.StringListCount(target, listKey)
    string[] sliders = _sliderNames()
    float[] values = Utility.CreateFloatArray(sliders.Length)
    int i = 0
    while i < n
        int packed = StorageUtil.GetIntValue(target, StorageUtil.StringListGet(target, listKey, i))
        int shape = packed / 1000
        float strength = (packed % 1000) as float / 100.0
        int s = 0
        while s < sliders.Length
            float value = _shapeWeight(shape, sliders[s]) * strength
            if value > values[s]
                values[s] = value
            endif
            s += 1
        endwhile
        i += 1
    endwhile
    string applied = ""
    i = 0
    while i < sliders.Length
        if values[i] > 0.0
            NiOverride.SetBodyMorph(target, sliders[i], NI_KEY, values[i])
            applied += " " + sliders[i] + "=" + values[i]
        else
            NiOverride.ClearBodyMorph(target, sliders[i], NI_KEY)
        endif
        i += 1
    endwhile
    NiOverride.UpdateModelWeight(target)
    if applied == ""
        applied = " none"
    endif
    Debug.Trace("[MTF_Plugin_RaceMenu] body morphs on " + target.GetName() + ":" + applied)
EndFunction

; Every CBBE 3BA slider any shape in _shapeWeight uses. A slider missing here is never set.
string[] Function _sliderNames() global
    string[] names = new string[36]
    names[0] = "MuscleAbs"
    names[1] = "MuscleArms"
    names[2] = "MuscleBack_v2"
    names[3] = "MuscleButt"
    names[4] = "MuscleLegs"
    names[5] = "MusclePecs"
    names[6] = "MuscleMoreAbs_v2"
    names[7] = "MuscleMoreArms_v2"
    names[8] = "MuscleMoreLegs_v2"
    names[9] = "Breasts"
    names[10] = "BreastsSmall"
    names[11] = "BreastPerkiness"
    names[12] = "PushUp"
    names[13] = "BreastGravity2"
    names[14] = "Butt"
    names[15] = "BigButt"
    names[16] = "ButtSmall"
    names[17] = "RoundAss"
    names[18] = "AppleCheeks"
    names[19] = "Hips"
    names[20] = "HipUpperWidth"
    names[21] = "Thighs"
    names[22] = "ThighFBThicc_v2"
    names[23] = "ThighOutsideThicc_v2"
    names[24] = "SlimThighs"
    names[25] = "LegsThin"
    names[26] = "ButtNarrow_v2"
    names[27] = "ChubbyArms"
    names[28] = "ChubbyButt"
    names[29] = "ChubbyLegs"
    names[30] = "ChubbyWaist"
    names[31] = "BigBelly"
    names[32] = "PregnancyBelly"
    names[33] = "NipplePerkiness"
    names[34] = "ButtSaggy_v2"
    names[35] = "ButtUnderFold"
    return names
EndFunction

; Indexes match _shapeWeight.
int Function _shapeIndex(string shapeId) global
    if shapeId == "muscular"
        return 0
    elseif shapeId == "bust"
        return 1
    elseif shapeId == "bust_small"
        return 2
    elseif shapeId == "bust_perky"
        return 3
    elseif shapeId == "bust_saggy"
        return 4
    elseif shapeId == "butt_big"
        return 5
    elseif shapeId == "butt_small"
        return 6
    elseif shapeId == "butt_round"
        return 7
    elseif shapeId == "hips_wide"
        return 8
    elseif shapeId == "thighs_thick"
        return 9
    elseif shapeId == "slender"
        return 10
    elseif shapeId == "chubby"
        return 11
    elseif shapeId == "pregnant"
        return 12
    elseif shapeId == "nipples_perky"
        return 13
    elseif shapeId == "older"
        return 14
    elseif shapeId == "younger"
        return 15
    endif
    return -1
EndFunction

; How far a shape at full strength moves a slider: 1.0 is 100 in BodySlide. Papyrus string
; comparison ignores case.
float Function _shapeWeight(int shape, string slider) global
    if shape == 0 ; muscular
        if slider == "MuscleAbs" || slider == "MuscleArms" || slider == "MuscleBack_v2" || slider == "MuscleButt" || slider == "MuscleLegs" || slider == "MusclePecs"
            return 1.0
        elseif slider == "MuscleMoreAbs_v2" || slider == "MuscleMoreArms_v2" || slider == "MuscleMoreLegs_v2"
            return 0.5
        endif
    elseif shape == 1 ; bust
        if slider == "Breasts"
            return 1.0
        endif
    elseif shape == 2 ; bust_small
        if slider == "BreastsSmall"
            return 1.0
        endif
    elseif shape == 3 ; bust_perky
        if slider == "BreastPerkiness"
            return 1.0
        elseif slider == "PushUp"
            return 0.5
        endif
    elseif shape == 4 ; bust_saggy
        if slider == "BreastGravity2"
            return 1.0
        endif
    elseif shape == 5 ; butt_big
        if slider == "Butt"
            return 1.0
        elseif slider == "BigButt"
            return 0.5
        endif
    elseif shape == 6 ; butt_small
        if slider == "ButtSmall"
            return 1.0
        endif
    elseif shape == 7 ; butt_round
        if slider == "RoundAss"
            return 1.0
        elseif slider == "AppleCheeks"
            return 0.5
        endif
    elseif shape == 8 ; hips_wide
        if slider == "Hips"
            return 1.0
        elseif slider == "HipUpperWidth"
            return 0.5
        endif
    elseif shape == 9 ; thighs_thick
        if slider == "Thighs"
            return 1.0
        elseif slider == "ThighFBThicc_v2" || slider == "ThighOutsideThicc_v2"
            return 0.5
        endif
    elseif shape == 10 ; slender
        if slider == "SlimThighs"
            return 1.0
        elseif slider == "LegsThin" || slider == "ButtNarrow_v2"
            return 0.5
        endif
    elseif shape == 11 ; chubby
        if slider == "ChubbyArms" || slider == "ChubbyButt" || slider == "ChubbyLegs" || slider == "ChubbyWaist"
            return 1.0
        elseif slider == "BigBelly"
            return 0.5
        endif
    elseif shape == 12 ; pregnant
        if slider == "PregnancyBelly"
            return 1.0
        endif
    elseif shape == 13 ; nipples_perky
        if slider == "NipplePerkiness"
            return 1.0
        endif
    elseif shape == 14 ; older
        if slider == "BreastGravity2" || slider == "ButtSaggy_v2"
            return 1.0
        elseif slider == "ButtUnderFold"
            return 0.5
        endif
    elseif shape == 15 ; younger
        if slider == "BreastPerkiness"
            return 1.0
        elseif slider == "NipplePerkiness"
            return 0.5
        endif
    endif
    return 0.0
EndFunction

int Function _clampInt(int value, int low, int high) global
    if value < low
        return low
    elseif value > high
        return high
    endif
    return value
EndFunction

string Function _instanceKey(string eid, int slot, int effectIdx)
    return KEY_PREFIX + eid + "." + slot + "." + effectIdx
EndFunction
