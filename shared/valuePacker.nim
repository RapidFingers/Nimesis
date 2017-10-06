type
    # Possible types of value
    ValueType* = enum
        INT                         # Int32 value
        STRING                      # String value
        FLOAT                       # Float64 value
        REF_ENTITY                  # Uint64 reference to entity
        STRUCTURE                   # Structure with data
        INT_ARRAY                   # Int32 array
        FLOAT_ARRAY                 # Float64 array
        STRING_ARRAY                # String array
        REF_ARRAY                   # Reference array
        STRUCTURE_ARRAY             # Structure array

    # Structure base
    StructureBase* = object of RootObj        
    
    # Data of structure
    StructureData* = object of StructureBase
        data* : seq[Value]                  # Structure data

    # Data of single structure
    SingleStructure* = object of StructureData
        id* : uint64                        # Unique id of structure to identetify structure        

    # Structure with data
    ArrayStructure* = object of StructureBase
        id* : uint64                        # Unique id of structure to identetify structure                    
        data* : seq[StructureData]          # Array of structure data

    # Base value
    Value* = ref object of RootObj

    # Int32 value
    VInt* = ref object of Value
        value* : int32

    # Float64 value
    VFloat* = ref object of Value
        value* : float64

    # String value
    VString* = ref object of Value
        value* : string

    # Reference value
    VRef* = ref object of Value
        value* : uint64

    # Data structure value
    VStructure* = ref object of Value
        value* : SingleStructure

    # Array of int32 value
    VIntArray* = ref object of Value
        value : seq[int32]

    # Array of float64 value
    VFloatArray* = ref object of Value
        value* : seq[float64]
    
    # Array of string value
    VStringArray* = ref object of Value
        value* : seq[string]

    # Array of reference value
    VRefArray* = ref object of Value
        value* : seq[uint64]

    # Array of data structure value
    VStructureArray* = ref object of Value
        value* : ArrayStructure

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

proc getStructure*(this : Value) : SingleStructure =
    # Get data structure
    return (VStructure(this)).value

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

proc getStructureArray*(this : Value) : ArrayStructure =
    # Get structure array
    return (VStructureArray(this)).value

proc box*(v : int32) : Value =
    # Box int32 value
    result = VInt(value: v)

proc box*(v : float64) : Value =
    # Box float64 value
    result = VFloat(value: v)

proc box*(v : string) : Value =
    # Box float64 value
    result = VString(value: v)