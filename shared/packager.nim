#############################################################################################
# Request id

# Add new class
const ADD_NEW_CLASS* = 1
# Add new class field
const ADD_NEW_FIELD* = 2
# Add new class
const ADD_NEW_INSTANCE* = 3
# Get field value
const GET_FIELD_VALUE* = 4
# Set field value
const SET_FIELD_VALUE* = 5
# Get class by id
const GET_CLASS_BY_ID* = 6
# Get instance by id
const GET_INSTANCE_BY_ID* = 7
# Invoke method
const INVOKE_METHOD_BY_ID* = 8

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
        id* : uint8

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

    # Get class field value request
    GetClassFieldValueRequest* = object of RequestPacket
        fieldId* : uint64

    # Get instance field value request
    GetInstanceFieldValueRequest* = object of RequestPacket
        fieldId* : uint64
        instanceId* : uint64

    # Set value request
    SetValueRequest* = object of RequestPacket

type 
    # Base response
    ResponsePacket* = object of RootObj
        id : uint8              # Id of packet
        code : uint8            # Response code

    # Ok response
    OkResponse* = object of ResponsePacket

    # Error response
    ErrorResponse* = object of ResponsePacket
        errorCode* : uint8      # Error code

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
# Packager api

proc packRequest*(stream : LimitedStream, packet : RequestPacket) : void =
    # Pack request
    case packet.id
    of ADD_NEW_CLASS: packAddClass(stream, AddClassRequest(packet))
    of ADD_NEW_INSTANCE: packAddInstance(stream, AddInstanceRequest(packet))
    of ADD_NEW_FIELD: packAddField(stream, AddFieldRequest(packet))
    else:
        raise newException(Exception, "Unknown packet")

proc unpackRequest*(data : LimitedStream) : RequestPacket =
    # Unpack request
    let id = data.readUint8()
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
    else:
        raise newException(Exception, "Unknown packet")
    