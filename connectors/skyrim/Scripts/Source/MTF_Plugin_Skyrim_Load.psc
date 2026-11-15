; Copyright (C) 2026 Jack Whitehouse (proteux). Licensed under the GNU General Public License v3.0 or later; see LICENSE.
Scriptname MTF_Plugin_Skyrim_Load extends ReferenceAlias
{On the player alias of MTF_Plugin_Skyrim's quest. Quest scripts never receive OnPlayerLoadGame or the
 player's OnSpellCast. Also runs the spell cast / spell aura tick, since the quest's own updates belong to
 MTF's registration.}

Event OnPlayerLoadGame()
    MTF_Plugin_Skyrim owner = GetOwningQuest() as MTF_Plugin_Skyrim
    if owner != None
        owner._onGameLoaded()
    endif
EndEvent

Event OnSpellCast(Form akSpell)
    Spell cast = akSpell as Spell
    MTF_Plugin_Skyrim owner = GetOwningQuest() as MTF_Plugin_Skyrim
    if cast != None && owner != None
        owner._logCast(Game.GetPlayer(), cast)
    endif
EndEvent

Function _startSpellTick()
    RegisterForSingleUpdate(0.1)
EndFunction

; Kept so an old .pex that still calls this name after a partial update can start the tick.
Function _startAuraTick()
    _startSpellTick()
EndFunction

Event OnUpdate()
    MTF_Plugin_Skyrim owner = GetOwningQuest() as MTF_Plugin_Skyrim
    if owner != None && owner._spellTick()
        RegisterForSingleUpdate(owner.SPELL_TICK_INTERVAL)
    endif
EndEvent
