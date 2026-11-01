Scriptname MTF_Plugin_RaceMenu extends MTF_Plugin
{Magic Tattoos Framework effects backed by RaceMenu: actor scale and BodySlide body shapes.
 Soft dependency: RaceMenu's skee plugin is checked at runtime, and the plugin stays unregistered without it.
 Catalog: SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/proteux-mtf.racemenu.json

 Everything goes through NiOverride under this plugin's own key, so it adds to RaceMenu's sliders, OBody
 presets, and other mods instead of overwriting them, and clearing the key undoes only this plugin's part.
 RaceMenu saves node transforms and body morphs in its co-save, so nothing needs replaying after a load.

 Changes ease in and out over each instance's Transition seconds. MTF's onTick is too coarse for that, so
 MTF_Plugin_RaceMenu_Loop, on the player alias, calls _step every STEP_SECONDS while any actor is moving.}

string Property MOD_VERSION = "0.1.0" AutoReadOnly Hidden
string Property KEY_PREFIX = "proteux-mtf.racemenu." AutoReadOnly Hidden
string Property NI_KEY = "proteux-mtf.racemenu" AutoReadOnly Hidden
string Property RAMP_LIST = "proteux-mtf.racemenu.moving" AutoReadOnly Hidden
float Property STEP_SECONDS = 0.25 AutoReadOnly Hidden
int Property MAX_TRANSITION = 30 AutoReadOnly Hidden

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

; Real time restarts on load, which would stall or jump a transition saved mid-way, so they all finish
; on the next step instead.
Function _onGameLoaded()
    int i = StorageUtil.FormListCount(self, RAMP_LIST)
    if i <= 0
        return
    endif
    while i > 0
        i -= 1
        Form moving = StorageUtil.FormListGet(self, RAMP_LIST, i)
        if moving != None
            StorageUtil.SetFloatValue(moving, KEY_PREFIX + "shape.ramp.duration", 0.0)
            StorageUtil.SetFloatValue(moving, KEY_PREFIX + "scale.ramp.duration", 0.0)
        endif
    endwhile
    GetAlias(0).RegisterForSingleUpdate(STEP_SECONDS)
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
        float fade = _clampInt(param2, 0, MAX_TRANSITION) as float
        StorageUtil.SetFloatValue(target, instKey, param as float / 100.0)
        StorageUtil.SetFloatValue(target, instKey + ".fade", fade)
        StorageUtil.StringListAdd(target, KEY_PREFIX + "scale.instances", instKey, false)
        _startScale(target, fade)
    elseif eid == "shape"
        int shape = _shapeIndex(_paramNStrEx(slot, effectIdx, useScratch, presetName, 1))
        if shape < 0 || param2 <= 0 || StorageUtil.HasIntValue(target, instKey)
            return
        endif
        float fade = _clampInt(_paramNEx(slot, effectIdx, useScratch, presetName, 3), 0, MAX_TRANSITION) as float
        StorageUtil.SetIntValue(target, instKey, shape * 1000 + _clampInt(param2, 0, 100))
        StorageUtil.SetFloatValue(target, instKey + ".fade", fade)
        StorageUtil.StringListAdd(target, KEY_PREFIX + "shape.instances", instKey, false)
        _startShapes(target, fade)
    endif
EndFunction

Function onDeactivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None
        return
    endif
    string instKey = _instanceKey(eid, slot, effectIdx)
    float fade = StorageUtil.GetFloatValue(target, instKey + ".fade")
    if eid == "scale"
        if !StorageUtil.HasFloatValue(target, instKey)
            return
        endif
        StorageUtil.UnsetFloatValue(target, instKey)
        StorageUtil.UnsetFloatValue(target, instKey + ".fade")
        StorageUtil.StringListRemove(target, KEY_PREFIX + "scale.instances", instKey, true)
        _startScale(target, fade)
    elseif eid == "shape"
        if !StorageUtil.HasIntValue(target, instKey)
            return
        endif
        StorageUtil.UnsetIntValue(target, instKey)
        StorageUtil.UnsetFloatValue(target, instKey + ".fade")
        StorageUtil.StringListRemove(target, KEY_PREFIX + "shape.instances", instKey, true)
        _startShapes(target, fade)
    endif
EndFunction

; ── Transitions ─────────────────────────────────────────────────────────────

