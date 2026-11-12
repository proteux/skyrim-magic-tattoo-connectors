; Copyright (C) 2026 Jack Whitehouse (proteux). Licensed under the GNU General Public License v3.0 or later; see LICENSE.
Scriptname MTF_Plugin_RaceMenu extends MTF_Plugin
{Magic Tattoos Framework effects backed by RaceMenu: actor scale, BodySlide body shapes, and hair color.
 Soft dependency: RaceMenu's skee plugin is checked at runtime, and the plugin stays unregistered without it.
 Catalog: SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/proteux-mtf.racemenu.json

 Scale and shapes go through NiOverride under this plugin's own key, so they add to RaceMenu's sliders, OBody
 presets, and other mods instead of overwriting them, and clearing the key undoes only this plugin's part.
 Hair color is a tint override on the hair's own nodes. Those aren't keyed, so the plugin remembers each
 node's color beforehand and puts it back. RaceMenu saves node transforms, body morphs and node overrides in
 its co-save, so nothing needs replaying after a load.

 Hair color (any wig) instead tints everything drawn as hair through powerofthree's SetHairColor,
 a second soft dependency checked when an instance starts. That tint isn't saved, so onTick keeps putting it back.

 Changes ease in and out over each instance's Transition seconds. MTF's onTick is too coarse for that, so
 MTF_Plugin_RaceMenu_Loop, on the player alias, calls _step every STEP_SECONDS while any actor is moving.}

string Property MOD_VERSION = "0.2.0" AutoReadOnly Hidden
string Property KEY_PREFIX = "proteux-mtf.racemenu." AutoReadOnly Hidden
string Property NI_KEY = "proteux-mtf.racemenu" AutoReadOnly Hidden
string Property RAMP_LIST = "proteux-mtf.racemenu.moving" AutoReadOnly Hidden
string Property ACTOR_LIST = "proteux-mtf.racemenu.actors" AutoReadOnly Hidden
float Property STEP_SECONDS = 0.25 AutoReadOnly Hidden
int Property MAX_TRANSITION = 30 AutoReadOnly Hidden
string Property ESP_NAME = "MTF_Plugin_RaceMenu.esp" AutoReadOnly Hidden
; Must match COLOR_FORMS in build.sh: the ESP's color records, FormIDs 0x801 up.
int Property HAIR_TINT_FORMS = 32 AutoReadOnly Hidden

Actor Property PlayerRef Auto Hidden
; Set to 1 from the console (setpqv MTF_Plugin_RaceMenu ResetOnLoad 1); the next save load undoes every
; change this plugin made and sets it back to 0. Skyrim's console can't call a script function directly.
int Property ResetOnLoad = 0 Auto Hidden

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
    if ResetOnLoad != 0
        ResetOnLoad = 0
        _resetAll()
        return
    endif
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
            StorageUtil.SetFloatValue(moving, KEY_PREFIX + "hair.ramp.duration", 0.0)
            StorageUtil.SetFloatValue(moving, KEY_PREFIX + "hairtint.ramp.duration", 0.0)
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
        StorageUtil.FormListAdd(self, ACTOR_LIST, target, false)
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
        StorageUtil.FormListAdd(self, ACTOR_LIST, target, false)
        _startShapes(target, fade)
    elseif eid == "hair"
        if StorageUtil.HasIntValue(target, instKey)
            return
        endif
        float fade = _clampInt(param2, 0, MAX_TRANSITION) as float
        bool hairOnly = _paramNStrEx(slot, effectIdx, useScratch, presetName, 3) == "hair"
        StorageUtil.SetIntValue(target, instKey, _rgb(param))
        StorageUtil.SetIntValue(target, instKey + ".parts", hairOnly as int)
        StorageUtil.SetFloatValue(target, instKey + ".fade", fade)
        StorageUtil.StringListAdd(target, KEY_PREFIX + "hair.instances", instKey, false)
        StorageUtil.FormListAdd(self, ACTOR_LIST, target, false)
        _startHair(target, fade)
        _logHairDebug(target)
    elseif eid == "hairtint"
        if StorageUtil.HasIntValue(target, instKey)
            return
        endif
        if !_hasPapyrusExtender()
            Debug.Trace("[MTF_Plugin_RaceMenu] Hair color (any wig) needs powerofthree's Papyrus Extender, which isn't installed")
            return
        endif
        float fade = _clampInt(param2, 0, MAX_TRANSITION) as float
        StorageUtil.SetIntValue(target, instKey, _rgb(param))
        StorageUtil.SetFloatValue(target, instKey + ".fade", fade)
        StorageUtil.StringListAdd(target, KEY_PREFIX + "hairtint.instances", instKey, false)
        StorageUtil.FormListAdd(self, ACTOR_LIST, target, false)
        _startHairTint(target, fade)
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
    elseif eid == "hair"
        if !StorageUtil.HasIntValue(target, instKey)
            return
        endif
        StorageUtil.UnsetIntValue(target, instKey)
        StorageUtil.UnsetIntValue(target, instKey + ".parts")
        StorageUtil.UnsetFloatValue(target, instKey + ".fade")
        StorageUtil.StringListRemove(target, KEY_PREFIX + "hair.instances", instKey, true)
        _startHair(target, fade)
    elseif eid == "hairtint"
        if !StorageUtil.HasIntValue(target, instKey)
            return
        endif
        StorageUtil.UnsetIntValue(target, instKey)
        StorageUtil.UnsetFloatValue(target, instKey + ".fade")
        StorageUtil.StringListRemove(target, KEY_PREFIX + "hairtint.instances", instKey, true)
        _startHairTint(target, fade)
    endif
