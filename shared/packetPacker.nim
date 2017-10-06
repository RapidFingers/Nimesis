import    
    strutils,
    streamProducer,
    valuePacker

type 
    RequestType* = enum    
        ADD_NEW_CLASS,                      # Add new class
        ADD_NEW_INSTANCE,                   # Add new instance
        ADD_NEW_FIELD,                      # Add new class field        
        GET_ALL_CLASSES,                    # Get iterate all classes
        GET_ALL_INSTANCES,                  # Get iterate all instances
        UPDATE_CLASS,                       # Update class data
        UPDATE_INSTANCE,                    # Update instance data
        UPDATE_FIELD,                       # Update field data
        REMOVE_CLASS,                       # Remove class
        REMOVE_INSTANCE,                    # Remove instance
        REMOVE_FIELD,                       # Remove field
        GET_VALUE,                          # Get field value        
        GET_LIST_FIELD_COUNT                # Get list field count        
        GET_LIST_FIELD_VALUE                # Get list field value        
        SET_VALUE,                          # Set field value        
        ADD_LIST_FIELD_VALUE,               # Add list field value        
        SET_LIST_FIELD_VALUE,               # Set list field value        
        REMOVE_LIST_FIELD_VALUE,            # Remove list field value        
        CLEAR_LIST_FIELD_VALUE              # Clear list field value        

    ResponseType* = enum
        INTERNAL_ERROR_RESPONSE,
        ADD_NEW_CLASS_RESPONSE,
        ADD_NEW_INSTANCE_RESPONSE,
        ADD_NEW_FIELD_RESPONSE,
        GET_ALL_CLASSES_RESPONSE,
        GET_ALL_INSTANCES_RESPONSE,
        GET_VALUE_RESPONSE

    ResponseCode* = enum
        OK_CODE,
        ERROR_CODE

#############################################################################################
# Process errors

type ErrorType* = enum
    INTERNAL_ERROR,
    CLASS_NOT_FOUND,                        # Class not found in storage    
    INSTANCE_NOT_FOUND,                     # Instance not found in storage
    FIELD_NOT_FOUND,                        # Field not found in storage
    VALUE_NOT_FOUND                         # Value not found in storage

type
    # Base packet
    RequestPacket* = ref object of RootObj
        id* : RequestType

    # Add class request
    AddClassRequest* = ref object of RequestPacket
        name* : string
        parentId* : uint64

    # Add class request
    AddInstanceRequest* = ref object of RequestPacket
        name* : string
        classId* : uint64

    # Add field request
    AddFieldRequest* = ref object of RequestPacket
        name* : string
        classId* : uint64
        isClassField* : bool
        valueType* : ValueType
    
    # Iterate all classes
    GetAllClassRequest* = ref object of RequestPacket

    # Iterate all instances
    GetAllInstanceRequest* = ref object of RequestPacket        

    # Base field value request
    FieldValueRequest* = ref object of RequestPacket
        fieldId* : uint64
        case isClassField* : bool
        of false:
            instanceId* : uint64
        else:
            discard

    # Get field value request
    GetFieldValueRequest* = ref object of FieldValueRequest
    
    # Set field value request
    SetFieldValueRequest* = ref object of FieldValueRequest
        value* : Value