; Called by MTF_Plugin_RaceMenu_Loop. Moves every listed actor one step and returns whether any still moves.
bool Function _step()
    float now = Utility.GetCurrentRealTime()
    int i = StorageUtil.FormListCount(self, RAMP_LIST)
    while i > 0
        i -= 1
        Actor moving = StorageUtil.FormListGet(self, RAMP_LIST, i) as Actor
        bool stillMoving = false
        if moving != None
            bool shapeMoving = _stepShapes(moving, now)
            bool scaleMoving = _stepScale(moving, now)
            stillMoving = shapeMoving || scaleMoving
        endif
        if !stillMoving
            StorageUtil.FormListRemoveAt(self, RAMP_LIST, i)
        endif
    endwhile
    return StorageUtil.FormListCount(self, RAMP_LIST) > 0
EndFunction

Function _beginRamp(Actor target, string kind, float fade)
    StorageUtil.SetFloatValue(target, KEY_PREFIX + kind + ".ramp.duration", fade)
    StorageUtil.SetFloatValue(target, KEY_PREFIX + kind + ".ramp.start", Utility.GetCurrentRealTime())
    StorageUtil.FormListAdd(self, RAMP_LIST, target, false)
    GetAlias(0).RegisterForSingleUpdate(0.01)
EndFunction

Function _endRamp(Actor target, string kind)
    StorageUtil.UnsetFloatValue(target, KEY_PREFIX + kind + ".ramp.start")
    StorageUtil.UnsetFloatValue(target, KEY_PREFIX + kind + ".ramp.duration")
EndFunction

; Eased progress from 0 to 1, or -1 when no transition of this kind is running. Smoothstep, so the change
; starts and stops gently.
float Function _rampProgress(Actor target, string kind, float now)
    string startKey = KEY_PREFIX + kind + ".ramp.start"
    if !StorageUtil.HasFloatValue(target, startKey)
        return -1.0
    endif
    float duration = StorageUtil.GetFloatValue(target, KEY_PREFIX + kind + ".ramp.duration")
    float t = 1.0
    if duration > 0.0
        t = (now - StorageUtil.GetFloatValue(target, startKey)) / duration
    endif
    if t >= 1.0 || t < 0.0
        return 1.0
    endif
    return t * t * (3.0 - 2.0 * t)
EndFunction

; ── Scale ───────────────────────────────────────────────────────────────────

; A keyed scale on the root "NPC" node, which multiplies with RaceMenu's own height. Stacked instances multiply.
float Function _scaleTarget(Actor target)
    string listKey = KEY_PREFIX + "scale.instances"
    int n = StorageUtil.StringListCount(target, listKey)
    float factor = 1.0
    int i = 0
    while i < n
        factor *= StorageUtil.GetFloatValue(target, StorageUtil.StringListGet(target, listKey, i), 1.0)
        i += 1
    endwhile
    return factor
EndFunction

; Starts from the scale shown right now, so a change mid-transition carries on smoothly.
Function _startScale(Actor target, float fade)
    float goal = _scaleTarget(target)
    if fade <= 0.0
        _endRamp(target, "scale")
        _setScale(target, goal)
        return
    endif
    StorageUtil.SetFloatValue(target, KEY_PREFIX + "scale.from", StorageUtil.GetFloatValue(target, KEY_PREFIX + "scale.current", 1.0))
    StorageUtil.SetFloatValue(target, KEY_PREFIX + "scale.to", goal)
    _beginRamp(target, "scale", fade)
EndFunction

bool Function _stepScale(Actor target, float now)
    float eased = _rampProgress(target, "scale", now)
    if eased < 0.0
        return false
    endif
    float from = StorageUtil.GetFloatValue(target, KEY_PREFIX + "scale.from", 1.0)
    float goal = StorageUtil.GetFloatValue(target, KEY_PREFIX + "scale.to", 1.0)
    _setScale(target, from + (goal - from) * eased)
    if eased < 1.0
        return true
    endif
    _endRamp(target, "scale")
    StorageUtil.UnsetFloatValue(target, KEY_PREFIX + "scale.from")
    StorageUtil.UnsetFloatValue(target, KEY_PREFIX + "scale.to")
    return false
EndFunction

