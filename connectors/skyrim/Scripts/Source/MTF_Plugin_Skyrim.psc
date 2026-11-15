; Copyright (C) 2026 Jack Whitehouse (proteux). Licensed under the GNU General Public License v3.0 or later; see LICENSE.
Scriptname MTF_Plugin_Skyrim extends MTF_Plugin
{Magic Tattoos Framework conditions and effects for the base game, beyond what MTF's built-in plugins cover.
 No soft dependency: everything here is Skyrim, its DLC, and SKSE.
 Catalog: SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/proteux-mtf.skyrim.json

 Optional: powerofthree's Papyrus Extender (hidden, diseased, disease.cure, calm, and the nearby actors of
 spell.aura via FindAllReferencesOfFormType). Without it those entries do nothing; everything else still works.

 spell.cast and spell.aura credit the actor stored in the shared key mtf.applier.<preset> on the wearer, which
 any mod that applies presets may set, and fall back to the wearer. With Magic Tattoos UI 1.8.3 or later, the
 spell lands through its MagicTattoosUI.CastAs, so it is as strong as the applier casting it. With 1.8.6 or later,
 Spell aura fire-and-forget hits use CastAsScaled at half strength.

 MTF does not replay effects after a load, so MTF_Plugin_Skyrim_Load, on the player alias,
 calls _onGameLoaded to restore state the game does not save (the Night Eye image space, expressions)
 and to start a new session, which makes onTick play magic auras again.
 It also passes on the player's OnSpellCast. NPC casts come from their cast animation events instead.}

string Property MOD_VERSION = "0.3.4" AutoReadOnly Hidden
string Property KEY_PREFIX = "proteux-mtf.skyrim." AutoReadOnly Hidden
float Property UNITS_PER_METRE = 70.0 AutoReadOnly Hidden
float Property MIN_SHOUT_MULT = 0.05 AutoReadOnly Hidden
int Property DISEASE_SPELL_TYPE = 1 AutoReadOnly Hidden
; RE::FormType::ActorCharacter — used by FindAllReferencesOfFormType for Spell aura scans.
int Property FORM_TYPE_ACTOR = 62 AutoReadOnly Hidden
; The largest Seconds and At least the Just made a kill catalog entry allows.
float Property KILL_WINDOW_MAX = 120.0 AutoReadOnly Hidden
int Property KILL_LOG_MAX = 20 AutoReadOnly Hidden
; The largest Seconds the Just cast a spell catalog entry allows.
float Property CAST_WINDOW_MAX = 120.0 AutoReadOnly Hidden
int Property CAST_LOG_MAX = 10 AutoReadOnly Hidden
int Property CAST_WATCH_MAX = 32 AutoReadOnly Hidden
string Property INSTALL_KEY = "proteux-mtf.skyrim.install" AutoReadOnly Hidden
string Property HEAL_LIST = "proteux-mtf.skyrim.heal" AutoReadOnly Hidden
string Property APPLIER_PREFIX = "mtf.applier." AutoReadOnly Hidden
; SKSE's packed form of 1.8.3, the first Magic Tattoos UI with MagicTattoosUI.CastAs: major << 24 | minor << 16 | patch << 4.
int Property CAST_AS_MIN_UI_VERSION = 0x01080030 AutoReadOnly Hidden
; 1.8.6, the first with CastAsScaled.
int Property CAST_AS_SCALED_MIN_UI_VERSION = 0x01080060 AutoReadOnly Hidden
; Its spells put presets on, so a tier casting one could keep putting its own preset back on.
string Property TACTICAL_PLUGIN = "MagicTattoosTactical.esp" AutoReadOnly Hidden
; On each wearer, the instance keys of its shown spell auras / repeating casts. On the player, every wearer with one.
string Property SPELL_AURA_KEYS = "proteux-mtf.skyrim.spellaura.keys" AutoReadOnly Hidden
string Property SPELL_AURA_WEARERS = "proteux-mtf.skyrim.spellaura.wearers" AutoReadOnly Hidden
string Property SPELL_CAST_KEYS = "proteux-mtf.skyrim.spellcast.keys" AutoReadOnly Hidden
string Property SPELL_CAST_WEARERS = "proteux-mtf.skyrim.spellcast.wearers" AutoReadOnly Hidden
string Property SPELL_TICK = "proteux-mtf.skyrim.spell.tick" AutoReadOnly Hidden
; How often the player alias wakes to check due casts and auras.
float Property SPELL_TICK_INTERVAL = 0.25 AutoReadOnly Hidden
; Spell aura pulses at this spacing; cast intervals use the spell's cast time (floored below).
float Property SPELL_AURA_INTERVAL = 1.0 AutoReadOnly Hidden
float Property SPELL_CAST_MIN_INTERVAL = 0.5 AutoReadOnly Hidden
float Property SPELL_AURA_FF_SCALE = 0.5 AutoReadOnly Hidden
int Property EFFECT_FLAG_HOSTILE = 0x00000001 AutoReadOnly Hidden
; MagicEffect.GetCastingType / GetDeliveryType.
int Property CASTING_FIRE_AND_FORGET = 1 AutoReadOnly Hidden
int Property CASTING_CONCENTRATION = 2 AutoReadOnly Hidden
int Property DELIVERY_SELF = 0 AutoReadOnly Hidden

Actor Property PlayerRef Auto Hidden
; Set to 1 from the console (setpqv MTF_Plugin_Skyrim ResetOnLoad 1); the next save load undoes every
; change this plugin's effects made and sets it back to 0. Skyrim's console can't call a script function directly.
int Property ResetOnLoad = 0 Auto Hidden
; Picked on first use and stamped on every actor this plugin's effects touch. A save loaded without the plugin
; loses it, so a new one is picked when the plugin comes back, and actors stamped with the old one are found stale.
int Property InstallId = 0 Auto Hidden
string Property ResolvedVersion Auto Hidden
GlobalVariable Property GameMonth Auto Hidden
GlobalVariable Property GameDay Auto Hidden
GlobalVariable Property GameDaysPassed Auto Hidden
Faction[] Property HoldCrimeFactions Auto Hidden
Location[] Property HoldLocations Auto Hidden
Keyword[] Property CraftKeywords Auto Hidden
int[] Property CraftGroups Auto Hidden
Spell[] Property RestedSpells Auto Hidden
ImageSpaceModifier Property NightEyeFX Auto Hidden
Perk Property NoFallDamagePerk Auto Hidden

string Function GetPluginId()
    return "proteux-mtf.skyrim"
EndFunction