type 
    # Base response
    ResponsePacket* = ref object of RootObj
        id* : ResponseType                      # Id of packet
        code* : ResponseCode                    # Response code

    # Error response
    ErrorResponse* = ref object of ResponsePacket
        errorCode* : ErrorType                  # Error code

    # Add new class response
    OkResponse* = ref object of ResponsePacket

    # Add class response
    AddClassResponse* = ref object of ResponsePacket
        classId* : uint64

    # Add class response
    AddInstanceResponse* = ref object of ResponsePacket
        instanceId* : uint64

    # Add class response
    AddFieldResponse* = ref object of ResponsePacket
        fieldId* : uint64

    GetAllEntityResponse* = ref object of OkResponse
        isEnd* : bool                   # End of data
        classId* : uint64               # Class id
        name* : string                  # Class name

    # Info about class field
    FieldInfoResponse* = ref object of RootObj
        id* : uint64                        # Field id
        name* : string                      # field name
        valueType* : ValueType              # Value type

    # Iterate all classes response
    GetAllClassResponse* = ref object of GetAllEntityResponse
        parentId* : uint64                          # Parent class id
        classFields* : seq[FieldInfoResponse]       # List of class field info
        instanceFields* : seq[FieldInfoResponse]    # List of instance field info
        # classMethods* :
        # instanceMethods* :

    # Iterate all instance response
    GetAllInstanceResponse* = ref object of GetAllEntityResponse
        instanceId* : uint64                        # Instance id

    GetFieldValueResponse* = ref object of OkResponse
        value* : Value

#############################################################################################
# RequestPacket

proc packBaseRequest(stream : LimitedStream, packet : RequestPacket) : void =
    # Pack base request
    stream.addUint8(uint8 packet.id)

#############################################################################################
# AddClassRequest

proc newAddClass*(name : string, parentId : BiggestUInt) : AddClassRequest =
    # Create add class request
    result = AddClassRequest(
        id : ADD_NEW_CLASS,
        name : name,
        parentId : parentId
    )

proc packRequest*(stream : LimitedStream, packet : AddClassRequest) : void =
    # Pack AddClassRequest
    packBaseRequest(stream, packet)
    stream.addStringWithLen(packet.name)
    stream.addUint64(packet.parentId)

proc unpackAddClass(stream : LimitedStream) : AddClassRequest =
    # Unpack to AddClassRequest
    result = AddClassRequest(
        name: stream.readStringWithLen(),
        parentId: stream.readUint64()
    )

#############################################################################################
# AddInstanceRequest

proc newAddInstance*(name : string, classId : BiggestUInt) : AddInstanceRequest =
    # Create add instance request
    result = AddInstanceRequest(
        id : ADD_NEW_INSTANCE,
        name : name,
        classId : classId
    )

proc packRequest*(stream : LimitedStream, packet : AddInstanceRequest) : void =
    # Pack AddInstanceRequest
    packBaseRequest(stream, packet)
    stream.addStringWithLen(packet.name)
    stream.addUint64(packet.classId)

proc unpackAddInstance(stream : LimitedStream) : AddInstanceRequest =
    # Unpack to AddInstanceRequest
    result = newAddInstance(
        name = stream.readStringWithLen(),
        classId = stream.readUint64()
    )

#############################################################################################
# AddFieldRequest

proc newAddField*(name : string, classId : BiggestUInt, isClassField : bool, valueType : ValueType) : AddFieldRequest =
    # Create add field request
    result = AddFieldRequest(
        id : ADD_NEW_FIELD,
        name : name,
        classId : classId,
        isClassField : isClassField,
        valueType : valueType
    )

proc packRequest*(stream : LimitedStream, packet : AddFieldRequest) : void =
    # Pack AddFieldRequest
    packBaseRequest(stream, packet)
    stream.addStringWithLen(packet.name)
    stream.addUint64(packet.classId)
    stream.addUint8(uint8 packet.isClassField)
    stream.addUint8(uint8 packet.valueType)

proc unpackAddField(data : LimitedStream) : AddFieldRequest =
    # Unpack AddFieldRequest
    result = newAddField(
        name = data.readStringWithLen(),
        classId = data.readUint64(),
        isClassField = bool data.readUint8(),
        valueType = ValueType(data.readUint8())
    )

#############################################################################################
# GetFieldValueRequest

proc newGetFieldValueRequest*(fieldId : uint64, isClassField : bool, instanceId : uint64 = 0) : GetFieldValueRequest =
    result = GetFieldValueRequest(
        id : GET_VALUE,
        fieldId : fieldId,
        isClassField : isClassField        
    )

    if isClassField:
        result.instanceId = instanceId

