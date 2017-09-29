import
    valuePackager

#############################################################################################
# Request id

type 
    RequestType* = enum    
        ADD_NEW_CLASS,                      # Add new class    
        ADD_NEW_FIELD,                      # Add new class field        
        ADD_NEW_INSTANCE,                   # Add new instance
        GET_CLASS_FIELD_VALUE,              # Get class field value
        GET_INSTANCE_FIELD_VALUE,           # Get instance field value
        GET_CLASS_LIST_FIELD_COUNT          # Get class list field count
        GET_INSTANCE_LIST_FIELD_COUNT       # Get instance list field count
        GET_CLASS_LIST_FIELD_VALUE          # Get class list field value
        GET_INSTANCE_LIST_FIELD_VALUE       # Get instance list field value        
        SET_CLASS_FIELD_VALUE,              # Set class field value
        SET_INSTANCE_FIELD_VALUE,           # Set instance field value
        ADD_CLASS_LIST_FIELD_VALUE,         # Add class list field value
        ADD_INSTANCE_LIST_FIELD_VALUE,      # Add instance list field value
        SET_CLASS_LIST_FIELD_VALUE,         # Set class field value
        SET_INSTANCE_LIST_FIELD_VALUE,      # Set instance field value
        REMOVE_CLASS_LIST_FIELD_VALUE,      # Remove class list field value
        REMOVE_INSTANCE_LIST_FIELD_VALUE,   # Remove instance list field value
        CLEAR_CLASS_LIST_FIELD_VALUE,       # Clear class list field value
        CLEAR_INSTANCE_LIST_FIELD_VALUE,    # Clear instance list field value

#############################################################################################
# Response id

# Ok code
const OK_CODE_RESPONSE* = 1
# Error code
const ERROR_CODE_RESPONSE* = 2

#############################################################################################
# Process errors

# Class not found in storage
const CLASS_NOT_FOUND* = 1
# Instance not found in storage
const INSTANCE_NOT_FOUND* = 2
# Field not found in storage
const FIELD_NOT_FOUND* = 3
# Value not found in storage
const VALUE_NOT_FOUND* = 4

import
    limitedStream

type
    # Base packet
    RequestPacket* = object of RootObj
        id* : RequestType

    # Add class request
    AddClassRequest* = object of RequestPacket
        name* : string
        parentId* : uint64

    # Add class request
    AddInstanceRequest* = object of RequestPacket
        name* : string
        classId* : uint64

    # Add field request
    AddFieldRequest* = object of RequestPacket
        name* : string
        classId* : uint64
        isClassField* : bool
        valueType* : uint8

    # Base get field value request
    GetFieldValueRequest* = object of RequestPacket
        fieldId* : uint64

    # Get class field value request
    GetClassFieldValueRequest* = object of GetFieldValueRequest

    # Get instance field value request
    GetInstanceFieldValueRequest* = object of GetFieldValueRequest
        instanceId* : uint64

    # Base get class list field count
    GetListFieldCountRequest* = object of RequestPacket
        fieldId* : uint64

    # Get instance list field count
    GetClassListFieldCountRequest* = object of GetListFieldCountRequest        

    # Get instance list field count
    GetInstanceListFieldCountRequest* = object of GetListFieldCountRequest
        instanceId* : uint64

    # Base get list field value
    GetListFieldValueRequest* = object of GetFieldValueRequest
        start* : int32
        len* : int32

    # Get class list field value
    GetClassListFieldValueRequest* = object of GetListFieldValueRequest    

    # Get instance list field value
    GetInstanceListFieldValueRequest* = object of GetListFieldValueRequest
        instanceId* : uint64    

    # Set value request
    SetValueRequest* = object of RequestPacket

type 
    # Base response
    ResponsePacket* = object of RootObj
        id* : uint8              # Id of packet
        code* : uint8            # Response code

    # Ok response
    OkResponse* = object of ResponsePacket

    # Error response
    ErrorResponse* = object of ResponsePacket
        errorCode* : uint8      # Error code

    GetFieldValueResponse* = object of OkResponse
        value* : Value


#############################################################################################
# RequestPacket


#############################################################################################
# AddClassRequest

proc packAddClass(stream : LimitedStream, packet : AddClassRequest) : void =
    # Pack AddClassRequest    
    stream.addStringWithLen(packet.name)
    stream.addUint64(packet.parentId)

proc unpackAddClass(data : LimitedStream) : AddClassRequest =
    # Unpack to AddClassRequest
    result = AddClassRequest(
        name: data.readStringWithLen(),
        parentId: data.readUint64()
    )

#############################################################################################
# AddInstanceRequest

proc packAddInstance(stream : LimitedStream, packet : AddInstanceRequest) : void =
    # Pack AddInstanceRequest    
    stream.addStringWithLen(packet.name)
    stream.addUint64(packet.classId)