; Usual size removes the transform altogether rather than leaving a 1.0 entry behind.
Function _setScale(Actor target, float factor)
    bool apply = factor > 1.001 || factor < 0.999
    if apply
        StorageUtil.SetFloatValue(target, KEY_PREFIX + "scale.current", factor)
    else
        StorageUtil.UnsetFloatValue(target, KEY_PREFIX + "scale.current")
    endif
    bool isFemale = _isFemale(target)
    _setNodeScale(target, false, isFemale, apply, factor)
    if target == PlayerRef
        _setNodeScale(target, true, isFemale, apply, factor)
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

; Starts each slider from its value right now, so a change mid-transition carries on smoothly. Only sliders
; that change are stepped.
Function _startShapes(Actor target, float fade)
    string[] sliders = _sliderNames()
    float[] goals = _shapeTargets(target, sliders)
    string movingKey = KEY_PREFIX + "shape.moving"
    _clearShapeRamp(target)
    if fade <= 0.0
        int s = 0
        while s < sliders.Length
            _setMorph(target, sliders[s], goals[s])
            s += 1
        endwhile
        NiOverride.UpdateModelWeight(target)
        _logMorphs(target, sliders)
        return
    endif
    int i = 0
    while i < sliders.Length
        float from = NiOverride.GetBodyMorph(target, sliders[i], NI_KEY)
        if from != goals[i]
            StorageUtil.SetFloatValue(target, KEY_PREFIX + "shape.from." + sliders[i], from)
            StorageUtil.SetFloatValue(target, KEY_PREFIX + "shape.to." + sliders[i], goals[i])
            StorageUtil.StringListAdd(target, movingKey, sliders[i], false)
        endif
        i += 1
    endwhile
    if StorageUtil.StringListCount(target, movingKey) > 0
        _beginRamp(target, "shape", fade)
    endif
EndFunction

bool Function _stepShapes(Actor target, float now)
    float eased = _rampProgress(target, "shape", now)
    if eased < 0.0
        return false
    endif
    string movingKey = KEY_PREFIX + "shape.moving"
    int n = StorageUtil.StringListCount(target, movingKey)
    int i = 0
    while i < n
        string slider = StorageUtil.StringListGet(target, movingKey, i)
        float from = StorageUtil.GetFloatValue(target, KEY_PREFIX + "shape.from." + slider)
        float goal = StorageUtil.GetFloatValue(target, KEY_PREFIX + "shape.to." + slider)
        _setMorph(target, slider, from + (goal - from) * eased)
        i += 1
    endwhile
    NiOverride.UpdateModelWeight(target)
    if eased < 1.0
        return true
    endif
    _clearShapeRamp(target)
    _logMorphs(target, _sliderNames())
    return false
EndFunction

Function _clearShapeRamp(Actor target)
    string movingKey = KEY_PREFIX + "shape.moving"
    int i = StorageUtil.StringListCount(target, movingKey)
    while i > 0
        i -= 1
        string slider = StorageUtil.StringListGet(target, movingKey, i)
        StorageUtil.UnsetFloatValue(target, KEY_PREFIX + "shape.from." + slider)
        StorageUtil.UnsetFloatValue(target, KEY_PREFIX + "shape.to." + slider)
    endwhile
    StorageUtil.StringListClear(target, movingKey)
    _endRamp(target, "shape")
EndFunction

Function _setMorph(Actor target, string slider, float value)
    if value > 0.0001 || value < -0.0001
        NiOverride.SetBodyMorph(target, slider, NI_KEY, value)
    else
        NiOverride.ClearBodyMorph(target, slider, NI_KEY)
    endif
EndFunction

Function _logMorphs(Actor target, string[] sliders)
    string applied = ""
    int i = 0
    while i < sliders.Length
        float value = NiOverride.GetBodyMorph(target, sliders[i], NI_KEY)
        if value != 0.0
            applied += " " + sliders[i] + "=" + value
        endif
        i += 1
    endwhile
    if applied == ""
        applied = " none"
    endif
    Debug.Trace("[MTF_Plugin_RaceMenu] body morphs on " + target.GetName() + ":" + applied)
EndFunction

; Each slider gets the strongest value any shown instance asks for, so stacked tiers don't add up past
; what one tier at full strength would do. Morph values are slider fractions: 1.0 is 100 in BodySlide.
float[] Function _shapeTargets(Actor target, string[] sliders)
    string listKey = KEY_PREFIX + "shape.instances"
    int n = StorageUtil.StringListCount(target, listKey)
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
    return values
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
