Scriptname StorageUtil Hidden
{Compile-only stub. Never shipped; PapyrusUtil SE provides the real script. Signatures match PapyrusUtil 4.x.}

int Function SetIntValue(Form ObjKey, string KeyName, int value) global native
float Function SetFloatValue(Form ObjKey, string KeyName, float value) global native

int Function GetIntValue(Form ObjKey, string KeyName, int missing = 0) global native
float Function GetFloatValue(Form ObjKey, string KeyName, float missing = 0.0) global native

bool Function HasIntValue(Form ObjKey, string KeyName) global native
bool Function HasFloatValue(Form ObjKey, string KeyName) global native

bool Function UnsetIntValue(Form ObjKey, string KeyName) global native
bool Function UnsetFloatValue(Form ObjKey, string KeyName) global native

int Function AdjustIntValue(Form ObjKey, string KeyName, int amount) global native

int Function FormListCount(Form ObjKey, string KeyName) global native
Form Function FormListGet(Form ObjKey, string KeyName, int index) global native
int function FormListAdd(Form ObjKey, string KeyName, Form value, bool allowDuplicate = true) global native
bool function FormListRemoveAt(Form ObjKey, string KeyName, int index) global native
int function FormListClear(Form ObjKey, string KeyName) global native

int function FloatListAdd(Form ObjKey, string KeyName, float value, bool allowDuplicate = true) global native
float function FloatListGet(Form ObjKey, string KeyName, int index) global native
bool function FloatListRemoveAt(Form ObjKey, string KeyName, int index) global native
int function FloatListCount(Form ObjKey, string KeyName) global native
int function FloatListClear(Form ObjKey, string KeyName) global native

int function StringListAdd(Form ObjKey, string KeyName, string value, bool allowDuplicate = true) global native
string function StringListGet(Form ObjKey, string KeyName, int index) global native
bool function StringListRemoveAt(Form ObjKey, string KeyName, int index) global native
int function StringListRemove(Form ObjKey, string KeyName, string value, bool allInstances = false) global native
int function StringListCount(Form ObjKey, string KeyName) global native
int function StringListClear(Form ObjKey, string KeyName) global native
int function StringListFind(Form ObjKey, string KeyName, string value) global native
