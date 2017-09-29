type
    # Possible types of value
    ValueType* = enum
        INT = 0,
        STRING = 1, 
        FLOAT = 2,
        REF_ENTITY = 3,
        INT_ARRAY = 4,
        FLOAT_ARRAY = 5,
        STRING_ARRAY = 6,
        REF_ARRAY = 7

    Value* = object of RootObj

    VInt* = object of Value
        value : int32

    VFloat* = object of Value
        value : float64

    VString* = object of Value
        value : string

    VRef* = object of Value
        value : uint64

    VIntArray* = object of Value
        value : seq[int32]

    VFloatArray* = object of Value
        value : seq[float64]
    
    VStringArray* = object of Value
        value : seq[string]

    VRefArray* = object of Value
        value : seq[uint64]

proc getInt*(this : Value) : int32 =
    # Get int32
    return (VInt(this)).value

proc getFloat*(this : Value) : float64 =
    # Get float64
    return (VFloat(this)).value

proc getString*(this : Value) : string =
    # Get string
    return (VString(this)).value

proc getRef*(this : Value) : uint64 =
    # Get reference
    return (VRef(this)).value

proc getIntArray*(this : Value) : seq[int32] =
    # Get int32 array
    return (VIntArray(this)).value

proc getFloatArray*(this : Value) : seq[float64] =
    # Get float array
    return (VFloatArray(this)).value

proc getStringArray*(this : Value) : seq[string] =
    # Get string array
    return (VStringArray(this)).value

proc getRefArray*(this : Value) : seq[uint64] =
    # Get ref array
    return (VRefArray(this)).value