proc packRequest*(stream : LimitedStream, packet : GetFieldValueRequest) : void =
    # Pack GetFieldValueRequest
    packBaseRequest(stream, packet)    
    stream.addUint64(packet.fieldId)
    stream.addUint8(uint8 packet.isClassField)
    if packet.isClassField:
        stream.addUint64(packet.instanceId)

proc unpackGetFieldValue(data : LimitedStream) : GetFieldValueRequest =
    # Unpack AddFieldRequest
    result = newGetFieldValueRequest(
        fieldId = data.readUint64(),
        isClassField = bool data.readUint8()
    )

    if result.isClassField:
        result.instanceId = data.readUint64()

#############################################################################################
# GetAllClassRequest

proc newGetAllClass*() : GetAllClassRequest =
    # Create get all classes
    result = GetAllClassRequest(
        id : GET_ALL_CLASSES
    )

proc packRequest*(stream : LimitedStream, packet : GetAllClassRequest) : void =
    # Pack GetAllClassRequest
    packBaseRequest(stream, packet)

proc unpackGetAllClass(stream : LimitedStream) : GetAllClassRequest =
    # Unpack GetAllClassRequest
    result = newGetAllClass()

#############################################################################################
# GetAllInstanceRequest

proc newGetAllInstance*() : GetAllInstanceRequest =
    # Create get all instances
    result = GetAllInstanceRequest(
        id : GET_ALL_INSTANCES
    )

proc packRequest*(stream : LimitedStream, packet : GetAllInstanceRequest) : void =
    # Pack GetAllInstanceRequest
    packBaseRequest(stream, packet)

proc unpackGetAllInstance(data : LimitedStream) : GetAllInstanceRequest =
    # Unpack GetAllInstanceRequest
    result = newGetAllInstance()

#############################################################################################
# ResponsePacket

proc packBaseResponse(stream : LimitedStream, packet : ResponsePacket) : void =
    # Pack base response
    stream.addUint8(uint8 packet.id)
    stream.addUint8(uint8 packet.code)

#############################################################################################
# OkResponse

proc newOkResponse*(packetId : ResponseType) : OkResponse =
    # Create new Ok response
    result = OkResponse(
        id : packetId,
        code : OK_CODE
    )

proc packResponse*(stream : LimitedStream, packet : OkResponse) : void =
    # Pack ok response
    packBaseResponse(stream, packet)

#############################################################################################
# ErrorResponse

proc newErrorResponse*(packetId : ResponseType, errorCode : ErrorType) : ErrorResponse =
    # Create new Ok response
    result = ErrorResponse(
        id : packetId,
        code : ERROR_CODE,
        errorCode : errorCode
    )

proc newInternalErrorResponse*() : ErrorResponse =
    result = ErrorResponse(
        id : INTERNAL_ERROR_RESPONSE,
        code : ERROR_CODE,
        errorCode : INTERNAL_ERROR
    )

proc packResponse*(stream : LimitedStream, packet : ErrorResponse) : void =
    # Pack error response
    packBaseResponse(stream, packet)
    stream.addUint8(uint8 packet.errorCode)

#############################################################################################
# AddClassResponse

proc newAddClassResponse*(classId : uint64) : AddClassResponse =
    # Add class response
    result = AddClassResponse(
        id : ADD_NEW_CLASS_RESPONSE,
        code : OK_CODE,
        classId : classId
    )

proc packResponse*(stream : LimitedStream, packet : AddClassResponse) : void =
    # Pack AddClassResponse
    packBaseResponse(stream, packet)
    stream.addUint64(packet.classId)

proc unpackAddClassResponse(stream : LimitedStream) : AddClassResponse =
    # Unpack add class response
    result = newAddClassResponse(
        classId = stream.readUint64()
    )

#############################################################################################
# AddInstanceResponse

proc newAddInstanceResponse*(instanceId : uint64) : AddInstanceResponse =
    # Add instance response
    result = AddInstanceResponse(
        id : ADD_NEW_INSTANCE_RESPONSE,
        code : OK_CODE,
        instanceId : instanceId
    )

