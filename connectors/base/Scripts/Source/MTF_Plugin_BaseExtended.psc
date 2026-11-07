; Copyright (C) 2026 Jack Whitehouse (proteux). Licensed under the GNU General Public License v3.0 or later; see LICENSE.
Scriptname MTF_Plugin_BaseExtended extends MTF_Plugin
{Magic Tattoos Framework conditions and effects for the base game, beyond what MTF's own Base plugin covers.
 No soft dependency: everything here is Skyrim, its DLC, and SKSE.
 Catalog: SKSE/Plugins/StorageUtilData/MagicTattoosFramework/plugins/proteux-mtf.base.json

 Optional: powerofthree's Papyrus Extender (hidden, diseased, disease.cure, calm).
 Without it those entries do nothing; everything else still works.

 MTF does not replay effects after a load, so MTF_Plugin_BaseExtended_Load, on the player alias,
 calls _onGameLoaded to restore state the game does not save (the Night Eye image space, expressions).
 It also passes on the player's OnSpellCast. NPC casts come from their cast animation events instead.}

string Property MOD_VERSION = "0.1.0" AutoReadOnly Hidden
string Property KEY_PREFIX = "proteux-mtf.base." AutoReadOnly Hidden
float Property UNITS_PER_METRE = 70.0 AutoReadOnly Hidden
float Property MIN_SHOUT_MULT = 0.05 AutoReadOnly Hidden
int Property DISEASE_SPELL_TYPE = 1 AutoReadOnly Hidden
; The largest Seconds and At least the Just made a kill catalog entry allows.
float Property KILL_WINDOW_MAX = 120.0 AutoReadOnly Hidden
int Property KILL_LOG_MAX = 20 AutoReadOnly Hidden
; The largest Seconds the Just cast a spell catalog entry allows.
float Property CAST_WINDOW_MAX = 120.0 AutoReadOnly Hidden
int Property CAST_LOG_MAX = 10 AutoReadOnly Hidden
int Property CAST_WATCH_MAX = 32 AutoReadOnly Hidden

Actor Property PlayerRef Auto Hidden
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
    return "proteux-mtf.base"
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
    Debug.Trace("[MTF_Plugin_BaseExtended] " + MOD_VERSION + " registered as " + GetPluginId())
EndFunction

Function _onGameLoaded()
    _resolveDeps()
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
        return _inHands(target, wanted, "")
    elseif cid == "spell.school.equipped"
        return _inHands(target, None, _host().GetEvalParamStr())
    elseif cid == "spell.cast.recent"
        ; Both read before _watchCasts, whose calls wait a frame while another evaluation can reset them.
        string[] wanted = StringUtil.Split(_host().GetEvalParamStr(), ",")
        float windowSec = _host().GetEvalParam2() as float
        if target != PlayerRef
            _watchCasts(target)
        endif
        return _castWithin(target, wanted, "", windowSec)
    elseif cid == "spell.school.cast.recent"
        string school = _host().GetEvalParamStr()
        float windowSec = _host().GetEvalParam2() as float
        if target != PlayerRef
            _watchCasts(target)
        endif
        return _castWithin(target, None, school, windowSec)
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

bool Function _castWithin(Actor caster, string[] names, string school, float windowSec)
    if windowSec <= 0.0
        windowSec = 10.0
    endif
    float now = Utility.GetCurrentRealTime()
    _pruneCasts(caster, now)
    string spellsKey = KEY_PREFIX + "cast.spells"
    string timesKey = KEY_PREFIX + "cast.times"
    int i = StorageUtil.FloatListCount(caster, timesKey) - 1
    while i >= 0 && StorageUtil.FloatListGet(caster, timesKey, i) >= now - windowSec
        if _spellMatches(StorageUtil.FormListGet(caster, spellsKey, i) as Spell, names, school)
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

bool Function _inHands(Actor target, string[] names, string school) global
    return _spellMatches(target.GetEquippedSpell(0), names, school) || _spellMatches(target.GetEquippedSpell(1), names, school)
EndFunction

; By school when one is given, otherwise by name. "any" is any spell with a school, so not a power.
bool Function _spellMatches(Spell candidate, string[] names, string school) global
    if candidate == None
        return false
    elseif school == ""
        return _nameIn(candidate.GetName(), names)
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
bool Function _nameIn(string spellName, string[] wanted) global
    if spellName == "" || wanted == None
        return false
    endif
    int i = 0
    while i < wanted.Length
        if _trim(wanted[i]) == spellName
            return true
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
    if nearby == None
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
    string instKey = _instanceKey(eid, slot, effectIdx)
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
    endif
EndFunction

Function onDeactivate(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None
        return
    endif
    string instKey = _instanceKey(eid, slot, effectIdx)
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
    endif
EndFunction

; Sleeping replaces the rested bonuses and they expire on their own, and dialogue or combat resets the
; face, so both are put back while their effect is shown.
Function onTick(Actor target, int param, int param2, string eid, int slot, int effectIdx, bool useScratch, int baseSlot, int area, string presetName)
    if target == None || PlayerRef == None
        return
    endif
    string instKey = _instanceKey(eid, slot, effectIdx)
    if eid == "rested"
        if StorageUtil.HasIntValue(target, instKey)
            _ensureRested(target, StorageUtil.GetIntValue(target, instKey))
        endif
    elseif eid == "mood"
        if StorageUtil.HasIntValue(target, instKey)
            _applyMood(target, false)
        endif
    endif
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
    if nearby == None || radius <= 0.0
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
