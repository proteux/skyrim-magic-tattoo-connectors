Scriptname NiOverride Hidden
{Compile-only stub. Never shipped; RaceMenu (skee64) provides the real script.}

Function AddNodeTransformScale(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName, string key, float scale) native global

bool Function RemoveNodeTransformScale(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName, string key) native global

Function UpdateNodeTransform(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName) native global

Function SetBodyMorph(ObjectReference ref, string morphName, string keyName, float value) native global

Function ClearBodyMorph(ObjectReference ref, string morphName, string keyName) native global

Function UpdateModelWeight(ObjectReference ref) native global
