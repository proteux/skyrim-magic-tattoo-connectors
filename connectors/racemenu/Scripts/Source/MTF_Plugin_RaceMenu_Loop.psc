Scriptname MTF_Plugin_RaceMenu_Loop extends ReferenceAlias
{On the player alias of MTF_Plugin_RaceMenu's quest: the step timer for transitions, and the load hook.
 The quest's own OnUpdate belongs to MTF_Plugin's registration, and quest scripts never receive OnPlayerLoadGame.}

Event OnUpdate()
    MTF_Plugin_RaceMenu owner = GetOwningQuest() as MTF_Plugin_RaceMenu
    if owner != None && owner._step()
        RegisterForSingleUpdate(owner.STEP_SECONDS)
    endif
EndEvent

Event OnPlayerLoadGame()
    MTF_Plugin_RaceMenu owner = GetOwningQuest() as MTF_Plugin_RaceMenu
    if owner != None
        owner._onGameLoaded()
    endif
EndEvent