proc unpackAddInstance(data : LimitedStream) : AddInstanceRequest =
    # Unpack to AddInstanceRequest
    result = AddInstanceRequest(
        name: data.readStringWithLen(),
        classId: data.readUint64()
    )

#############################################################################################
# AddFieldRequest

proc packAddField(stream : LimitedStream, packet : AddFieldRequest) : void =
    # Pack AddFieldRequest    
    stream.addStringWithLen(packet.name)
    stream.addUint64(packet.classId)
    stream.addUint8(uint8 packet.isClassField)
    stream.addUint8(packet.valueType)

proc unpackAddField(data : LimitedStream) : AddFieldRequest =
    # Unpack AddFieldRequest
    result = AddFieldRequest(
        name: data.readStringWithLen(),
        classId: data.readUint64(),
        isClassField: bool data.readUint8(),
        valueType: data.readUint8()
    )

#############################################################################################
# ResponsePacket

proc packBaseResponse(stream : LimitedStream, packet : ResponsePacket) : void =
    # Pack base response
    stream.addUint8(packet.id)
    stream.addUint8(packet.code)

#############################################################################################
# OkResponse

proc newOkResponse*(packetId : uint8) : OkResponse =
    # Create new Ok response
    result = OkResponse(
        id : packetId,
        code : OK_CODE_RESPONSE
    )

#############################################################################################
# ErrorResponse

proc newErrorResponse*(packetId : uint8, errorCode : uint8) : ErrorResponse =
    # Create new Ok response
    result = ErrorResponse(
        id : packetId,
        code : ERROR_CODE_RESPONSE,
        errorCode : errorCode
    )

proc packErrorResponse(stream : LimitedStream, packet : ErrorResponse) : void =
    # Pack error response
    packBaseResponse(stream, packet)
    stream.addUint8(packet.errorCode)

#############################################################################################
# GetFieldValueResponse

proc newGetFieldValueResponse*(packetId : uint8, value : Value) : GetFieldValueResponse =
    # Create new GetFieldValueResponse
    result = GetFieldValueResponse(
        id : packetId,
        code : OK_CODE_RESPONSE,
        value : value
    )

proc packGetFieldValueResponse(stream : LimitedStream, packet : GetFieldValueResponse) : void =
    # Pack GetFieldValueResponse
    if packet.value of VInt:
        let v = packet.value.getInt()
        stream.addInt32(v)
    elif packet.value of VFloat:
        let v = packet.value.getFloat()
        stream.addFloat64(v)
    elif packet.value of VString:
        let v = packet.value.getString()
        stream.addStringWithLen(v)
    elif packet.value of VRef:
        let v = packet.value.getRef()
        stream.addUint64(v)
    elif packet.value of VIntArray:
        let v = packet.value.getIntArray()
        for it in v:
            stream.addInt32(it)
    elif packet.value of VFloatArray:
        let v = packet.value.getFloatArray()
        for it in v:
            stream.addFloat64(it)
    elif packet.value of VStringArray:
        let v = packet.value.getStringArray()
        for it in v:
            stream.addStringWithLen(it)
    elif packet.value of VRefArray:
        let v = packet.value.getRefArray()
        for it in v:
            stream.addUint64(it)

#############################################################################################
# Packager api

proc packRequest*(stream : LimitedStream, packet : RequestPacket) : void =
    # Pack request
    case packet.id
    of ADD_NEW_CLASS: packAddClass(stream, AddClassRequest(packet))
    of ADD_NEW_INSTANCE: packAddInstance(stream, AddInstanceRequest(packet))
    of ADD_NEW_FIELD: packAddField(stream, AddFieldRequest(packet))
    of GET_FIELD_VALUE: packAddField(stream, GetFieldValueRequest(packet))
    else:
        raise newException(Exception, "Unknown packet")

proc unpackRequest*(data : LimitedStream) : RequestPacket =
    # Unpack request
    let id = RequestType(data.readUint8())
    case id
    of ADD_NEW_CLASS: result = unpackAddClass(data)
    of ADD_NEW_INSTANCE: result = unpackAddInstance(data)
    of ADD_NEW_FIELD: result = unpackAddField(data)
    else:
        raise newException(Exception, "Unknown packet")

proc packResponse*(stream : LimitedStream, packet : ResponsePacket) : void =
    # Pack response
    if packet of OkResponse: packBaseResponse(stream, OkResponse(packet))
    if packet of ErrorResponse: packErrorResponse(stream, ErrorResponse(packet))
    if packet of GetFieldValueResponse: packGetFieldValueResponse(stream, GetFieldValueResponse(packet))
    else:
        raise newException(Exception, "Unknown packet")
    