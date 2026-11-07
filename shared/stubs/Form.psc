Scriptname Form Hidden
{Compile-only stub. Never shipped; the game has the real script. Signatures match the game and SKSE sources.}

int Function GetFormID() native

string Function GetName() native

bool Function HasKeyword(Keyword akKeyword) native

Function RegisterForSingleUpdate(float afInterval) native

Function RegisterForModEvent(string eventName, string callbackName) native

bool Function RegisterForAnimationEvent(ObjectReference akSender, string asEventName) native

Function UnregisterForAnimationEvent(ObjectReference akSender, string asEventName) native

Event OnInit()
EndEvent

Event OnUpdate()
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
EndEvent
