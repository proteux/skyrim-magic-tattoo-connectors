Scriptname MTF_Plugin_BaseExtended_Load extends ReferenceAlias
{On the player alias of MTF_Plugin_BaseExtended's quest. Quest scripts never receive OnPlayerLoadGame.}

Event OnPlayerLoadGame()
    MTF_Plugin_BaseExtended owner = GetOwningQuest() as MTF_Plugin_BaseExtended
    if owner != None
        owner._onGameLoaded()
    endif
EndEvent