EndFunction

; A new hairstyle or wig has nodes the tint isn't on yet, and a wig put back on, or hair physics rebuilding the
; mesh, loses the tint. Between transitions, picks up new nodes or puts the color back.
Function onTick(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None || !target.Is3DLoaded()
        return
    endif
    if eid == "hairtint"
        if !StorageUtil.HasFloatValue(target, KEY_PREFIX + "hairtint.ramp.start")
            _reapplyHairTint(target)
        endif
        return
    elseif eid != "hair"
        return
    endif
    if StorageUtil.HasFloatValue(target, KEY_PREFIX + "hair.ramp.start")
        return
    endif
    if _findHairNodes(target, _hairIncludesBeard(target), false)
        _startHair(target, 0.0)
        _logHairDebug(target)
    else
        _repairHair(target)
    endif
EndFunction

; ── Reset ───────────────────────────────────────────────────────────────────

; Undoes every change on every actor this plugin has touched, and forgets the tiers it applied. MTF still
; counts those tiers as showing, so their onDeactivate finds nothing to undo, and they apply again the next
; time they start. The player is always included, in case they were touched before the actor list existed.
Function _resetAll()
    StorageUtil.FormListAdd(self, ACTOR_LIST, PlayerRef, false)
    int i = StorageUtil.FormListCount(self, ACTOR_LIST)
    int count = 0
    while i > 0
        i -= 1
        Actor target = StorageUtil.FormListGet(self, ACTOR_LIST, i) as Actor
        if target != None
            _resetActor(target)
            count += 1
        endif
    endwhile
    StorageUtil.FormListClear(self, ACTOR_LIST)
    StorageUtil.FormListClear(self, RAMP_LIST)
    Debug.Trace("[MTF_Plugin_RaceMenu] reset " + count + " actor(s)")
EndFunction

Function _resetActor(Actor target)
    _clearShapeRamp(target)
    _endRamp(target, "scale")
    StorageUtil.UnsetFloatValue(target, KEY_PREFIX + "scale.from")
    StorageUtil.UnsetFloatValue(target, KEY_PREFIX + "scale.to")
    _forgetInstances(target, "shape")
    _forgetInstances(target, "scale")
    NiOverride.ClearBodyMorphKeys(target, NI_KEY)
    NiOverride.UpdateModelWeight(target)
    _setScale(target, 1.0)
    _forgetInstances(target, "hair")
    _startHair(target, 0.0)
    _forgetInstances(target, "hairtint")
    _startHairTint(target, 0.0)
EndFunction

Function _forgetInstances(Actor target, string kind)
    string listKey = KEY_PREFIX + kind + ".instances"
    int i = StorageUtil.StringListCount(target, listKey)
    while i > 0
        i -= 1
        string instKey = StorageUtil.StringListGet(target, listKey, i)
        StorageUtil.UnsetIntValue(target, instKey)
        StorageUtil.UnsetIntValue(target, instKey + ".parts")
        StorageUtil.UnsetFloatValue(target, instKey)
        StorageUtil.UnsetFloatValue(target, instKey + ".fade")
    endwhile
    StorageUtil.StringListClear(target, listKey)
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
            bool hairMoving = _stepHair(moving, now)
            bool tintMoving = _stepHairTint(moving, now)
            stillMoving = shapeMoving || scaleMoving || hairMoving || tintMoving
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

; ── Hair color ──────────────────────────────────────────────────────────────

; The hair shader multiplies its texture by one tint color, NiOverride key 7. The newest instance wins; on
; the hair alone, or the brows and beard too. Every node starts from the color it showed before the plugin
; touched it, and gets that color back when no instance covers it any more.

; Starts each node from the color it shows right now, so a change mid-transition carries on smoothly.
Function _startHair(Actor target, float fade)
    if StorageUtil.StringListCount(target, KEY_PREFIX + "hair.instances") > 0
        _findHairNodes(target, _hairIncludesBeard(target), true)
    endif
    _clearHairRamp(target)
    string listKey = KEY_PREFIX + "hair.nodes"
    string movingKey = KEY_PREFIX + "hair.moving"
    int n = StorageUtil.StringListCount(target, listKey)
    if n <= 0
        return
    endif
    int i = 0
    while i < n
        string node = StorageUtil.StringListGet(target, listKey, i)
        string nodeKey = _hairNodeKey(node)
        StorageUtil.SetIntValue(target, nodeKey + ".from", StorageUtil.GetIntValue(target, nodeKey + ".cur"))
        StorageUtil.SetIntValue(target, nodeKey + ".to", _hairGoal(target, nodeKey))
        StorageUtil.StringListAdd(target, movingKey, node, false)
        i += 1
    endwhile
    if fade <= 0.0
        _finishHair(target)
        return
    endif
    _beginRamp(target, "hair", fade)
EndFunction

; Steps aren't saved: RaceMenu keeps the last finished color until the transition ends.
bool Function _stepHair(Actor target, float now)
    float eased = _rampProgress(target, "hair", now)
    if eased < 0.0
        return false
    endif
    if eased >= 1.0
        _finishHair(target)
        return false
    endif
    if !target.Is3DLoaded()
        return true
    endif
    bool isFemale = _isFemale(target)
    string movingKey = KEY_PREFIX + "hair.moving"
    int n = StorageUtil.StringListCount(target, movingKey)
    int i = 0
    while i < n
        string node = StorageUtil.StringListGet(target, movingKey, i)
        string nodeKey = _hairNodeKey(node)
        int from = StorageUtil.GetIntValue(target, nodeKey + ".from")
        int goal = StorageUtil.GetIntValue(target, nodeKey + ".to")
        if from != goal
            int color = _blendColor(from, goal, eased)
            StorageUtil.SetIntValue(target, nodeKey + ".cur", color)
            NiOverride.AddNodeOverrideInt(target, isFemale, node, 7, -1, color, false)
        endif
        i += 1
    endwhile
    return true
EndFunction

; Saves each node's final color. A node no instance covers gets its own color back and is forgotten; the
; override comes off after ApplyNodeOverrides, which leaves that color showing until the head next loads.
Function _finishHair(Actor target)
    bool isFemale = _isFemale(target)
    string movingKey = KEY_PREFIX + "hair.moving"
    string applied = ""
    int n = StorageUtil.StringListCount(target, movingKey)
    int i = 0
    while i < n
        string node = StorageUtil.StringListGet(target, movingKey, i)
        string nodeKey = _hairNodeKey(node)
        int goal = StorageUtil.GetIntValue(target, nodeKey + ".to")
        StorageUtil.SetIntValue(target, nodeKey + ".cur", goal)
        NiOverride.AddNodeOverrideInt(target, isFemale, node, 7, -1, goal, true)
        if _hairCovers(target, nodeKey)
            applied += " " + node + "=#" + _hex(goal)
        endif
        i += 1
    endwhile
    NiOverride.ApplyNodeOverrides(target)
    i = n
    while i > 0
        i -= 1
        string node = StorageUtil.StringListGet(target, movingKey, i)
        if !_hairCovers(target, _hairNodeKey(node))
            _forgetHairNode(target, node, isFemale)
        endif
    endwhile
    _clearHairRamp(target)
    if applied == ""
        applied = " none"
    endif
    Debug.Trace("[MTF_Plugin_RaceMenu] hair color on " + _actorName(target) + ":" + applied)
EndFunction

Function _clearHairRamp(Actor target)
    string movingKey = KEY_PREFIX + "hair.moving"
    int i = StorageUtil.StringListCount(target, movingKey)
    while i > 0
        i -= 1
        string nodeKey = _hairNodeKey(StorageUtil.StringListGet(target, movingKey, i))
        StorageUtil.UnsetIntValue(target, nodeKey + ".from")
        StorageUtil.UnsetIntValue(target, nodeKey + ".to")
    endwhile
    StorageUtil.StringListClear(target, movingKey)
    _endRamp(target, "hair")
EndFunction

; Head part types: 3 hair, 4 facial hair, 6 brows. Each part's extra parts, such as a hairline, come along,
; and so does a wig worn in the hair slots. Returns whether any node is new.
bool Function _findHairNodes(Actor target, bool includeBeard, bool rescanWorn)
    Form worn31 = target.GetWornForm(0x2)
    Form worn41 = target.GetWornForm(0x800)
    bool added = _findWornHair(target, worn31 as Armor, "31", rescanWorn)
    if worn41 != worn31 && _findWornHair(target, worn41 as Armor, "41", rescanWorn)
        added = true
    endif
    if _findHeadPartHair(target, includeBeard)
        added = true
    endif
    return added
EndFunction

; A wig is armor, not a head part, so its node names are guessed from its mesh and kept if they exist. KS
; Hairdos SMP wigs name their shapes after the mesh: Angels_1.nif holds KSSMP_Angels, KSSMP_Angels_HL and
; Hairline. Each item is only searched again once it's taken off, or when an instance starts.
bool Function _findWornHair(Actor target, Armor worn, string slot, bool rescan)
    string memKey = KEY_PREFIX + "hair.worn." + slot
    if worn == None
        StorageUtil.UnsetIntValue(target, memKey)
        return false
    endif
    if !rescan && StorageUtil.GetIntValue(target, memKey) == worn.GetFormID()
        return false
    endif
    if !target.Is3DLoaded()
        return false
    endif
    bool isFemale = _isFemale(target)
    bool added = false
    bool found = false
    int n = worn.GetNumArmorAddons()
    int i = 0
    while i < n
        ArmorAddon addon = worn.GetNthArmorAddon(i)
        if addon != None && _inHairSlot(addon.GetSlotMask())
            string name = _modelBaseName(addon.GetModelPath(false, isFemale))
            int k = 0
            while k < 4
                string node = _wigNodeName(name, k)
                if node != "" && NetImmerse.HasNode(target, node, false)
                    found = true
                    if _addHairNode(target, node, false)
                        added = true
                    endif
                endif
                k += 1
            endwhile
        endif
        i += 1
    endwhile
    if found
        StorageUtil.SetIntValue(target, memKey, worn.GetFormID())
    endif
    return added
EndFunction

bool Function _inHairSlot(int slotMask) global
    return (slotMask / 0x2) % 2 != 0 || (slotMask / 0x800) % 2 != 0
EndFunction

string Function _wigNodeName(string name, int k) global
    if k == 3
        return "Hairline"
    elseif name == ""
        return ""
    elseif k == 0
        return "KSSMP_" + name
    elseif k == 1
        return "KSSMP_" + name + "_HL"
    endif
    return name
EndFunction

; Puts the color back on any node showing something else, such as a wig taken off and put on again, or
; hair physics rebuilding the mesh. The shader rounds colors, so a channel may be off by a little.
Function _repairHair(Actor target)
    bool isFemale = _isFemale(target)
    string listKey = KEY_PREFIX + "hair.nodes"
    int i = StorageUtil.StringListCount(target, listKey)
    while i > 0
        i -= 1
        string node = StorageUtil.StringListGet(target, listKey, i)
        string nodeKey = _hairNodeKey(node)
        if _hairCovers(target, nodeKey) && NetImmerse.HasNode(target, node, false)
            int want = StorageUtil.GetIntValue(target, nodeKey + ".cur")
            int live = _rgb(NiOverride.GetNodePropertyInt(target, false, node, 7, -1))
            if !_closeColor(want, live)
                NiOverride.AddNodeOverrideInt(target, isFemale, node, 7, -1, want, true)
                Debug.Trace("[MTF_Plugin_RaceMenu] hair color on " + _actorName(target) + ": put back " + node + "=#" + _hex(want) + " (was #" + _hex(live) + ")")
            endif
        endif
    endwhile
EndFunction

bool Function _closeColor(int a, int b) global
    return _channelGap(a / 0x10000, b / 0x10000) <= 2 && _channelGap((a / 0x100) % 0x100, (b / 0x100) % 0x100) <= 2 && _channelGap(a % 0x100, b % 0x100) <= 2
EndFunction

int Function _channelGap(int a, int b) global
    if a > b
        return a - b
    endif
    return b - a
EndFunction

bool Function _findHeadPartHair(Actor target, bool includeBeard)
    ActorBase base = target.GetLeveledActorBase()
    if base == None
        return false
    endif
    bool added = false
    int i = base.GetNumHeadParts()
    while i > 0
        i -= 1
        HeadPart part = base.GetNthHeadPart(i)
        if part != None
            int type = part.GetType()
            bool beard = type == 4 || type == 6
            if type == 3 || (beard && includeBeard)
                if _addHairNode(target, part.GetPartName(), beard)
                    added = true
                endif
                int e = part.GetNumExtraParts()
                while e > 0
                    e -= 1
                    HeadPart extra = part.GetNthExtraPart(e)
                    if extra != None && _addHairNode(target, extra.GetPartName(), beard)
                        added = true
                    endif
                endwhile
            endif
        endif
    endwhile
    return added
EndFunction

; A head part's node in the actor's 3D is named after its editor ID. The color it shows now is remembered:
; another mod's override if there is one (kept afterwards), else the live shader's, else the NPC's hair color.
bool Function _addHairNode(Actor target, string node, bool beard)
    string listKey = KEY_PREFIX + "hair.nodes"
    if node == "" || StorageUtil.StringListFind(target, listKey, node) >= 0
        return false
    endif
    string nodeKey = _hairNodeKey(node)
    bool isFemale = _isFemale(target)
    int orig = 0
    if NiOverride.HasNodeOverride(target, isFemale, node, 7, -1)
        orig = _rgb(NiOverride.GetNodeOverrideInt(target, isFemale, node, 7, -1))
        StorageUtil.SetIntValue(target, nodeKey + ".kept", 1)
    elseif target.Is3DLoaded()
        orig = _rgb(NiOverride.GetNodePropertyInt(target, false, node, 7, -1))
    endif
    if orig == 0
        orig = _baseHairColor(target)
    endif
    StorageUtil.SetIntValue(target, nodeKey, orig)
    StorageUtil.SetIntValue(target, nodeKey + ".cur", orig)
    StorageUtil.SetIntValue(target, nodeKey + ".beard", beard as int)
    StorageUtil.StringListAdd(target, listKey, node, false)
    return true
EndFunction

; Expects the node's own color to be showing already. Another mod's override stays; this plugin's comes off.
Function _forgetHairNode(Actor target, string node, bool isFemale)
    string nodeKey = _hairNodeKey(node)
    if StorageUtil.GetIntValue(target, nodeKey + ".kept") == 0
        NiOverride.RemoveNodeOverride(target, isFemale, node, 7, -1)
    endif
    StorageUtil.UnsetIntValue(target, nodeKey)
    StorageUtil.UnsetIntValue(target, nodeKey + ".cur")
    StorageUtil.UnsetIntValue(target, nodeKey + ".beard")
    StorageUtil.UnsetIntValue(target, nodeKey + ".kept")
    StorageUtil.UnsetIntValue(target, nodeKey + ".from")
    StorageUtil.UnsetIntValue(target, nodeKey + ".to")
    StorageUtil.StringListRemove(target, KEY_PREFIX + "hair.nodes", node, true)
EndFunction

bool Function _hairCovers(Actor target, string nodeKey)
    string listKey = KEY_PREFIX + "hair.instances"
    int n = StorageUtil.StringListCount(target, listKey)
    if n <= 0
        return false
    endif
    if StorageUtil.GetIntValue(target, nodeKey + ".beard") == 0
        return true
    endif
    return StorageUtil.GetIntValue(target, StorageUtil.StringListGet(target, listKey, n - 1) + ".parts") == 0
EndFunction

bool Function _hairIncludesBeard(Actor target)
    string listKey = KEY_PREFIX + "hair.instances"
    int n = StorageUtil.StringListCount(target, listKey)
    return n > 0 && StorageUtil.GetIntValue(target, StorageUtil.StringListGet(target, listKey, n - 1) + ".parts") == 0
EndFunction

int Function _hairGoal(Actor target, string nodeKey)
    if !_hairCovers(target, nodeKey)
        return StorageUtil.GetIntValue(target, nodeKey)
    endif
    string listKey = KEY_PREFIX + "hair.instances"
    int n = StorageUtil.StringListCount(target, listKey)
    return StorageUtil.GetIntValue(target, StorageUtil.StringListGet(target, listKey, n - 1))
EndFunction

; The shader shows the hair color record at twice its value: #6B3F47 shows as #D67E8E. White leaves the hair
; texture as it is.
int Function _baseHairColor(Actor target)
    ActorBase base = target.GetLeveledActorBase()
    if base != None
        ColorForm color = base.GetHairColor()
        if color != None
            int c = _rgb(color.GetColor())
            return _doubleChannel(c / 0x10000) * 0x10000 + _doubleChannel((c / 0x100) % 0x100) * 0x100 + _doubleChannel(c % 0x100)
        endif
    endif
    return 0xFFFFFF
EndFunction

int Function _doubleChannel(int c) global
    if c > 127
        return 255
    endif
    return c * 2
EndFunction

; Lists what the hair effect can see on the actor: head parts, the items worn in the hair slots (31 and 41)
; with the node names a wig's mesh suggests, and the nodes being tinted. Each node shows whether it exists in
; the actor's 3D and its live tint.
Function _logHairDebug(Actor target)
    string tag = "[MTF_Plugin_RaceMenu] hair debug: "
    bool isFemale = _isFemale(target)
    Debug.Trace(tag + _actorName(target) + ", 3D loaded " + target.Is3DLoaded() + ", female " + isFemale)
    ActorBase base = target.GetLeveledActorBase()
    if base != None
        string recordColor = "none"
        ColorForm color = base.GetHairColor()
        if color != None
            recordColor = "#" + _hex(_rgb(color.GetColor()))
        endif
        Debug.Trace(tag + "hair color record " + recordColor)
        int n = base.GetNumHeadParts()
        int i = 0
        while i < n
            HeadPart part = base.GetNthHeadPart(i)
            if part != None
                Debug.Trace(tag + "head part type " + part.GetType() + " " + part.GetPartName() + _hairNodeState(target, part.GetPartName()))
                int e = 0
                int extras = part.GetNumExtraParts()
                while e < extras
                    HeadPart extra = part.GetNthExtraPart(e)
                    if extra != None
                        Debug.Trace(tag + "  extra type " + extra.GetType() + " " + extra.GetPartName() + _hairNodeState(target, extra.GetPartName()))
                    endif
                    e += 1
                endwhile
            endif
            i += 1
        endwhile
    endif
    Form slot31 = target.GetWornForm(0x2)
    _logWornHair(target, slot31, "31", isFemale)
    Form slot41 = target.GetWornForm(0x800)
    if slot41 != None && slot41 == slot31
        Debug.Trace(tag + "slot 41: the same item")
    else
        _logWornHair(target, slot41, "41", isFemale)
    endif
    string listKey = KEY_PREFIX + "hair.nodes"
    int count = StorageUtil.StringListCount(target, listKey)
    int t = 0
    while t < count
        string node = StorageUtil.StringListGet(target, listKey, t)
        string nodeKey = _hairNodeKey(node)
        Debug.Trace(tag + "tracking " + node + ": own #" + _hex(StorageUtil.GetIntValue(target, nodeKey)) + ", set #" + _hex(StorageUtil.GetIntValue(target, nodeKey + ".cur")) + _hairNodeState(target, node))
        t += 1
    endwhile
EndFunction

Function _logWornHair(Actor target, Form worn, string slot, bool isFemale)
    string tag = "[MTF_Plugin_RaceMenu] hair debug: "
    if worn == None
        Debug.Trace(tag + "slot " + slot + ": empty")
        return
    endif
    Debug.Trace(tag + "slot " + slot + ": " + worn.GetName() + " (form id " + worn.GetFormID() + ")")
    Armor item = worn as Armor
    if item == None
        return
    endif
    int n = item.GetNumArmorAddons()
    int i = 0
    while i < n
        ArmorAddon addon = item.GetNthArmorAddon(i)
        if addon != None
            string path = addon.GetModelPath(false, isFemale)
            Debug.Trace(tag + "  addon " + i + ": slot mask " + addon.GetSlotMask() + ", model " + path)
            string name = _modelBaseName(path)
            if name != ""
                Debug.Trace(tag + "    KSSMP_" + name + _hairNodeState(target, "KSSMP_" + name))
                Debug.Trace(tag + "    KSSMP_" + name + "_HL" + _hairNodeState(target, "KSSMP_" + name + "_HL"))
                Debug.Trace(tag + "    " + name + _hairNodeState(target, name))
            endif
        endif
        i += 1
    endwhile
    Debug.Trace(tag + "  Hairline" + _hairNodeState(target, "Hairline"))
EndFunction

string Function _hairNodeState(Actor target, string node)
    if node == ""
        return ""
    elseif !target.Is3DLoaded()
        return " (3D not loaded)"
    elseif !NetImmerse.HasNode(target, node, false)
        return " (no node)"
    endif
    return " (node, tint #" + _hex(_rgb(NiOverride.GetNodePropertyInt(target, false, node, 7, -1))) + ")"
EndFunction

; "Armor\KSWigsHDT\f\Anchor_0.nif" gives "Anchor": the file name without its extension or weight suffix.
string Function _modelBaseName(string path) global
    string name = _afterLast(_afterLast(path, "\\"), "/")
    int dot = StringUtil.Find(name, ".")
    if dot > 0
        name = StringUtil.Substring(name, 0, dot)
    endif
    int len = StringUtil.GetLength(name)
    if len > 2
        string suffix = StringUtil.Substring(name, len - 2)
        if suffix == "_0" || suffix == "_1"
            name = StringUtil.Substring(name, 0, len - 2)
        endif
    endif
    return name
EndFunction

string Function _afterLast(string s, string sep) global
    int start = 0
    int found = StringUtil.Find(s, sep)
    while found >= 0
        start = found + 1
        found = StringUtil.Find(s, sep, start)
    endwhile
    if start == 0
        return s
    endif
    return StringUtil.Substring(s, start)
EndFunction

; The player reference has no name of its own, so fall back to the base actor's.
string Function _actorName(Actor target)
    string name = target.GetName()
    if name == ""
        ActorBase base = target.GetLeveledActorBase()
        if base != None
            name = base.GetName()
        endif
    endif
    return name
EndFunction

string Function _hairNodeKey(string node)
    return KEY_PREFIX + "hair.node." + node
EndFunction

; Drops any alpha byte, leaving 0xRRGGBB.
int Function _rgb(int color) global
    color = color % 0x1000000
    if color < 0
        color += 0x1000000
    endif
    return color
EndFunction

int Function _blendColor(int from, int goal, float t) global
    int r = _blendChannel(from / 0x10000, goal / 0x10000, t)
    int g = _blendChannel((from / 0x100) % 0x100, (goal / 0x100) % 0x100, t)
    int b = _blendChannel(from % 0x100, goal % 0x100, t)
    return r * 0x10000 + g * 0x100 + b
EndFunction

int Function _blendChannel(int from, int goal, float t) global
    return (from as float + (goal - from) as float * t + 0.5) as int
EndFunction

string Function _hex(int color) global
    string digits = "0123456789ABCDEF"
    string s = ""
    int i = 0
    while i < 6
        s = StringUtil.GetNthChar(digits, color % 16) + s
        color /= 16
        i += 1
    endwhile
    return s
EndFunction

; ── Hair color (any wig) ────────────────────────────────────────────────────

; powerofthree's SetHairColor tints every mesh in the actor's 3D drawn as hair, from whatever mod, wigs
; included. It reads the color record when its queued task runs, so each actor borrows its own record from
; the ESP's pool and two actors changing at once can't swap colors. The newest instance wins. The tint
; lives only on the loaded 3D: a load, a rebuilt mesh or a wig put on shows the hair's own color until
; onTick puts the tint back.

bool Function _hasPapyrusExtender()
    if SKSE.GetPluginVersion("powerofthree's Papyrus Extender") > 0 || SKSE.GetPluginVersion("po3_PapyrusExtender") > 0
        return true
    endif
    int[] version = PO3_SKSEFunctions.GetPapyrusExtenderVersion()
    return version.Length > 0
EndFunction

; Starts from the color shown right now, so a change mid-transition carries on smoothly. An actor that
; isn't loaded jumps straight to the goal, which onTick applies once it is.
Function _startHairTint(Actor target, float fade)
    _clearHairTintRamp(target)
    string curKey = KEY_PREFIX + "hairtint.cur"
    bool shown = StorageUtil.StringListCount(target, KEY_PREFIX + "hairtint.instances") > 0
    if !shown && !StorageUtil.HasIntValue(target, curKey)
        _forgetHairTint(target)
        return
    endif
    if fade <= 0.0 || !target.Is3DLoaded()
        _finishHairTint(target)
        return
    endif
    int from = StorageUtil.GetIntValue(target, curKey)
    if !StorageUtil.HasIntValue(target, curKey)
        from = _hairTintOwn(target)
    endif
    StorageUtil.SetIntValue(target, KEY_PREFIX + "hairtint.from", from)
    StorageUtil.SetIntValue(target, KEY_PREFIX + "hairtint.to", _hairTintGoal(target))
    _beginRamp(target, "hairtint", fade)
EndFunction

bool Function _stepHairTint(Actor target, float now)
    float eased = _rampProgress(target, "hairtint", now)
    if eased < 0.0
        return false
    endif
    if eased >= 1.0
        _finishHairTint(target)
        return false
    endif
    if target.Is3DLoaded()
        int from = StorageUtil.GetIntValue(target, KEY_PREFIX + "hairtint.from")
        int goal = StorageUtil.GetIntValue(target, KEY_PREFIX + "hairtint.to")
        int color = _blendColor(from, goal, eased)
        StorageUtil.SetIntValue(target, KEY_PREFIX + "hairtint.cur", color)
        _applyHairTint(target, color)
    endif
    return true
EndFunction

; With no instance left, the hair's own color goes back on and the actor's color record is freed. An actor
; that isn't loaded shows its own color anyway once its 3D is built again.
Function _finishHairTint(Actor target)
    _clearHairTintRamp(target)
    string ownKey = KEY_PREFIX + "hairtint.own"
    if StorageUtil.StringListCount(target, KEY_PREFIX + "hairtint.instances") > 0
        int goal = _hairTintGoal(target)
        StorageUtil.SetIntValue(target, KEY_PREFIX + "hairtint.cur", goal)
        if target.Is3DLoaded()
            _applyHairTint(target, goal)
        endif
        Debug.Trace("[MTF_Plugin_RaceMenu] hair tint on " + _actorName(target) + ": #" + _hex(goal))
        return
    endif
    if target.Is3DLoaded() && StorageUtil.HasIntValue(target, ownKey)
        _applyHairTint(target, StorageUtil.GetIntValue(target, ownKey))
    endif
    Debug.Trace("[MTF_Plugin_RaceMenu] hair tint on " + _actorName(target) + ": none")
    _forgetHairTint(target)
EndFunction

Function _clearHairTintRamp(Actor target)
    StorageUtil.UnsetIntValue(target, KEY_PREFIX + "hairtint.from")
    StorageUtil.UnsetIntValue(target, KEY_PREFIX + "hairtint.to")
    _endRamp(target, "hairtint")
EndFunction

Function _forgetHairTint(Actor target)
    StorageUtil.UnsetIntValue(target, KEY_PREFIX + "hairtint.own")
    StorageUtil.UnsetIntValue(target, KEY_PREFIX + "hairtint.cur")
    _releaseHairTintForm(target)
EndFunction

Function _reapplyHairTint(Actor target)
    string curKey = KEY_PREFIX + "hairtint.cur"
    if StorageUtil.HasIntValue(target, curKey)
        _applyHairTint(target, StorageUtil.GetIntValue(target, curKey))
    endif
EndFunction

; Only call with the actor's 3D loaded, so the hair's own color is read before the first tint covers it.
Function _applyHairTint(Actor target, int color)
    _hairTintOwn(target)
    ColorForm record = _hairTintForm(target)
    if record != None
        record.SetColor(color)
        PO3_SKSEFunctions.SetHairColor(target, record)
    endif
EndFunction

int Function _hairTintGoal(Actor target)
    string listKey = KEY_PREFIX + "hairtint.instances"
    int n = StorageUtil.StringListCount(target, listKey)
    if n > 0
        return StorageUtil.GetIntValue(target, StorageUtil.StringListGet(target, listKey, n - 1))
    endif
    return _hairTintOwn(target)
EndFunction

; The color the hair showed before the first tint, remembered once it can be read from the loaded hair:
; the hair head part's live tint, which includes a RaceMenu hair color, else the hair color record.
int Function _hairTintOwn(Actor target)
    string ownKey = KEY_PREFIX + "hairtint.own"
    if StorageUtil.HasIntValue(target, ownKey)
        return StorageUtil.GetIntValue(target, ownKey)
    endif
    int own = 0
    if target.Is3DLoaded()
        ActorBase base = target.GetLeveledActorBase()
        if base != None
            int i = base.GetNumHeadParts()
            while i > 0 && own == 0
                i -= 1
                HeadPart part = base.GetNthHeadPart(i)
                if part != None && part.GetType() == 3 && NetImmerse.HasNode(target, part.GetPartName(), false)
                    own = _rgb(NiOverride.GetNodePropertyInt(target, false, part.GetPartName(), 7, -1))
                endif
            endwhile
        endif
    endif
    if own == 0
        own = _baseHairColor(target)
    endif
    if target.Is3DLoaded()
        StorageUtil.SetIntValue(target, ownKey, own)
    endif
    return own
EndFunction

ColorForm Function _hairTintForm(Actor target)
    string slotKey = KEY_PREFIX + "hairtint.form"
    int slot = StorageUtil.GetIntValue(target, slotKey) - 1
    if slot < 0
        slot = _claimHairTintForm(target)
        if slot < 0
            return None
        endif
        StorageUtil.SetIntValue(target, slotKey, slot + 1)
    endif
    ColorForm record = Game.GetFormFromFile(0x801 + slot, ESP_NAME) as ColorForm
    if record == None
        Debug.Trace("[MTF_Plugin_RaceMenu] hair tint: color record " + (0x801 + slot) + " is missing from " + ESP_NAME)
    endif
    return record
EndFunction

; A record is free when no actor holds it, or its holder has let go of it, such as after a reset.
int Function _claimHairTintForm(Actor target)
    int i = 0
    while i < HAIR_TINT_FORMS
        string ownerKey = KEY_PREFIX + "hairtint.owner." + i
        Form owner = StorageUtil.GetFormValue(self, ownerKey)
        if owner == None || StorageUtil.GetIntValue(owner, KEY_PREFIX + "hairtint.form") != i + 1
            StorageUtil.SetFormValue(self, ownerKey, target)
            return i
        endif
        i += 1
    endwhile
    Debug.Trace("[MTF_Plugin_RaceMenu] hair tint: all " + HAIR_TINT_FORMS + " colors are in use, so " + _actorName(target) + " keeps their hair color")
    return -1
EndFunction

Function _releaseHairTintForm(Actor target)
    string slotKey = KEY_PREFIX + "hairtint.form"
    int slot = StorageUtil.GetIntValue(target, slotKey) - 1
    if slot >= 0
        string ownerKey = KEY_PREFIX + "hairtint.owner." + slot
        if StorageUtil.GetFormValue(self, ownerKey) == target
            StorageUtil.UnsetFormValue(self, ownerKey)
        endif
    endif
    StorageUtil.UnsetIntValue(target, slotKey)
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
    Debug.Trace("[MTF_Plugin_RaceMenu] body morphs on " + _actorName(target) + ":" + applied)
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
    string[] names = new string[46]
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
    names[36] = "NippleLength"
    names[37] = "HipNarrow_v2"
    ; TNG male genitals
    names[38] = "Length"
    names[39] = "Thickness"
    names[40] = "Head"
    ; TNG ERF Futanari addon (the old SOS slider names)
    names[41] = "SOS - SchlongLength"
    names[42] = "SOS - SchlongGirth"
    names[43] = "SOS - GlansSize"
    names[44] = "SOS - BallsSize"
    names[45] = "SOS - BallsSmall"
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
    elseif shapeId == "schlong_long"
        return 16
    elseif shapeId == "schlong_thick"
        return 17
    elseif shapeId == "glans_big"
        return 18
    elseif shapeId == "balls_big"
        return 19
    elseif shapeId == "hips_narrow"
        return 20
    elseif shapeId == "thighs_thin"
        return 21
    elseif shapeId == "balls_small"
        return 22
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
        elseif slider == "NippleLength"
            return 0.5
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
    elseif shape == 16 ; schlong_long
        if slider == "Length" || slider == "SOS - SchlongLength"
            return 1.0
        endif
    elseif shape == 17 ; schlong_thick
        if slider == "Thickness" || slider == "SOS - SchlongGirth"
            return 1.0
        endif
    elseif shape == 18 ; glans_big
        if slider == "Head" || slider == "SOS - GlansSize"
            return 1.0
        endif
    elseif shape == 19 ; balls_big
        if slider == "SOS - BallsSize"
            return 1.0
        endif
    elseif shape == 20 ; hips_narrow
        if slider == "HipNarrow_v2"
            return 1.0
        endif
    elseif shape == 21 ; thighs_thin
        if slider == "SlimThighs"
            return 1.0
        elseif slider == "LegsThin"
            return 0.5
        endif
    elseif shape == 22 ; balls_small
        if slider == "SOS - BallsSmall"
            return 1.0
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