proc packResponse*(stream : LimitedStream, packet : AddInstanceResponse) : void =
    # Pack AddClassResponse
    packBaseResponse(stream, packet)
    stream.addUint64(packet.instanceId)

proc unpackAddInstanceResponse(stream : LimitedStream) : AddInstanceResponse =
    # Unpack add instance response
    result = newAddInstanceResponse(
        instanceId = stream.readUint64()
    )

#############################################################################################
# AddFieldResponse

proc newAddFieldResponse*(fieldId : uint64) : AddFieldResponse =
    # Add instance response
    result = AddFieldResponse(
        id : ADD_NEW_FIELD_RESPONSE,
        code : OK_CODE,
        fieldId : fieldId
    )

proc packResponse*(stream : LimitedStream, packet : AddFieldResponse) : void =
    # Pack AddClassResponse
    packBaseResponse(stream, packet)
    stream.addUint64(packet.fieldId)

proc unpackAddFieldResponse(stream : LimitedStream) : AddFieldResponse =
    # Unpack add instance response
    result = newAddFieldResponse(
        fieldId = stream.readUint64()
    )

#############################################################################################
# FieldInfoResponse

proc newFieldInfoResponse*(id : uint64, name : string, valueType : ValueType) : FieldInfoResponse =
    # Create new field info response
    result = FieldInfoResponse(
        id : id,
        name : name,
        valueType : valueType
    )

proc packResponse*(stream : LimitedStream, packet : FieldInfoResponse) : void =
    # Pack FieldInfoResponse
    stream.addUint64(packet.id)
    stream.addStringWithLen(packet.name)
    stream.addUint8(uint8 packet.valueType)

proc unpackFieldInfoResponse*(stream : LimitedStream) : FieldInfoResponse =
    # Unpack FieldInfoResponse
    result = newFieldInfoResponse(
        id = stream.readUint64(),
        name = stream.readStringWithLen(),
        valueType = ValueType(stream.readUint8())
    )

#############################################################################################
# GetAllClassResponse

proc newGetAllClassResponse*(isEnd : bool, classId : uint64 = 0, parentId : uint64 = 0, name : string = "") : GetAllClassResponse =
    # Create new get all class response
    result = GetAllClassResponse(
        id : GET_ALL_CLASSES_RESPONSE,
        code : OK_CODE,
        isEnd : isEnd,
        classId : classId,
        parentId : parentId,
        name : name,
        classFields : @[],
        instanceFields : @[]
    )

proc packResponse*(stream : LimitedStream, packet : GetAllClassResponse) : void =
    # Pack GetAllClassResponse
    packBaseResponse(stream, packet)
    stream.addBool(packet.isEnd)
    if not packet.isEnd:        
        stream.addUint64(packet.classId)
        stream.addUint64(packet.parentId)
        stream.addStringWithLen(packet.name)
        stream.addLength(uint32 packet.classFields.len)
        for f in packet.classFields:
            packResponse(stream, f)
        stream.addLength(uint32 packet.instanceFields.len)
        for f in packet.instanceFields:
            packResponse(stream, f)

proc unpackGetAllClassesResponse(stream : LimitedStream) : GetAllClassResponse =
    # Unpack all classes response
    let isEnd = stream.readBool()
    if not isEnd:        
        result = newGetAllClassResponse(
            isEnd = isEnd,
            classId = stream.readUint64(),
            parentId = stream.readUint64(),
            name = stream.readStringWithLen(),            
        )

        let classFieldsLen = stream.readLength()        
        
        for i in 0..<classFieldsLen:
            result.classFields.add(stream.unpackFieldInfoResponse())

        let instanceFieldsLen = stream.readLength()
        for i in 0..<instanceFieldsLen:
            result.instanceFields.add(unpackFieldInfoResponse(stream))
    else:
        result = newGetAllClassResponse(
            isEnd = isEnd
        )        

#############################################################################################
# GetAllInstanceResponse