bool Function _resolveDeps()
    if ResolvedVersion == MOD_VERSION
        return true
    endif
    GameMonth = Game.GetFormFromFile(0x000036, "Skyrim.esm") as GlobalVariable
    GameDay = Game.GetFormFromFile(0x000037, "Skyrim.esm") as GlobalVariable
    GameDaysPassed = Game.GetFormFromFile(0x000039, "Skyrim.esm") as GlobalVariable

    HoldCrimeFactions = new Faction[10]
    HoldLocations = new Location[10]
    _setHold(0, 0x0267EA, 0x016772, "Skyrim.esm") ; Whiterun
    _setHold(1, 0x029DB0, 0x016770, "Skyrim.esm") ; Haafingar
    _setHold(2, 0x028170, 0x01676F, "Skyrim.esm") ; Falkreath
    _setHold(3, 0x02816D, 0x01676E, "Skyrim.esm") ; Hjaalmarch
    _setHold(4, 0x02816E, 0x01676D, "Skyrim.esm") ; The Pale
    _setHold(5, 0x02816B, 0x01676C, "Skyrim.esm") ; The Rift
    _setHold(6, 0x02816F, 0x01676B, "Skyrim.esm") ; Winterhold
    _setHold(7, 0x0267E3, 0x01676A, "Skyrim.esm") ; Eastmarch
    _setHold(8, 0x02816C, 0x016769, "Skyrim.esm") ; The Reach
    _setHold(9, 0x018279, 0x016E2A, "Dragonborn.esm") ; Solstheim (Raven Rock)

    ; Groups match _craftGroup.
    CraftKeywords = new Keyword[13]
    CraftGroups = new int[13]
    _setCraft(0, 0x088105, "Skyrim.esm", 0) ; CraftingSmithingForge
    _setCraft(1, 0x0F46CE, "Skyrim.esm", 0) ; CraftingSmithingSkyforge
    _setCraft(2, 0x005756, "Dawnguard.esm", 0) ; DLC1LD_CraftingForgeAetherium
    _setCraft(3, 0x0ADB78, "Skyrim.esm", 1) ; CraftingSmithingArmorTable
    _setCraft(4, 0x088108, "Skyrim.esm", 2) ; CraftingSmithingSharpeningWheel
    _setCraft(5, 0x0A5CCE, "Skyrim.esm", 3) ; CraftingSmelter
    _setCraft(6, 0x07866A, "Skyrim.esm", 4) ; CraftingTanningRack
    _setCraft(7, 0x0A5CB3, "Skyrim.esm", 5) ; CraftingCookpot
    _setCraft(8, 0x068ADA, "Skyrim.esm", 5) ; isCookingSpit
    _setCraft(9, 0x1010B2, "Skyrim.esm", 5) ; isSmallCookingPot
    _setCraft(10, 0x02A40B, "Skyrim.esm", 6) ; isAlchemy
    _setCraft(11, 0x06E2A3, "Skyrim.esm", 7) ; isEnchanting
    _setCraft(12, 0x017738, "Dragonborn.esm", 7) ; DLC2StaffEnchanter

    ; Indexes match _restedIndex.
    RestedSpells = new Spell[3]
    RestedSpells[0] = Game.GetFormFromFile(0x0FB981, "Skyrim.esm") as Spell ; Rested
    RestedSpells[1] = Game.GetFormFromFile(0x0FB984, "Skyrim.esm") as Spell ; WellRested
    RestedSpells[2] = Game.GetFormFromFile(0x0CDA1D, "Skyrim.esm") as Spell ; MarriageRested (Lover's Comfort)

    NightEyeFX = Game.GetFormFromFile(0x06B108, "Skyrim.esm") as ImageSpaceModifier ; MagicNightEyeMainFX
    NoFallDamagePerk = Game.GetFormFromFile(0x01E801, "Dragonborn.esm") as Perk ; DLC2BlackBookNoFallingDamagePerk
    PlayerRef = Game.GetPlayer()
    ; Set last: it is the "resolved" marker checked above.
    ResolvedVersion = MOD_VERSION
    return true
EndFunction

Function _setHold(int i, int factionId, int locationId, string file)
    HoldCrimeFactions[i] = Game.GetFormFromFile(factionId, file) as Faction
    HoldLocations[i] = Game.GetFormFromFile(locationId, file) as Location
EndFunction

Function _setCraft(int i, int keywordId, string file, int group)
    CraftKeywords[i] = Game.GetFormFromFile(keywordId, file) as Keyword
    CraftGroups[i] = group
EndFunction

Function _onRegistered()
    Debug.Trace("[MTF_Plugin_Skyrim] " + MOD_VERSION + " registered as " + GetPluginId())
    _replaceStale(_host())
    _sweep()
EndFunction

; _tryRegister does nothing once _registered is set, so a plugin missing from MTF's list would never be called
; again. Registers anew when MTF no longer lists this plugin.
Function _checkRegistered()
    MTF_MainQuest host = _host()
    if host == None || _replaceStale(host)
        return
    endif
    if !_registered || host.FindPlugin(GetPluginId()) == self
        return
    endif
    Debug.Trace("[MTF_Plugin_Skyrim] MTF had lost this plugin, so it registers again")
    _registered = false
    _tryRegister()
EndFunction

; A save can keep a copy of this script whose quest is gone, from an earlier install. MTF lists it under this
; plugin's id, so it calls that copy, which does nothing, and won't register this one. Puts this one in its place.
bool Function _replaceStale(MTF_MainQuest host)
    if host == None
        return false
    endif
    int idx = host.FindPluginIndex(GetPluginId())
    if idx < 0 || host.FindPlugin(GetPluginId()) == self
        return false
    endif
    Form[] plugins = host.registeredPlugins
    plugins[idx] = self
    _registered = true
    Debug.Trace("[MTF_Plugin_Skyrim] MTF listed a copy of this plugin left from an earlier install, so it lists this one instead")
    return true
EndFunction

Function _onGameLoaded()
    _resolveDeps()
    _checkRegistered()
    StorageUtil.AdjustIntValue(PlayerRef, KEY_PREFIX + "session", 1)
    if ResetOnLoad != 0
        ResetOnLoad = 0
        _resetAll()
    else
        _sweep()
    endif
    if NightEyeFX != None && StorageUtil.GetIntValue(PlayerRef, KEY_PREFIX + "nighteye.count") > 0
        NightEyeFX.ApplyCrossFade(1.0)
    endif
    _applyMood(PlayerRef, false)
    StorageUtil.UnsetFloatValue(PlayerRef, KEY_PREFIX + "kills.base")
    StorageUtil.FloatListClear(PlayerRef, KEY_PREFIX + "kills.times")
    _clearCasts(PlayerRef)
    string watchKey = KEY_PREFIX + "cast.watched"
    int i = StorageUtil.FormListCount(PlayerRef, watchKey)
    while i > 0
        i -= 1
        Actor npc = StorageUtil.FormListGet(PlayerRef, watchKey, i) as Actor
        if npc != None
            _clearCasts(npc)
        endif
    endwhile
    StorageUtil.FormListClear(PlayerRef, watchKey)
    StorageUtil.UnsetFloatValue(PlayerRef, SPELL_TICK)
    if StorageUtil.FormListCount(PlayerRef, SPELL_AURA_WEARERS) > 0 || StorageUtil.FormListCount(PlayerRef, SPELL_CAST_WEARERS) > 0
        _startSpellTick()
    endif
EndFunction

; ── Conditions ──────────────────────────────────────────────────────────────

bool Function checkCondition(Actor target, int param, string cid)
    if target == None || PlayerRef == None
        return false
    endif
    if cid == "stat"
        if target != PlayerRef
            return false
        endif
        string statName = _statName(_host().GetEvalParamStr())
        return statName != "" && Game.QueryStat(statName) >= _host().GetEvalParam2()
    elseif cid == "moon.phase"
        return _moonMatches(_moonPhase(), _host().GetEvalParamStr())
    elseif cid == "darkness"
        return target.GetLightLevel() < param as float
    elseif cid == "season"
        return _seasonOf(GameMonth.GetValueInt()) == _host().GetEvalParamStr()
    elseif cid == "holiday"
        string today = _holidayOn(GameMonth.GetValueInt(), GameDay.GetValueInt())
        string wanted = _host().GetEvalParamStr()
        return today != "" && (wanted == "any" || wanted == today)
    elseif cid == "bounty"
        if target != PlayerRef
            return false
        endif
        Faction crime = _currentHoldCrime(target)
        return crime != None && crime.GetCrimeGold() >= param
    elseif cid == "wanted"
        return target == PlayerRef && _wantedAnywhere(param)
    elseif cid == "hidden"
        return target.IsSneaking() && !_isDetected(target)
    elseif cid == "sitting"
        return target.GetSitState() == 3
    elseif cid == "sleeping"
        return target.GetSleepState() == 3
    elseif cid == "crafting"
        return _craftingMatches(target, _craftGroup(_host().GetEvalParamStr()))
    elseif cid == "diseased"
        return _countDiseases(target, false) > 0
    elseif cid == "kill.recent"
        if target != PlayerRef
            return false
        endif
        int wanted = _host().GetEvalParam2()
        if wanted < 1
            wanted = 1
        endif
        return _recentKills(param as float) >= wanted
    elseif cid == "levelup.recent"
        return _transientIncrease(target, "level", target.GetLevel() as float, param as float)
    elseif cid == "spell.equipped"
        string[] wanted = StringUtil.Split(_host().GetEvalParamStr(), ",")
        bool contains = _host().GetEvalParam2Str() == "contains"
        return _inHands(target, wanted, contains, "")
    elseif cid == "spell.school.equipped"
        ; Unassigned rather than a None literal, which fails to cast to string[] at runtime.
        string[] noNames
        return _inHands(target, noNames, false, _host().GetEvalParamStr())
    elseif cid == "spell.cast.recent"
        ; All read before _watchCasts, whose calls wait a frame while another evaluation can reset them.
        string[] wanted = StringUtil.Split(_host().GetEvalParamStr(), ",")
        bool contains = _host().GetEvalParam2Str() == "contains"
        float windowSec = _host().GetEvalParam3() as float
        if target != PlayerRef
            _watchCasts(target)
        endif
        return _castWithin(target, wanted, contains, "", windowSec)
    elseif cid == "spell.school.cast.recent"
        string school = _host().GetEvalParamStr()
        float windowSec = _host().GetEvalParam2() as float
        if target != PlayerRef
            _watchCasts(target)
        endif
        string[] noNames
        return _castWithin(target, noNames, false, school, windowSec)
    endif
    return false
EndFunction

; ── Spell casts ─────────────────────────────────────────────────────────────

; NPCs' casts are seen through BeginCastLeft and BeginCastRight, registered the first time a Just cast
; tier checks them. Registrations can be lost when the NPC unloads or a save loads, so every check
; renews them. A cast before the first check is not seen.
Function _watchCasts(Actor npc)
    string watchKey = KEY_PREFIX + "cast.watched"
    if StorageUtil.FormListAdd(PlayerRef, watchKey, npc, false) >= CAST_WATCH_MAX
        ObjectReference oldest = StorageUtil.FormListGet(PlayerRef, watchKey, 0) as ObjectReference
        StorageUtil.FormListRemoveAt(PlayerRef, watchKey, 0)
        if oldest != None
            UnregisterForAnimationEvent(oldest, "BeginCastLeft")
            UnregisterForAnimationEvent(oldest, "BeginCastRight")
        endif
    endif
    RegisterForAnimationEvent(npc, "BeginCastLeft")
    RegisterForAnimationEvent(npc, "BeginCastRight")
EndFunction

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
    Actor caster = akSource as Actor
    if caster == None
        return
    endif
    int hand = 1
    if asEventName == "BeginCastLeft"
        hand = 0
    elseif asEventName != "BeginCastRight"
        return
    endif
    Spell cast = caster.GetEquippedSpell(hand)
    if cast != None
        _logCast(caster, cast)
    endif
EndEvent

; Each caster keeps its last casts as parallel spell and real-time lists, shared by every tier.
Function _logCast(Actor caster, Spell cast)
    if caster == None || cast == None
        return
    endif
    float now = Utility.GetCurrentRealTime()
    _pruneCasts(caster, now)
    StorageUtil.FormListAdd(caster, KEY_PREFIX + "cast.spells", cast)
    StorageUtil.FloatListAdd(caster, KEY_PREFIX + "cast.times", now)
    _pruneCasts(caster, now)
EndFunction

bool Function _castWithin(Actor caster, string[] names, bool contains, string school, float windowSec)
    if windowSec <= 0.0
        windowSec = 10.0
    endif
    float now = Utility.GetCurrentRealTime()
    _pruneCasts(caster, now)
    string spellsKey = KEY_PREFIX + "cast.spells"
    string timesKey = KEY_PREFIX + "cast.times"
    int i = StorageUtil.FloatListCount(caster, timesKey) - 1
    while i >= 0 && StorageUtil.FloatListGet(caster, timesKey, i) >= now - windowSec
        if _spellMatches(StorageUtil.FormListGet(caster, spellsKey, i) as Spell, names, contains, school)
            return true
        endif
        i -= 1
    endwhile
    return false
EndFunction

; Drops casts older than the longest window and past the cap. Lists that disagree in length, or a time ahead
; of now (real time restarts on load), start over.
Function _pruneCasts(Actor caster, float now)
    string spellsKey = KEY_PREFIX + "cast.spells"
    string timesKey = KEY_PREFIX + "cast.times"
    int n = StorageUtil.FloatListCount(caster, timesKey)
    if n != StorageUtil.FormListCount(caster, spellsKey) || (n > 0 && StorageUtil.FloatListGet(caster, timesKey, n - 1) > now + 1.0)
        _clearCasts(caster)
        return
    endif
    while n > CAST_LOG_MAX || (n > 0 && StorageUtil.FloatListGet(caster, timesKey, 0) < now - CAST_WINDOW_MAX)
        StorageUtil.FloatListRemoveAt(caster, timesKey, 0)
        StorageUtil.FormListRemoveAt(caster, spellsKey, 0)
        n -= 1
    endwhile
EndFunction

Function _clearCasts(Actor caster)
    StorageUtil.FormListClear(caster, KEY_PREFIX + "cast.spells")
    StorageUtil.FloatListClear(caster, KEY_PREFIX + "cast.times")
EndFunction

bool Function _inHands(Actor target, string[] names, bool contains, string school) global
    return _spellMatches(target.GetEquippedSpell(0), names, contains, school) || _spellMatches(target.GetEquippedSpell(1), names, contains, school)
EndFunction

; By school when one is given, otherwise by name. "any" is any spell with a school, so not a power.
bool Function _spellMatches(Spell candidate, string[] names, bool contains, string school) global
    if candidate == None
        return false
    elseif school == ""
        return _nameIn(candidate.GetName(), names, contains)
    endif
    string actual = _schoolOf(candidate)
    return actual != "" && (school == "any" || school == actual)
EndFunction

; The school of the costliest effect, as the game picks it for skill experience. Papyrus compares strings
; without case, so the menu id "destruction" matches "Destruction".
string Function _schoolOf(Spell candidate) global
    MagicEffect costliest = candidate.GetNthEffectMagicEffect(candidate.GetCostliestEffectIndex())
    if costliest == None
        return ""
    endif
    string skill = costliest.GetAssociatedSkill()
    if skill == "Alteration" || skill == "Conjuration" || skill == "Destruction" || skill == "Illusion" || skill == "Restoration"
        return skill
    endif
    return ""
EndFunction

; Papyrus compares strings without case, so "flames" matches Flames.
bool Function _nameIn(string spellName, string[] wanted, bool contains) global
    if spellName == "" || !wanted
        return false
    endif
    int i = 0
    while i < wanted.Length
        string want = _trim(wanted[i])
        if want != ""
            if contains
                if StringUtil.Find(spellName, want) >= 0
                    return true
                endif
            elseif want == spellName
                return true
            endif
        endif
        i += 1
    endwhile
    return false
EndFunction

string Function _trim(string s) global
    int last = StringUtil.GetLength(s) - 1
    int first = 0
    while first <= last && StringUtil.GetNthChar(s, first) == " "
        first += 1
    endwhile
    while last >= first && StringUtil.GetNthChar(s, last) == " "
        last -= 1
    endwhile
    if last < first
        return ""
    endif
    ; Substring reads a length of 0 as "to the end", but last >= first keeps it at 1 or more.
    return StringUtil.Substring(s, first, last - first + 1)
EndFunction

; Masser's cycle as the game draws it: 24 days, 3 per phase, full moon on day 0.
; 0 full, 1-3 waning, 4 new, 5-7 waxing.
int Function _moonPhase()
    int day = Math.Floor(GameDaysPassed.GetValue() - 0.5) % 24
    if day < 0
        day += 24
    endif
    return day / 3
EndFunction

bool Function _moonMatches(int phase, string wanted) global
    if wanted == "waxing"
        return phase >= 5
    elseif wanted == "waning"
        return phase >= 1 && phase <= 3
    endif
    return wanted == _moonPhaseId(phase)
EndFunction

string Function _moonPhaseId(int phase) global
    if phase == 0
        return "full"
    elseif phase == 1
        return "waning_gibbous"
    elseif phase == 2
        return "waning_half"
    elseif phase == 3
        return "waning_crescent"
    elseif phase == 4
        return "new"
    elseif phase == 5
        return "waxing_crescent"
    elseif phase == 6
        return "waxing_half"
    elseif phase == 7
        return "waxing_gibbous"
    endif
    return ""
EndFunction

; GameMonth is 0-based: 0 is Morning Star (January).
string Function _seasonOf(int month) global
    if month == 11 || month <= 1
        return "winter"
    elseif month <= 4
        return "spring"
    elseif month <= 7
        return "summer"
    endif
    return "autumn"
EndFunction

; Holidays from the in-game calendar (UESP Lore:Holidays). GameMonth is 0-based, GameDay 1-based.
string Function _holidayOn(int month, int day) global
    int date = month * 100 + day
    if date == 1
        return "new_life"
    elseif date == 13
        return "meridia"
    elseif date == 15
        return "south_winds_prayer"
    elseif date == 116
        return "hearts_day"
    elseif date == 205
        return "hermaeus_mora"
    elseif date == 207
        return "first_planting"
    elseif date == 309
        return "peryite"
    elseif date == 328
        return "jesters_festival"
    elseif date == 407
        return "second_planting"
    elseif date == 505
        return "hircine"
    elseif date == 516
        return "mid_year"
    elseif date == 610
        return "merchants_festival"
    elseif date == 620
        return "suns_rest"
    elseif date == 727
        return "harvests_end"
    elseif date == 803
        return "tales_and_tallows"
    elseif date == 908
        return "malacath"
    elseif date == 913
        return "witches_festival"
    elseif date == 930
        return "emperors_day"
    elseif date == 1020
        return "warriors_festival"
    elseif date == 1115
        return "north_winds_prayer"
    elseif date == 1125
        return "saturalia"
    elseif date == 1131
        return "old_life"
    endif
    return ""
EndFunction

; The hold whose location contains the actor's current location. Unnamed wilderness has no location.
Faction Function _currentHoldCrime(Actor target)
    Location here = target.GetCurrentLocation()
    if here == None
        return None
    endif
    int i = 0
    while i < HoldLocations.Length
        Location hold = HoldLocations[i]
        if hold != None && (here == hold || here.IsChild(hold))
            return HoldCrimeFactions[i]
        endif
        i += 1
    endwhile
    return None
EndFunction

bool Function _wantedAnywhere(int atLeast)
    if atLeast < 1
        atLeast = 1
    endif
    int i = 0
    while i < HoldCrimeFactions.Length
        Faction crime = HoldCrimeFactions[i]
        if crime != None && crime.GetCrimeGold() >= atLeast
            return true
        endif
        i += 1
    endwhile
    return false
EndFunction

; Any living actor in high process that has detected the target. The player's followers do not count.
; Without Papyrus Extender the list is None and the target never counts as hidden.
bool Function _isDetected(Actor target)
    Actor[] nearby = PO3_SKSEFunctions.GetActorsByProcessingLevel(0)
    if !nearby
        return true
    endif
    bool skipTeammates = target == PlayerRef
    int i = 0
    while i < nearby.Length
        Actor other = nearby[i]
        if other != None && other != target && !other.IsDead()
            if !(skipTeammates && other.IsPlayerTeammate()) && target.IsDetectedBy(other)
                return true
            endif
        endif
        i += 1
    endwhile
    return false
EndFunction

; -2 for an unknown id, -1 for "any".
int Function _craftGroup(string groupId) global
    if groupId == "any"
        return -1
    elseif groupId == "forge"
        return 0
    elseif groupId == "workbench"
        return 1
    elseif groupId == "grindstone"
        return 2
    elseif groupId == "smelter"
        return 3
    elseif groupId == "tanning_rack"
        return 4
    elseif groupId == "cooking"
        return 5
    elseif groupId == "alchemy"
        return 6
    elseif groupId == "enchanting"
        return 7
    endif
    return -2
EndFunction

bool Function _craftingMatches(Actor target, int group)
    if group < -1
        return false
    endif
    ObjectReference furniture = target.GetFurnitureReference()
    if furniture == None
        return false
    endif
    Form furnitureBase = furniture.GetBaseObject()
    if furnitureBase == None
        return false
    endif
    int i = 0
    while i < CraftKeywords.Length
        Keyword kw = CraftKeywords[i]
        if kw != None && (group == -1 || CraftGroups[i] == group) && furnitureBase.HasKeyword(kw)
            return true
        endif
        i += 1
    endwhile
    return false
EndFunction

; Diseases are added spells of the disease type. With remove set, cures them and returns how many.
int Function _countDiseases(Actor target, bool remove)
    Spell[] found = new Spell[128]
    int foundCount = 0
    int i = target.GetSpellCount()
    while i > 0 && foundCount < found.Length
        i -= 1
        Spell sp = target.GetNthSpell(i)
        if sp != None && PO3_SKSEFunctions.GetSpellType(sp) == DISEASE_SPELL_TYPE
            found[foundCount] = sp
            foundCount += 1
        endif
    endwhile
    if remove
        i = 0
        while i < foundCount
            target.RemoveSpell(found[i])
            i += 1
        endwhile
    endif
    return foundCount
EndFunction

float Function _killCount()
    int kills = Game.QueryStat("People Killed") + Game.QueryStat("Animals Killed") + Game.QueryStat("Creatures Killed")
    kills += Game.QueryStat("Undead Killed") + Game.QueryStat("Daedra Killed") + Game.QueryStat("Automatons Killed")
    return kills as float
EndFunction

; The player's kills in the last windowSec real seconds. A poll that sees the kill count rise logs one
; time per new kill. The log is shared by every tier, so it only drops times older than the longest
; window. The first poll after a load only sets the baseline, and a time ahead of now is left over from
; an earlier session (real time restarts on load), so the log starts over.
int Function _recentKills(float windowSec)
    if windowSec <= 0.0
        windowSec = 10.0
    endif
    string baseKey = KEY_PREFIX + "kills.base"
    string logKey = KEY_PREFIX + "kills.times"
    float now = Utility.GetCurrentRealTime()
    float current = _killCount()
    float prev = StorageUtil.GetFloatValue(PlayerRef, baseKey, -1.0)
    StorageUtil.SetFloatValue(PlayerRef, baseKey, current)
    int n = StorageUtil.FloatListCount(PlayerRef, logKey)
    if n > 0 && StorageUtil.FloatListGet(PlayerRef, logKey, n - 1) > now + 1.0
        StorageUtil.FloatListClear(PlayerRef, logKey)
    endif
    if prev >= 0.0 && current > prev
        int added = (current - prev) as int
        if added > KILL_LOG_MAX
            added = KILL_LOG_MAX
        endif
        while added > 0
            StorageUtil.FloatListAdd(PlayerRef, logKey, now)
            added -= 1
        endwhile
    endif
    n = StorageUtil.FloatListCount(PlayerRef, logKey)
    while n > KILL_LOG_MAX || (n > 0 && StorageUtil.FloatListGet(PlayerRef, logKey, 0) < now - KILL_WINDOW_MAX)
        StorageUtil.FloatListRemoveAt(PlayerRef, logKey, 0)
        n -= 1
    endwhile
    int count = 0
    int i = n - 1
    while i >= 0 && StorageUtil.FloatListGet(PlayerRef, logKey, i) >= now - windowSec
        count += 1
        i -= 1
    endwhile
    return count
EndFunction

; Same contract as MTF_Plugin_Base._checkTransientIncrease: the first poll only sets a baseline, a rise
; opens a window of sustainSec real seconds, and a window further out than one full length is left over
; from an earlier session (real time restarts on load), so it re-baselines instead of firing.
bool Function _transientIncrease(Actor target, string name, float current, float sustainSec)
    if sustainSec <= 0.0
        sustainSec = 5.0
    endif
    string baseKey = KEY_PREFIX + "transient." + name + ".base"
    string armKey = KEY_PREFIX + "transient." + name + ".until"
    float now = Utility.GetCurrentRealTime()
    float armUntil = StorageUtil.GetFloatValue(target, armKey, 0.0)
    if armUntil > now + sustainSec + 1.0
        StorageUtil.SetFloatValue(target, baseKey, current)
        StorageUtil.UnsetFloatValue(target, armKey)
        return false
    endif
    float prev = StorageUtil.GetFloatValue(target, baseKey, -1.0)
    if prev < 0.0
        StorageUtil.SetFloatValue(target, baseKey, current)
        return false
    elseif current > prev
        StorageUtil.SetFloatValue(target, baseKey, current)
        armUntil = now + sustainSec
        StorageUtil.SetFloatValue(target, armKey, armUntil)
    endif
    return now < armUntil
EndFunction

; Names as Game.QueryStat expects them, which are the names on the General Stats page.
string Function _statName(string statId) global
    if statId == "locations_discovered"
        return "Locations Discovered"
    elseif statId == "dungeons_cleared"
        return "Dungeons Cleared"
    elseif statId == "days_passed"
        return "Days Passed"
    elseif statId == "hours_slept"
        return "Hours Slept"
    elseif statId == "hours_waiting"
        return "Hours Waiting"
    elseif statId == "standing_stones"
        return "Standing Stones Found"
    elseif statId == "gold_found"
        return "Gold Found"
    elseif statId == "most_gold"
        return "Most Gold Carried"
    elseif statId == "chests_looted"
        return "Chests Looted"
    elseif statId == "horses_owned"
        return "Horses Owned"
    elseif statId == "houses_owned"
        return "Houses Owned"
    elseif statId == "stores_invested"
        return "Stores Invested In"
    elseif statId == "skill_increases"
        return "Skill Increases"
    elseif statId == "skill_books"
        return "Skill Books Read"
    elseif statId == "books_read"
        return "Books Read"
    elseif statId == "food_eaten"
        return "Food Eaten"
    elseif statId == "training_sessions"
        return "Training Sessions"
    elseif statId == "barters"
        return "Barters"
    elseif statId == "persuasions"
        return "Persuasions"
    elseif statId == "bribes"
        return "Bribes"
    elseif statId == "intimidations"
        return "Intimidations"
    elseif statId == "diseases"
        return "Diseases Contracted"
    elseif statId == "days_vampire"
        return "Days as a Vampire"
    elseif statId == "days_werewolf"
        return "Days as a Werewolf"
    elseif statId == "necks_bitten"
        return "Necks Bitten"
    elseif statId == "vampirism_cures"
        return "Vampirism Cures"
    elseif statId == "werewolf_transformations"
        return "Werewolf Transformations"
    elseif statId == "mauls"
        return "Mauls"
    elseif statId == "quests"
        return "Quests Completed"
    elseif statId == "misc_objectives"
        return "Misc Objectives Completed"
    elseif statId == "quests_main"
        return "Main Quests Completed"
    elseif statId == "quests_side"
        return "Side Quests Completed"
    elseif statId == "quests_companions"
        return "The Companions Quests Completed"
    elseif statId == "quests_college"
        return "College of Winterhold Quests Completed"
    elseif statId == "quests_thieves"
        return "Thieves' Guild Quests Completed"
    elseif statId == "quests_brotherhood"
        return "The Dark Brotherhood Quests Completed"
    elseif statId == "quests_civil_war"
        return "Civil War Quests Completed"
    elseif statId == "quests_daedric"
        return "Daedric Quests Completed"
    elseif statId == "quests_dawnguard"
        return "Dawnguard Quests Completed"
    elseif statId == "quests_dragonborn"
        return "Dragonborn Quests Completed"
    elseif statId == "questlines"
        return "Questlines Completed"
    elseif statId == "people_killed"
        return "People Killed"
    elseif statId == "animals_killed"
        return "Animals Killed"
    elseif statId == "creatures_killed"
        return "Creatures Killed"
    elseif statId == "undead_killed"
        return "Undead Killed"
    elseif statId == "daedra_killed"
        return "Daedra Killed"
    elseif statId == "automatons_killed"
        return "Automatons Killed"
    elseif statId == "bunnies"
        return "Bunnies Slaughtered"
    elseif statId == "critical_strikes"
        return "Critical Strikes"
    elseif statId == "sneak_attacks"
        return "Sneak Attacks"
    elseif statId == "backstabs"
        return "Backstabs"
    elseif statId == "weapons_disarmed"
        return "Weapons Disarmed"
    elseif statId == "brawls_won"
        return "Brawls Won"
    elseif statId == "spells_learned"
        return "Spells Learned"
    elseif statId == "dragon_souls"
        return "Dragon Souls Collected"
    elseif statId == "words_of_power"
        return "Words Of Power Unlocked"
    elseif statId == "shouts_learned"
        return "Shouts Learned"
    elseif statId == "shouts_mastered"
        return "Shouts Mastered"
    elseif statId == "times_shouted"
        return "Times Shouted"
    elseif statId == "soul_gems_used"
        return "Soul Gems Used"
    elseif statId == "souls_trapped"
        return "Souls Trapped"
    elseif statId == "magic_items_made"
        return "Magic Items Made"
    elseif statId == "weapons_improved"
        return "Weapons Improved"
    elseif statId == "weapons_made"
        return "Weapons Made"
    elseif statId == "armor_improved"
        return "Armor Improved"
    elseif statId == "armor_made"
        return "Armor Made"
    elseif statId == "potions_mixed"
        return "Potions Mixed"
    elseif statId == "potions_used"
        return "Potions Used"
    elseif statId == "poisons_mixed"
        return "Poisons Mixed"
    elseif statId == "poisons_used"
        return "Poisons Used"
    elseif statId == "ingredients_harvested"
        return "Ingredients Harvested"
    elseif statId == "ingredients_eaten"
        return "Ingredients Eaten"
    elseif statId == "nirnroots_found"
        return "Nirnroots Found"
    elseif statId == "wings_plucked"
        return "Wings Plucked"
    elseif statId == "total_bounty"
        return "Total Lifetime Bounty"
    elseif statId == "largest_bounty"
        return "Largest Bounty"
    elseif statId == "locks_picked"
        return "Locks Picked"
    elseif statId == "pockets_picked"
        return "Pockets Picked"
    elseif statId == "items_pickpocketed"
        return "Items Pickpocketed"
    elseif statId == "times_jailed"
        return "Times Jailed"
    elseif statId == "days_jailed"
        return "Days Jailed"
    elseif statId == "fines_paid"
        return "Fines Paid"
    elseif statId == "jail_escapes"
        return "Jail Escapes"
    elseif statId == "items_stolen"
        return "Items Stolen"
    elseif statId == "assaults"
        return "Assaults"
    elseif statId == "murders"
        return "Murders"
    elseif statId == "horses_stolen"
        return "Horses Stolen"
    elseif statId == "trespasses"
        return "Trespasses"
    endif
    return ""
EndFunction

; ── Effects ─────────────────────────────────────────────────────────────────

Function onActivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None
        return
    endif
    _checkInstall(target)
    string instKey = _instanceKey(eid, slot, effectIdx)
    StorageUtil.StringListRemove(target, HEAL_LIST, instKey, true)
    if eid == "disease.cure"
        _countDiseases(target, true)
    elseif eid == "calm"
        _calmAround(target, param as float * UNITS_PER_METRE)
    elseif eid == "weather"
        if target == PlayerRef
            Weather sky = _weatherForm(_paramNStrEx(slot, effectIdx, useScratch, presetName, 1))
            if sky != None
                sky.SetActive(false, true)
            endif
        endif
    elseif eid == "xp.grant"
        if target == PlayerRef && param > 0
            float needed = Game.GetExperienceForLevel(PlayerRef.GetLevel())
            Game.SetPlayerExperience(Game.GetPlayerExperience() + needed * param as float / 100.0)
        endif
    elseif eid == "vision.night"
        if target != PlayerRef || NightEyeFX == None || !_claim(target, instKey, 0)
            return
        endif
        if StorageUtil.AdjustIntValue(PlayerRef, KEY_PREFIX + "nighteye.count", 1) == 1
            NightEyeFX.ApplyCrossFade(1.0)
        endif
    elseif eid == "shout.recovery"
        if param <= 0 || StorageUtil.HasFloatValue(target, instKey)
            return
        endif
        ; Claimed before GetActorValue suspends, so a second dispatch of this instance stops above.
        StorageUtil.SetFloatValue(target, instKey, 0.0)
        float current = target.GetActorValue("ShoutRecoveryMult")
        float delta = param as float / 100.0 - 1.0
        if current + delta < MIN_SHOUT_MULT
            delta = MIN_SHOUT_MULT - current
        endif
        StorageUtil.SetFloatValue(target, instKey, delta)
        target.ModActorValue("ShoutRecoveryMult", delta)
    elseif eid == "rested"
        int restedIdx = _restedIndex(_paramNStrEx(slot, effectIdx, useScratch, presetName, 1))
        if restedIdx < 0 || RestedSpells[restedIdx] == None || !_claim(target, instKey, restedIdx)
            return
        endif
        StorageUtil.AdjustIntValue(target, _restedKey(restedIdx, "count"), 1)
        _ensureRested(target, restedIdx)
    elseif eid == "mood"
        int mood = _moodIndex(_paramNStrEx(slot, effectIdx, useScratch, presetName, 1))
        if mood < 0 || !_claim(target, instKey, mood * 1000 + _clampInt(param2, 0, 100))
            return
        endif
        StorageUtil.StringListAdd(target, KEY_PREFIX + "mood.instances", instKey, false)
        _applyMood(target, true)
    elseif eid == "fall.nodamage"
        if target != PlayerRef || NoFallDamagePerk == None || !_claim(target, instKey, 0)
            return
        endif
        if StorageUtil.AdjustIntValue(target, KEY_PREFIX + "fall.count", 1) == 1 && !target.HasPerk(NoFallDamagePerk)
            StorageUtil.SetIntValue(target, KEY_PREFIX + "fall.added", 1)
            target.AddPerk(NoFallDamagePerk)
        endif
    elseif eid == "aura"
        if StorageUtil.HasStringValue(target, instKey)
            return
        endif
        string auraId = _paramNStrEx(slot, effectIdx, useScratch, presetName, 1)
        StorageUtil.SetStringValue(target, instKey, auraId)
        EffectShader shader = _auraShader(auraId)
        if shader == None
            StorageUtil.UnsetStringValue(target, instKey)
            return
        endif
        if StorageUtil.AdjustIntValue(target, _auraKey(auraId, "count"), 1) == 1
            _playAura(target, auraId, shader)
        endif
    elseif eid == "spell.cast"
        string spellText = _paramNStrEx(slot, effectIdx, useScratch, presetName, 1)
        bool pays = _paramNStrEx(slot, effectIdx, useScratch, presetName, 2) == "wearer"
        if spellText == "" || StorageUtil.HasStringValue(target, instKey)
            return
        endif
        Spell cast = _resolveSpell(spellText)
        if cast == None
            return
        endif
        if _isSelfBuff(cast)
            if pays && !_pay(target, cast)
                return
            endif
            _castAs(_applier(target, presetName), cast, target, 1.0)
            return
        endif
        StorageUtil.SetStringValue(target, instKey, spellText)
        StorageUtil.SetIntValue(target, instKey, pays as int)
        StorageUtil.SetFloatValue(target, instKey, 0.0)
        StorageUtil.SetStringValue(target, _spellCastPresetKey(instKey), presetName)
        _listSpellCast(target, instKey)
        _castPulse(target, instKey)
    elseif eid == "spell.aura"
        ; All read before the claim below, so a second dispatch of this instance can't claim it in between.
        string spellText = _paramNStrEx(slot, effectIdx, useScratch, presetName, 1)
        bool pays = _paramNStrEx(slot, effectIdx, useScratch, presetName, 3) == "wearer"
        if spellText == "" || StorageUtil.HasStringValue(target, instKey)
            return
        endif
        StorageUtil.SetStringValue(target, instKey, spellText)
        StorageUtil.SetFloatValue(target, instKey, param2 as float)
        StorageUtil.SetIntValue(target, instKey, pays as int)
        StorageUtil.SetStringValue(target, _spellAuraPresetKey(instKey), presetName)
        StorageUtil.UnsetFloatValue(target, _spellAuraPulseKey(instKey))
        _listSpellAura(target, instKey)
    endif
EndFunction

Function onDeactivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None
        return
    endif
    _checkInstall(target)
    string instKey = _instanceKey(eid, slot, effectIdx)
    StorageUtil.StringListRemove(target, HEAL_LIST, instKey, true)
    if eid == "vision.night"
        if _release(target, instKey) < 0
            return
        endif
        if StorageUtil.AdjustIntValue(PlayerRef, KEY_PREFIX + "nighteye.count", -1) <= 0
            StorageUtil.UnsetIntValue(PlayerRef, KEY_PREFIX + "nighteye.count")
            ImageSpaceModifier.RemoveCrossFade(1.0)
        endif
    elseif eid == "shout.recovery"
        if !StorageUtil.HasFloatValue(target, instKey)
            return
        endif
        float delta = StorageUtil.GetFloatValue(target, instKey)
        StorageUtil.UnsetFloatValue(target, instKey)
        target.ModActorValue("ShoutRecoveryMult", -delta)
    elseif eid == "rested"
        int restedIdx = _release(target, instKey)
        if restedIdx < 0
            return
        endif
        if StorageUtil.AdjustIntValue(target, _restedKey(restedIdx, "count"), -1) <= 0
            StorageUtil.UnsetIntValue(target, _restedKey(restedIdx, "count"))
            if StorageUtil.GetIntValue(target, _restedKey(restedIdx, "added")) == 1
                StorageUtil.UnsetIntValue(target, _restedKey(restedIdx, "added"))
                target.RemoveSpell(RestedSpells[restedIdx])
            endif
        endif
    elseif eid == "mood"
        if _release(target, instKey) < 0
            return
        endif
        StorageUtil.StringListRemove(target, KEY_PREFIX + "mood.instances", instKey, true)
        _applyMood(target, true)
    elseif eid == "fall.nodamage"
        if _release(target, instKey) < 0
            return
        endif
        if StorageUtil.AdjustIntValue(target, KEY_PREFIX + "fall.count", -1) <= 0
            StorageUtil.UnsetIntValue(target, KEY_PREFIX + "fall.count")
            if StorageUtil.GetIntValue(target, KEY_PREFIX + "fall.added") == 1
                StorageUtil.UnsetIntValue(target, KEY_PREFIX + "fall.added")
                target.RemovePerk(NoFallDamagePerk)
            endif
        endif
    elseif eid == "aura"
        if !StorageUtil.HasStringValue(target, instKey)
            return
        endif
        string auraId = StorageUtil.GetStringValue(target, instKey)
        StorageUtil.UnsetStringValue(target, instKey)
        if StorageUtil.AdjustIntValue(target, _auraKey(auraId, "count"), -1) <= 0
            StorageUtil.UnsetIntValue(target, _auraKey(auraId, "count"))
            StorageUtil.UnsetIntValue(target, _auraKey(auraId, "session"))
            EffectShader shader = _auraShader(auraId)
            if shader != None
                shader.Stop(target)
            endif
        endif
    elseif eid == "spell.cast"
        _dropSpellCast(target, instKey)
    elseif eid == "spell.aura"
        _dropSpellAura(target, instKey)
    endif
EndFunction

; Sleeping replaces the rested bonuses and they expire on their own, and dialogue or combat resets the
; face, so both are put back while their effect is shown. The game doesn't save shaders, so an aura last
; played before the latest load is played again. A spell aura or repeating cast is listed again, which
; restarts its tick if it stopped. A tier undone as stale while MTF still shows it gets no new onActivate,
; so it applies again here.
Function onTick(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None
        return
    endif
    _checkInstall(target)
    string instKey = _instanceKey(eid, slot, effectIdx)
    if StorageUtil.StringListFind(target, HEAL_LIST, instKey) >= 0
        onActivate(target, param, param2, eid, slot, effectIdx, useScratch, baseSlot, area, presetName)
        return
    endif
    if eid == "rested"
        if StorageUtil.HasIntValue(target, instKey)
            _ensureRested(target, StorageUtil.GetIntValue(target, instKey))
        endif
    elseif eid == "mood"
        if StorageUtil.HasIntValue(target, instKey)
            _applyMood(target, false)
        endif
    elseif eid == "aura"
        if StorageUtil.HasStringValue(target, instKey)
            string auraId = StorageUtil.GetStringValue(target, instKey)
            if StorageUtil.GetIntValue(target, _auraKey(auraId, "session"), -1) != _session()
                EffectShader shader = _auraShader(auraId)
                if shader != None
                    _playAura(target, auraId, shader)
                endif
            endif
        endif
    elseif eid == "spell.cast"
        if StorageUtil.HasStringValue(target, instKey)
            _listSpellCast(target, instKey)
        endif
    elseif eid == "spell.aura"
        if StorageUtil.HasStringValue(target, instKey)
            _listSpellAura(target, instKey)
        endif
    endif
EndFunction

; ── Reset ───────────────────────────────────────────────────────────────────

; Undoes every effect's change on the player and every actor MTF tracks, and forgets the tiers it applied. MTF
; still counts those tiers as showing, so their onDeactivate finds nothing to undo, and they apply again the
; next time they start.
Function _resetAll()
    int count = 0
    if _resetIfChanged(PlayerRef)
        count += 1
    endif
    MTF_MainQuest host = _host()
    if host != None
        int t = host.GetTrackedCount()
        while t > 0
            t -= 1
            Actor tracked = host.GetTrackedAt(t)
            if tracked != None && tracked != PlayerRef && _resetIfChanged(tracked)
                count += 1
            endif
        endwhile
    endif
    Debug.Trace("[MTF_Plugin_Skyrim] reset " + count + " actor(s)")
EndFunction

bool Function _resetIfChanged(Actor target)
    StorageUtil.StringListClear(target, HEAL_LIST)
    if !_hasInstances(target)
        return false
    endif
    _resetActor(target)
    return true
EndFunction

; Instances are found by key prefix rather than a list, so ones recorded before this existed are found too.
Function _resetActor(Actor target)
    string[] keys = StorageUtil.debug_AllObjFloatKeys(target)
    int i = keys.Length
    while i > 0
        i -= 1
        if StringUtil.Find(keys[i], KEY_PREFIX + "shout.recovery.") == 0
            float delta = StorageUtil.GetFloatValue(target, keys[i])
            StorageUtil.UnsetFloatValue(target, keys[i])
            target.ModActorValue("ShoutRecoveryMult", -delta)
        endif
    endwhile
    keys = StorageUtil.debug_AllObjStringKeys(target)
    i = keys.Length
    while i > 0
        i -= 1
        if StringUtil.Find(keys[i], KEY_PREFIX + "aura.") == 0
            EffectShader shader = _auraShader(StorageUtil.GetStringValue(target, keys[i]))
            StorageUtil.UnsetStringValue(target, keys[i])
            if shader != None
                shader.Stop(target)
            endif
        elseif StringUtil.Find(keys[i], KEY_PREFIX + "spell.aura.") == 0 || StringUtil.Find(keys[i], KEY_PREFIX + "spell.cast.") == 0
            StorageUtil.UnsetStringValue(target, keys[i])
            StorageUtil.UnsetFloatValue(target, keys[i])
            StorageUtil.UnsetIntValue(target, keys[i])
        elseif StringUtil.Find(keys[i], KEY_PREFIX + "spellaura.") == 0 || StringUtil.Find(keys[i], KEY_PREFIX + "spellcast.") == 0
            StorageUtil.UnsetStringValue(target, keys[i])
            StorageUtil.UnsetFloatValue(target, keys[i])
        endif
    endwhile
    StorageUtil.StringListClear(target, SPELL_AURA_KEYS)
    StorageUtil.StringListClear(target, SPELL_CAST_KEYS)
    if PlayerRef != None
        StorageUtil.FormListRemove(PlayerRef, SPELL_AURA_WEARERS, target, true)
        StorageUtil.FormListRemove(PlayerRef, SPELL_CAST_WEARERS, target, true)
    endif
    i = RestedSpells.Length
    while i > 0
        i -= 1
        if StorageUtil.GetIntValue(target, _restedKey(i, "added")) == 1 && RestedSpells[i] != None
            target.RemoveSpell(RestedSpells[i])
        endif
    endwhile
    if StorageUtil.GetIntValue(target, KEY_PREFIX + "fall.added") == 1 && NoFallDamagePerk != None
        target.RemovePerk(NoFallDamagePerk)
    endif
    if StorageUtil.StringListCount(target, KEY_PREFIX + "mood.instances") > 0
        StorageUtil.StringListClear(target, KEY_PREFIX + "mood.instances")
        target.ClearExpressionOverride()
    endif
    if target == PlayerRef && StorageUtil.GetIntValue(PlayerRef, KEY_PREFIX + "nighteye.count") > 0
        ImageSpaceModifier.RemoveCrossFade(1.0)
    endif
    StorageUtil.ClearObjIntValuePrefix(target, KEY_PREFIX + "vision.night.")
    StorageUtil.ClearObjIntValuePrefix(target, KEY_PREFIX + "nighteye.")
    StorageUtil.ClearObjIntValuePrefix(target, KEY_PREFIX + "rested.")
    StorageUtil.ClearObjIntValuePrefix(target, KEY_PREFIX + "mood.")
    StorageUtil.ClearObjIntValuePrefix(target, KEY_PREFIX + "fall.")
    StorageUtil.ClearObjIntValuePrefix(target, KEY_PREFIX + "aura.")
EndFunction

bool Function _hasInstances(Actor target)
    return StorageUtil.CountObjFloatValuePrefix(target, KEY_PREFIX + "shout.recovery.") > 0 || StorageUtil.CountObjStringValuePrefix(target, KEY_PREFIX + "aura.") > 0 || StorageUtil.CountObjIntValuePrefix(target, KEY_PREFIX + "vision.night.") > 0 || StorageUtil.CountObjIntValuePrefix(target, KEY_PREFIX + "rested.") > 0 || StorageUtil.CountObjIntValuePrefix(target, KEY_PREFIX + "mood.") > 0 || StorageUtil.CountObjIntValuePrefix(target, KEY_PREFIX + "fall.") > 0 || StorageUtil.CountObjStringValuePrefix(target, KEY_PREFIX + "spell.aura.") > 0 || StorageUtil.CountObjStringValuePrefix(target, KEY_PREFIX + "spell.cast.") > 0
EndFunction

int Function _installId()
    if InstallId == 0
        InstallId = Utility.RandomInt(1, 2147483647)
    endif
    return InstallId
EndFunction

; MTF can't deactivate tiers while this plugin is missing, so their instances outlive them and would block those
; tiers from applying again. An actor stamped by another install is undone first, as by the reset, and the
; instances it had are kept so onTick can apply any tier MTF still shows. An actor never stamped, from a save
; made before stamps existed, is only stamped: its changes are still live.
Function _checkInstall(Actor target)
    int id = _installId()
    int stamp = StorageUtil.GetIntValue(target, INSTALL_KEY)
    if stamp == id
        return
    endif
    StorageUtil.SetIntValue(target, INSTALL_KEY, id)
    if stamp == 0 || !_hasInstances(target)
        return
    endif
    Debug.Trace("[MTF_Plugin_Skyrim] " + target.GetDisplayName() + " had changes left from a load without this plugin, so they're undone first")
    _keepForHeal(target, StorageUtil.debug_AllObjIntKeys(target))
    _keepForHeal(target, StorageUtil.debug_AllObjFloatKeys(target))
    _keepForHeal(target, StorageUtil.debug_AllObjStringKeys(target))
    _resetActor(target)
EndFunction

; Counters share the instances' prefixes but never match an instance key, so keeping them is harmless.
Function _keepForHeal(Actor target, string[] keys)
    int i = keys.Length
    while i > 0
        i -= 1
        string k = keys[i]
        if StringUtil.Find(k, KEY_PREFIX + "vision.night.") == 0 || StringUtil.Find(k, KEY_PREFIX + "shout.recovery.") == 0 || StringUtil.Find(k, KEY_PREFIX + "rested.") == 0 || StringUtil.Find(k, KEY_PREFIX + "mood.") == 0 || StringUtil.Find(k, KEY_PREFIX + "fall.nodamage.") == 0 || StringUtil.Find(k, KEY_PREFIX + "aura.") == 0 || StringUtil.Find(k, KEY_PREFIX + "spell.aura.") == 0 || StringUtil.Find(k, KEY_PREFIX + "spell.cast.") == 0
            StorageUtil.StringListAdd(target, HEAL_LIST, k, false)
        endif
    endwhile
EndFunction

; Finds stale actors without waiting for one of their tiers, so changes from a tier that stopped while the plugin
; was missing are undone too.
Function _sweep()
    _checkInstall(PlayerRef)
    MTF_MainQuest host = _host()
    if host == None
        return
    endif
    int t = host.GetTrackedCount()
    while t > 0
        t -= 1
        Actor tracked = host.GetTrackedAt(t)
        if tracked != None
            _checkInstall(tracked)
        endif
    endwhile
EndFunction

; ── Effect helpers ──────────────────────────────────────────────────────────

; Records one shown instance with a value. False when this instance is already recorded.
bool Function _claim(Actor target, string instKey, int value)
    if StorageUtil.HasIntValue(target, instKey)
        return false
    endif
    StorageUtil.SetIntValue(target, instKey, value)
    return true
EndFunction

; Forgets one instance and returns its value, or -1 when it was never recorded.
int Function _release(Actor target, string instKey)
    if !StorageUtil.HasIntValue(target, instKey)
        return -1
    endif
    int value = StorageUtil.GetIntValue(target, instKey)
    StorageUtil.UnsetIntValue(target, instKey)
    return value
EndFunction

; Only a bonus this plugin added is removed later, so an earned one survives the tattoo.
Function _ensureRested(Actor target, int restedIdx)
    Spell bonus = RestedSpells[restedIdx]
    if bonus == None || target.HasSpell(bonus)
        return
    endif
    StorageUtil.SetIntValue(target, _restedKey(restedIdx, "added"), 1)
    target.AddSpell(bonus, false)
EndFunction

string Function _restedKey(int restedIdx, string suffix)
    return KEY_PREFIX + "rested." + restedIdx + "." + suffix
EndFunction

int Function _restedIndex(string restedId) global
    if restedId == "rested"
        return 0
    elseif restedId == "well_rested"
        return 1
    elseif restedId == "lovers_comfort"
        return 2
    endif
    return -1
EndFunction

; The most recently shown mood wins. Each instance stores mood * 1000 + strength.
Function _applyMood(Actor target, bool clearIfNone)
    string listKey = KEY_PREFIX + "mood.instances"
    int n = StorageUtil.StringListCount(target, listKey)
    if n <= 0
        if clearIfNone
            target.ClearExpressionOverride()
        endif
        return
    endif
    int packed = StorageUtil.GetIntValue(target, StorageUtil.StringListGet(target, listKey, n - 1))
    target.SetExpressionOverride(packed / 1000, packed % 1000)
EndFunction

; Expression indexes 7 to 14 are the "mood" set; 0 to 6 are dialogue versions that snap back quickly.
int Function _moodIndex(string moodId) global
    if moodId == "neutral"
        return 7
    elseif moodId == "angry"
        return 8
    elseif moodId == "fearful"
        return 9
    elseif moodId == "happy"
        return 10
    elseif moodId == "sad"
        return 11
    elseif moodId == "surprised"
        return 12
    elseif moodId == "puzzled"
        return 13
    elseif moodId == "disgusted"
        return 14
    endif
    return -1
EndFunction

; Stops combat for every living actor near the target that is hostile to it or fighting it.
Function _calmAround(Actor target, float radius)
    Actor[] nearby = PO3_SKSEFunctions.GetActorsByProcessingLevel(0)
    if !nearby || radius <= 0.0
        return
    endif
    int i = 0
    while i < nearby.Length
        Actor other = nearby[i]
        if other != None && other != target && !other.IsDead() && other.GetDistance(target) <= radius
            if other.IsHostileToActor(target) || other.GetCombatTarget() == target
                other.StopCombat()
                other.StopCombatAlarm()
            endif
        endif
        i += 1
    endwhile
EndFunction

Weather Function _weatherForm(string weatherId) global
    int formId = 0
    if weatherId == "clear"
        formId = 0x00081A ; SkyrimClear
    elseif weatherId == "cloudy"
        formId = 0x012F89 ; SkyrimCloudy
    elseif weatherId == "fog"
        formId = 0x0C821E ; SkyrimFog
    elseif weatherId == "rain"
        formId = 0x0C821F ; SkyrimOvercastRain
    elseif weatherId == "storm"
        formId = 0x0C8220 ; SkyrimStormRain
    elseif weatherId == "snow"
        formId = 0x04D7FB ; SkyrimOvercastSnow
    elseif weatherId == "blizzard"
        formId = 0x0C8221 ; SkyrimStormSnow
    else
        return None
    endif
    return Game.GetFormFromFile(formId, "Skyrim.esm") as Weather
EndFunction

; ── Magic aura ──────────────────────────────────────────────────────────────

; EffectShader.Play stacks rather than replacing, so each actor counts its shown instances per aura: the
; first plays it, the last stops it, and a replay only happens once per session.
int Function _session()
    return StorageUtil.GetIntValue(PlayerRef, KEY_PREFIX + "session")
EndFunction

string Function _auraKey(string auraId, string suffix)
    return KEY_PREFIX + "aura." + auraId + "." + suffix
EndFunction

; The session is stored before Play, which waits a frame while another tick could see a stale session.
Function _playAura(Actor target, string auraId, EffectShader shader)
    StorageUtil.SetIntValue(target, _auraKey(auraId, "session"), _session())
    shader.Play(target, -1.0)
EndFunction

EffectShader Function _auraShader(string auraId) global
    int formId = _auraSkyrimId(auraId)
    if formId > 0
        return Game.GetFormFromFile(formId, "Skyrim.esm") as EffectShader
    endif
    formId = _auraDawnguardId(auraId)
    if formId > 0
        return Game.GetFormFromFile(formId, "Dawnguard.esm") as EffectShader
    endif
    formId = _auraDragonbornId(auraId)
    if formId > 0
        return Game.GetFormFromFile(formId, "Dragonborn.esm") as EffectShader
    endif
    return None
EndFunction

int Function _auraSkyrimId(string auraId) global
    if auraId == "oakflesh"
        return 0x094160 ; MagicArmorOakFleshFXS
    elseif auraId == "ironflesh"
        return 0x094163 ; MagicArmorIronFleshFXS
    elseif auraId == "shield_spell"
        return 0x056AC9 ; ShieldSpellFXS
    elseif auraId == "shield_charge"
        return 0x10F803 ; PerkShieldChargeFXShader
    elseif auraId == "lightning_cloak"
        return 0x10F9A6 ; ShockPlayerCloakFXShader
    elseif auraId == "frost_light"
        return 0x0435A3 ; FrostShortFXShader
    elseif auraId == "frost_spikes"
        return 0x0647B9 ; FrostSpikeFXShader
    elseif auraId == "ice_form"
        return 0x0DC20D ; FrostIceFormFXShader
    elseif auraId == "steam"
        return 0x10FDF9 ; SteamFXShader
    elseif auraId == "webbed"
        return 0x02E1CD ; WebbedFXS
    elseif auraId == "chaurus_poison"
        return 0x10CC64 ; ChaurusPoisonFXShader
    elseif auraId == "ench_red"
        return 0x0D7661 ; EnchRedFXShader
    elseif auraId == "ench_blue"
        return 0x05D608 ; EnchBlueFXShader
    elseif auraId == "ench_purple"
        return 0x05D607 ; EnchPurpleFXShader
    elseif auraId == "ench_green"
        return 0x05D606 ; EnchGreenFXShader
    elseif auraId == "ench_fire"
        return 0x04E810 ; EnchFireFXShader
    elseif auraId == "ench_frost"
        return 0x04FA1D ; EnchFrostFXShader
    elseif auraId == "ench_shock"
        return 0x059EDA ; EnchShockFXShader
    elseif auraId == "elemental_fury"
        return 0x0510D3 ; EnchElementalFuryFXS
    elseif auraId == "bound_weapon"
        return 0x069CE8 ; EnchBoundSwordFXS
    elseif auraId == "potion_fire"
        return 0x10BEA9 ; AlchArmorFireFXS
    elseif auraId == "potion_frost"
        return 0x10BEAA ; AlchArmorFrostFXS
    elseif auraId == "potion_magicka"
        return 0x10BEAB ; AlchArmorMagickaFXS
    elseif auraId == "potion_shock"
        return 0x10BEAC ; AlchArmorShockFXS
    elseif auraId == "potion_poison"
        return 0x10BEAD ; AlchArmorPoisonFXS
    elseif auraId == "illusion_positive"
        return 0x073321 ; IllusionPositiveFXS
    elseif auraId == "illusion_negative"
        return 0x074799 ; IllusionNegativeFXS
    elseif auraId == "fear"
        return 0x07D450 ; IllusionFearFXS
    elseif auraId == "paralysis"
        return 0x06DE84 ; ParalyzeFxShader
    elseif auraId == "berserk"
        return 0x0FD7D9 ; BerserkerFXS
    elseif auraId == "nightmare"
        return 0x0BF743 ; NightmareFXShader
    elseif auraId == "kynes_peace"
        return 0x084B39 ; KynesPeaceFXS
    elseif auraId == "animal_allegiance"
        return 0x084B3A ; AnimalAllyFXS
    elseif auraId == "disguise"
        return 0x07876B ; Disguise01FXS
    elseif auraId == "absorb_magicka"
        return 0x0ABF08 ; AbsorbBlueFXS
    elseif auraId == "absorb_stamina"
        return 0x0ABF07 ; AbsorbGreenFXS
    elseif auraId == "dragon_soul"
        return 0x0280C0 ; DragonPowerAbsorbFXS
    elseif auraId == "greybeard_power"
        return 0x09186F ; GreybeardPowerAbsorbFXS
    elseif auraId == "ghost_violet"
        return 0x103129 ; GhostVioletFXShader
    elseif auraId == "wolf_spirit"
        return 0x0FE68D ; GhostWolfSpiritFXShader
    elseif auraId == "call_of_valor"
        return 0x01A1E9 ; GhostCallValorFXShader
    elseif auraId == "mage_ghost"
        return 0x06A155 ; MGGhostFXShader
    elseif auraId == "nightingale"
        return 0x0C5EF7 ; GhostFXShaderNightingale
    elseif auraId == "nightingale_corrupt"
        return 0x0C7908 ; GhostFXShaderNightingaleCorrupt
    elseif auraId == "nightingale_shadow"
        return 0x000E5C ; InvisFXShaderNightingale
    elseif auraId == "shadow_armor"
        return 0x081180 ; DA02ArmorShadow
    elseif auraId == "dragonskin"
        return 0x10F566 ; PowerRacialBretonFXShader
    elseif auraId == "highborn"
        return 0x10CC48 ; PowerRacialHighbornFXS
    elseif auraId == "command_animal"
        return 0x10F927 ; PowerRacialCommandAnimalFXShader
    elseif auraId == "ancestors_wrath"
        return 0x10F56C ; DarkElfAncestorsWrathFXShader
    elseif auraId == "histskin"
        return 0x10F4A9 ; ArgonianHistHealFXS
    elseif auraId == "adrenaline_rush"
        return 0x10F4A8 ; AdrenalineRushFXS
    elseif auraId == "healing_circle"
        return 0x10CDC9 ; HealCircleFXS
    elseif auraId == "mystic_healing"
        return 0x04E220 ; HealMysticFXS
    elseif auraId == "water_breathing"
        return 0x0BCF27 ; WaterBreathingFXS
    elseif auraId == "azura_radiant"
        return 0x08CA2F ; AzuraGood
    elseif auraId == "azura_corrupted"
        return 0x050F02 ; AzuraEvil
    elseif auraId == "boethiah"
        return 0x0CC6E6 ; DA02BoethiahFXS
    elseif auraId == "sovngarde"
        return 0x10B2DF ; SovengardeFXS01
    elseif auraId == "ancano"
        return 0x025226 ; MGAncanoEffectShader
    elseif auraId == "flame_atronach"
        return 0x078ED3 ; AtronachFlameGlowFXS
    endif
    return 0
EndFunction

int Function _auraDawnguardId(string auraId) global
    if auraId == "sun_fire_cloak"
        return 0x00A3BC ; DLC1SunFireCloakFXShader
    elseif auraId == "sun_fire"
        return 0x00A3BB ; DLC1SunFireFXShader
    elseif auraId == "soul_cairn_ghost"
        return 0x019AB3 ; DLC1SoulCairnGhostFXShader
    elseif auraId == "soul_cairn"
        return 0x00939B ; DLC01SoulCairnFXShader
    elseif auraId == "mistform"
        return 0x01AA2E ; DLC1VampireMistform01FXS
    elseif auraId == "drain_vitality"
        return 0x00CBC1 ; DLC1DrainVital01FXS
    elseif auraId == "auriel"
        return 0x00AEB3 ; DLC1AurielsBowFireFXShader
    endif
    return 0
EndFunction

int Function _auraDragonbornId(string auraId) global
    if auraId == "miraak_magic"
        return 0x03D30E ; DLC2MiraakMagicFXS
    elseif auraId == "miraak_smoke"
        return 0x03D30D ; DLC2MiraakSmokeFXS
    elseif auraId == "dragon_aspect_1"
        return 0x021735 ; DLC2DragonbornAspectFXS01
    elseif auraId == "dragon_aspect_2"
        return 0x021734 ; DLC2DragonbornAspectFXS02
    elseif auraId == "dragon_aspect_3"
        return 0x021733 ; DLC2DragonbornAspectFXS03
    elseif auraId == "ash_shell"
        return 0x027E34 ; DLC2AshShellFXS
    elseif auraId == "ash_guardian"
        return 0x027E33 ; DLC2AshGuardianFXS
    elseif auraId == "whirlwind_cloak"
        return 0x02502A ; DLC2WhirlWindCloakFXS
    elseif auraId == "moras_grasp"
        return 0x03A299 ; DLC2MorasGraspFXShader
    elseif auraId == "omen_of_danger"
        return 0x0324C1 ; DLC2OmenOfDangerFXS
    elseif auraId == "apocrypha"
        return 0x03CD84 ; DLC2ApocryphaSpellFXS
    elseif auraId == "seeker"
        return 0x023F87 ; DLC2HMDaedraFXS
    endif
    return 0
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

; ── Spells from tattoos ─────────────────────────────────────────────────────

; "Plugin.esp|0x012FCD", as the Magic Tattoos UI stores it, or the name of a spell the player knows, typed in
; MTF's own menu.
Spell Function _resolveSpell(string spellText)
    string text = _trim(spellText)
    if text == ""
        return None
    endif
    Spell found = None
    int bar = StringUtil.Find(text, "|")
    if bar > 0
        int formId = _parseHex(_trim(StringUtil.Substring(text, bar + 1)))
        if formId > 0
            found = Game.GetFormFromFile(formId, _trim(StringUtil.Substring(text, 0, bar))) as Spell
        endif
    elseif PlayerRef != None
        int i = PlayerRef.GetSpellCount()
        while i > 0 && found == None
            i -= 1
            Spell known = PlayerRef.GetNthSpell(i)
            if known != None && known.GetName() == text
                found = known
            endif
        endwhile
    endif
    if found == None
        Debug.Trace("[MTF_Plugin_Skyrim] no spell found for '" + text + "'")
    elseif _isTacticalSpell(found)
        Debug.Trace("[MTF_Plugin_Skyrim] '" + text + "' is a Magic Tattoos Tactical spell, which tattoos can't cast")
        found = None
    endif
    return found
EndFunction

; Tactical is ESL-flagged, so its forms are 0xFE, then its light index, then the local ID.
bool Function _isTacticalSpell(Spell candidate)
    int light = Game.GetLightModByName(TACTICAL_PLUGIN)
    if light < 0 || light > 0xFFF
        return false
    endif
    int id = candidate.GetFormID()
    return Math.RightShift(id, 24) == 0xFE && Math.LogicalAnd(Math.RightShift(id, 12), 0xFFF) == light
EndFunction

; Hex digits with or without 0x. -1 when anything else is in the string.
int Function _parseHex(string s) global
    int n = StringUtil.GetLength(s)
    int i = 0
    if n >= 2 && StringUtil.GetNthChar(s, 0) == "0" && StringUtil.GetNthChar(s, 1) == "x"
        i = 2
    endif
    if i >= n
        return -1
    endif
    int value = 0
    while i < n
        int digit = _hexDigit(StringUtil.GetNthChar(s, i))
        if digit < 0
            return -1
        endif
        value = value * 16 + digit
        i += 1
    endwhile
    return value
EndFunction

; Papyrus compares strings without case, so "a" matches "A".
int Function _hexDigit(string c) global
    int d = 0
    while d < 16
        if StringUtil.GetNthChar("0123456789ABCDEF", d) == c
            return d
        endif
        d += 1
    endwhile
    return -1
EndFunction

; The actor credited with a spell from this preset: the one in the shared mtf.applier.<preset> key, or the wearer.
Actor Function _applier(Actor wearer, string presetName)
    if presetName != ""
        Actor applier = StorageUtil.GetFormValue(wearer, APPLIER_PREFIX + presetName) as Actor
        if applier != None && !applier.IsDead()
            return applier
        endif
    endif
    return wearer
EndFunction

; Lands the spell on the target as if the applier cast it. afScale multiplies magnitude when Magic Tattoos UI
; 1.8.6 or later is present (Spell aura fire-and-forget uses 0.5). DoCombatSpellApply, without the UI, may leave
; out the applier's perks and potions and ignores afScale.
Function _castAs(Actor applier, Spell cast, Actor target, float afScale)
    if afScale <= 0.0
        return
    endif
    int ui = SKSE.GetPluginVersion("MagicTattoosUI")
    if ui >= CAST_AS_SCALED_MIN_UI_VERSION
        MagicTattoosUI.CastAsScaled(applier, cast, target, afScale)
    elseif ui >= CAST_AS_MIN_UI_VERSION
        MagicTattoosUI.CastAs(applier, cast, target)
    else
        applier.DoCombatSpellApply(cast, target)
    endif
EndFunction

bool Function _isHarmful(Spell candidate)
    MagicEffect costliest = candidate.GetNthEffectMagicEffect(candidate.GetCostliestEffectIndex())
    return costliest != None && costliest.IsEffectFlagSet(EFFECT_FLAG_HOSTILE)
EndFunction

bool Function _isConcentration(Spell candidate)
    MagicEffect costliest = candidate.GetNthEffectMagicEffect(candidate.GetCostliestEffectIndex())
    return costliest != None && costliest.GetCastingType() == CASTING_CONCENTRATION
EndFunction

; Self delivery and not concentration: Oakflesh, Courage, and so on. Lands once when the tier shows.
bool Function _isSelfBuff(Spell candidate)
    MagicEffect costliest = candidate.GetNthEffectMagicEffect(candidate.GetCostliestEffectIndex())
    return costliest != None && costliest.GetDeliveryType() == DELIVERY_SELF && costliest.GetCastingType() != CASTING_CONCENTRATION
EndFunction

; Concentration pulses every second; fire-and-forget uses the spell's cast time, floored so a 0 charge can't spin.
float Function _castInterval(Spell candidate)
    if _isConcentration(candidate)
        return SPELL_AURA_INTERVAL
    endif
    float charge = candidate.GetCastTime()
    if charge < SPELL_CAST_MIN_INTERVAL
        return SPELL_CAST_MIN_INTERVAL
    endif
    return charge
EndFunction

; Takes the spell's cost from the wearer's magicka. False, taking nothing, when they don't have enough.
bool Function _pay(Actor wearer, Spell cast)
    float cost = cast.GetEffectiveMagickaCost(wearer) as float
    if cost <= 0.0
        return true
    elseif wearer.GetActorValue("Magicka") < cost
        return false
    endif
    wearer.DamageActorValue("Magicka", cost)
    return true
EndFunction

; ── Spell cast (repeating on wearer) and Spell aura ─────────────────────────

; Each shown instance keeps, under its instance key on the wearer, the spell as a string, whether the wearer
; pays as an int, and for auras the radius in metres as a float / for casts the next due real time as a float.
; Presets and aura pulse times sit under prefixes no reset scan mistakes for an instance.
string Function _spellAuraPresetKey(string instKey)
    return KEY_PREFIX + "spellaura.preset." + instKey
EndFunction

string Function _spellAuraPulseKey(string instKey)
    return KEY_PREFIX + "spellaura.pulse." + instKey
EndFunction

string Function _spellCastPresetKey(string instKey)
    return KEY_PREFIX + "spellcast.preset." + instKey
EndFunction

Function _listSpellAura(Actor wearer, string instKey)
    StorageUtil.StringListAdd(wearer, SPELL_AURA_KEYS, instKey, false)
    StorageUtil.FormListAdd(PlayerRef, SPELL_AURA_WEARERS, wearer, false)
    _startSpellTick()
EndFunction

Function _dropSpellAura(Actor wearer, string instKey)
    StorageUtil.StringListRemove(wearer, SPELL_AURA_KEYS, instKey, true)
    StorageUtil.UnsetStringValue(wearer, instKey)
    StorageUtil.UnsetFloatValue(wearer, instKey)
    StorageUtil.UnsetIntValue(wearer, instKey)
    StorageUtil.UnsetStringValue(wearer, _spellAuraPresetKey(instKey))
    StorageUtil.UnsetFloatValue(wearer, _spellAuraPulseKey(instKey))
EndFunction

Function _listSpellCast(Actor wearer, string instKey)
    StorageUtil.StringListAdd(wearer, SPELL_CAST_KEYS, instKey, false)
    StorageUtil.FormListAdd(PlayerRef, SPELL_CAST_WEARERS, wearer, false)
    _startSpellTick()
EndFunction

Function _dropSpellCast(Actor wearer, string instKey)
    StorageUtil.StringListRemove(wearer, SPELL_CAST_KEYS, instKey, true)
    StorageUtil.UnsetStringValue(wearer, instKey)
    StorageUtil.UnsetFloatValue(wearer, instKey)
    StorageUtil.UnsetIntValue(wearer, instKey)
    StorageUtil.UnsetStringValue(wearer, _spellCastPresetKey(instKey))
EndFunction

; The tick runs on the player alias, since the quest's own updates belong to MTF's registration. A queued update
; can be lost after a load or a script rebuild, so a tick that hasn't run for a while is started again; real time
; restarts on load, so a time ahead of now counts as stopped too.
Function _startSpellTick()
    float now = Utility.GetCurrentRealTime()
    float last = StorageUtil.GetFloatValue(PlayerRef, SPELL_TICK)
    if last > 0.0 && last <= now && now - last < SPELL_TICK_INTERVAL * 2.5
        return
    endif
    StorageUtil.SetFloatValue(PlayerRef, SPELL_TICK, now)
    MTF_Plugin_Skyrim_Load ticker = GetAlias(0) as MTF_Plugin_Skyrim_Load
    if ticker != None
        ticker._startSpellTick()
    endif
EndFunction

; Kept so an old Load.pex that still calls this name after a partial update keeps the tick running.
bool Function _auraTick()
    return _spellTick()
EndFunction

; One wake of every shown spell cast and spell aura. False once none are left, which stops the tick.
bool Function _spellTick()
    int auras = StorageUtil.FormListCount(PlayerRef, SPELL_AURA_WEARERS)
    int casts = StorageUtil.FormListCount(PlayerRef, SPELL_CAST_WEARERS)
    if auras <= 0 && casts <= 0
        StorageUtil.UnsetFloatValue(PlayerRef, SPELL_TICK)
        return false
    endif
    float now = Utility.GetCurrentRealTime()
    StorageUtil.SetFloatValue(PlayerRef, SPELL_TICK, now)
    if auras > 0
        int w = auras
        while w > 0
            w -= 1
            Actor wearer = StorageUtil.FormListGet(PlayerRef, SPELL_AURA_WEARERS, w) as Actor
            int n = 0
            if wearer != None
                n = StorageUtil.StringListCount(wearer, SPELL_AURA_KEYS)
            endif
            if n <= 0
                StorageUtil.FormListRemoveAt(PlayerRef, SPELL_AURA_WEARERS, w)
            elseif !wearer.IsDead() && wearer.Is3DLoaded()
                while n > 0
                    n -= 1
                    _auraPulse(wearer, StorageUtil.StringListGet(wearer, SPELL_AURA_KEYS, n), now)
                endwhile
            endif
        endwhile
    endif
    int c = casts
    while c > 0
        c -= 1
        Actor wearer = StorageUtil.FormListGet(PlayerRef, SPELL_CAST_WEARERS, c) as Actor
        int n = 0
        if wearer != None
            n = StorageUtil.StringListCount(wearer, SPELL_CAST_KEYS)
        endif
        if n <= 0
            StorageUtil.FormListRemoveAt(PlayerRef, SPELL_CAST_WEARERS, c)
        elseif !wearer.IsDead() && wearer.Is3DLoaded()
            while n > 0
                n -= 1
                _castPulseDue(wearer, StorageUtil.StringListGet(wearer, SPELL_CAST_KEYS, n), now)
            endwhile
        endif
    endwhile
    return StorageUtil.FormListCount(PlayerRef, SPELL_AURA_WEARERS) > 0 || StorageUtil.FormListCount(PlayerRef, SPELL_CAST_WEARERS) > 0
EndFunction

; Fires now and schedules the next hit from the spell's cast interval.
Function _castPulse(Actor wearer, string instKey)
    _castPulseDue(wearer, instKey, Utility.GetCurrentRealTime())
EndFunction

Function _castPulseDue(Actor wearer, string instKey, float now)
    string spellText = StorageUtil.GetStringValue(wearer, instKey)
    if spellText == ""
        StorageUtil.StringListRemove(wearer, SPELL_CAST_KEYS, instKey, true)
        return
    endif
    float due = StorageUtil.GetFloatValue(wearer, instKey)
    if due > now
        return
    endif
    Spell cast = _resolveSpell(spellText)
    if cast == None
        return
    endif
    if StorageUtil.GetIntValue(wearer, instKey) == 1 && !_pay(wearer, cast)
        StorageUtil.SetFloatValue(wearer, instKey, now + _castInterval(cast))
        return
    endif
    Actor applier = _applier(wearer, StorageUtil.GetStringValue(wearer, _spellCastPresetKey(instKey)))
    _castAs(applier, cast, wearer, 1.0)
    StorageUtil.SetFloatValue(wearer, instKey, now + _castInterval(cast))
EndFunction

; True when other is fighting applier, or their factions are enemies. IsHostileToActor alone misses
; Unaggressive faction-enemies (training dummies, calmed bandits) who never drew weapons.
bool Function _isEnemyOf(Actor other, Actor applier)
    if other == None || applier == None
        return false
    endif
    ; GetFactionReaction: 0 Neutral, 1 Enemy, 2 Ally, 3 Friend.
    return other.IsHostileToActor(applier) || other.GetFactionReaction(applier) == 1
EndFunction

; A helpful spell lands on the wearer and everyone near them who isn't an enemy of the applier. A harmful one lands
; on everyone near them who is, never on the wearer or the player's teammates when the player applied it.
; Fire-and-forget spells use half magnitude when Magic Tattoos UI 1.8.6 or later is present.
; Neighbours come from a radius scan (FindAllReferencesOfFormType), not GetActorsByProcessingLevel(0): pinned or
; restrained actors such as training dummies can be 3D-loaded next to the player and still missing from high process.
Function _auraPulse(Actor wearer, string instKey, float now)
    string spellText = StorageUtil.GetStringValue(wearer, instKey)
    if spellText == ""
        StorageUtil.StringListRemove(wearer, SPELL_AURA_KEYS, instKey, true)
        return
    endif
    float last = StorageUtil.GetFloatValue(wearer, _spellAuraPulseKey(instKey))
    if last > 0.0 && now - last < SPELL_AURA_INTERVAL
        return
    endif
    Spell cast = _resolveSpell(spellText)
    if cast == None || (StorageUtil.GetIntValue(wearer, instKey) == 1 && !_pay(wearer, cast))
        return
    endif
    StorageUtil.SetFloatValue(wearer, _spellAuraPulseKey(instKey), now)
    Actor applier = _applier(wearer, StorageUtil.GetStringValue(wearer, _spellAuraPresetKey(instKey)))
    float radius = StorageUtil.GetFloatValue(wearer, instKey) * UNITS_PER_METRE
    bool harmful = _isHarmful(cast)
    float scale = 1.0
    if !_isConcentration(cast)
        scale = SPELL_AURA_FF_SCALE
    endif
    ObjectReference[] nearby = PO3_SKSEFunctions.FindAllReferencesOfFormType(wearer, FORM_TYPE_ACTOR, radius)
    if !harmful
        _castAs(applier, cast, wearer, scale)
    endif
    bool sawPlayer = false
    if nearby
        int i = 0
        while i < nearby.Length
            Actor other = nearby[i] as Actor
            if other == PlayerRef
                sawPlayer = true
            endif
            _auraHit(applier, wearer, other, cast, harmful, radius, scale)
            i += 1
        endwhile
    endif
    ; Without Papyrus Extender (or an empty scan), still try the player for helpful auras.
    if !sawPlayer
        _auraHit(applier, wearer, PlayerRef, cast, harmful, radius, scale)
    endif
EndFunction

Function _auraHit(Actor applier, Actor wearer, Actor other, Spell cast, bool harmful, float radius, float scale)
    if other == None || other == wearer || other.IsDead() || other.GetDistance(wearer) > radius
        return
    endif
    if harmful
        if other == applier || !_isEnemyOf(other, applier) || (applier == PlayerRef && other.IsPlayerTeammate())
            return
        endif
    elseif other != applier && _isEnemyOf(other, applier)
        return
    endif
    _castAs(applier, cast, other, scale)
EndFunction
