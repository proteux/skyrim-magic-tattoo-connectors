Scriptname NiOverride Hidden
{Compile-only stub. Never shipped; RaceMenu (skee64) provides the real script.}

Function AddNodeTransformScale(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName, string key, float scale) native global

bool Function RemoveNodeTransformScale(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName, string key) native global

Function UpdateNodeTransform(ObjectReference akRef, bool firstPerson, bool isFemale, string nodeName) native global

Function SetBodyMorph(ObjectReference ref, string morphName, string keyName, float value) native global

float Function GetBodyMorph(ObjectReference ref, string morphName, string keyName) native global

Function ClearBodyMorph(ObjectReference ref, string morphName, string keyName) native global

Function ClearBodyMorphKeys(ObjectReference ref, string keyName) native global

Function UpdateModelWeight(ObjectReference ref) native global

Function AddNodeOverrideInt(ObjectReference ref, bool isFemale, string node, int key, int index, int value, bool persist) native global

bool Function HasNodeOverride(ObjectReference ref, bool isFemale, string node, int key, int index) native global

int Function GetNodeOverrideInt(ObjectReference ref, bool isFemale, string node, int key, int index) native global

Function ApplyNodeOverrides(ObjectReference ref) native global

Function RemoveNodeOverride(ObjectReference ref, bool isFemale, string node, int key, int index) native global

int Function GetNodePropertyInt(ObjectReference ref, bool firstPerson, string node, int key, int index) native global