proc newGetAllInstanceResponse*(isEnd : bool, instanceId : uint64 = 0, classId : uint64 = 0, name : string = "") : GetAllInstanceResponse =
    # Create new GetAllInstanceResponse
    result = GetAllInstanceResponse(
        id : GET_ALL_INSTANCES_RESPONSE,
        instanceId : instanceId,
        classId : classId,
        isEnd : isEnd,    
        name : name    
    )

proc packResponse*(stream : LimitedStream, packet : GetAllInstanceResponse) : void =
    # Pack GetAllInstanceRequest
    packBaseResponse(stream, packet)
    stream.addBool(packet.isEnd)
    if not packet.isEnd:        
        stream.addUint64(packet.instanceId)
        stream.addUint64(packet.classId)
        stream.addStringWithLen(packet.name)

proc unpackGetAllInstanceResponse(stream : LimitedStream) : GetAllInstanceResponse =
    # Unpack all classes response
    let isEnd = stream.readBool()
    if not isEnd:        
        result = newGetAllInstanceResponse(
            isEnd = isEnd,
            instanceId = stream.readUint64(),
            classId = stream.readUint64(),
            name = stream.readStringWithLen(),            
        )        
    else:
        result = newGetAllInstanceResponse(
            isEnd = isEnd
        )  

#############################################################################################
# GetFieldValueResponse

proc newGetFieldValueResponse*(value : Value) : GetFieldValueResponse =
    # Create new GetFieldValueResponse
    result = GetFieldValueResponse(
        id : GET_VALUE_RESPONSE,
        code : OK_CODE,
        value : value
    )

proc packResponse*(stream : LimitedStream, packet : GetFieldValueResponse) : void =
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

proc unpackGetFieldValueResponse(stream : LimitedStream) : GetFieldValueResponse =
    # Unpack GetFieldValueResponse
    discard

#############################################################################################
# Packager api

proc unpackRequest*(data : LimitedStream) : RequestPacket =
    # Unpack request    
    let id = RequestType(data.readUint8())
    case id
    of ADD_NEW_CLASS: result = unpackAddClass(data)
    of ADD_NEW_INSTANCE: result = unpackAddInstance(data)
    of ADD_NEW_FIELD: result = unpackAddField(data)
    of GET_ALL_CLASSES: result = unpackGetAllClass(data)
    of GET_ALL_INSTANCES: result = unpackGetAllInstance(data)
    of GET_VALUE: result = unpackGetFieldValue(data)
    else:
        raise newException(Exception, "Unknown request packet")

proc unpackResponse(id : ResponseType, code : ResponseCode, data : LimitedStream) : ResponsePacket =
    # Unpack response with some data or not
    case id    
    of ADD_NEW_CLASS_RESPONSE: result = unpackAddClassResponse(data)
    of ADD_NEW_INSTANCE_RESPONSE: result = unpackAddInstanceResponse(data)
    of ADD_NEW_FIELD_RESPONSE: result = unpackAddFieldResponse(data)
    of GET_ALL_CLASSES_RESPONSE: result = unpackGetAllClassesResponse(data)
    of GET_ALL_INSTANCES_RESPONSE: result = unpackGetAllInstanceResponse(data)
    of GET_VALUE_RESPONSE: result = unpackGetFieldValueResponse(data)
    else:
        result = OkResponse()
    result.id = id
    result.code = code

proc unpackResponse*(data : LimitedStream) : ResponsePacket =
    # Unpack response
    let id = ResponseType(data.readUint8())
    let code = ResponseCode(data.readUint8())
    case code
    of OK_CODE: result = unpackResponse(id, code, data)
    of ERROR_CODE:
        result = ErrorResponse(
            id : id,
            code : code,
            errorCode : ErrorType(data.readUint8())
        )
    else:
        raise newException(Exception, "Unknown responce code")

proc unpackResponse*(data : string) : ResponsePacket =
    # Unpack response
    var stream = newLimitedStream()
    stream.setData(data)
    result = unpackResponse(stream)