Scriptname PlayerVampireQuestScript extends Quest
{Compile-only stub. Not shipped. Sacrosanct replaces the vanilla script; these are the members MTF_Plugin_Sacrosanct uses.
 Devolve exists only in Sacrosanct's version.}

Int Property VampireStatus Auto
Float Property LastFeedTime Auto
GlobalVariable Property PlayerIsVampire Auto

Bool Function Devolve(Bool abForceDevolve)
EndFunction

Function VampireFeed()
EndFunction

Function StartHate(Actor Player)
EndFunction

Function StopHate(Actor Player, Bool akForceStopHate)
EndFunction
