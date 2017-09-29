import
    asyncdispatch,
    strutils,
    tables,
    times,    
    variant,
    ../../shared/packager,
    ../../shared/limitedStream,
    ioDevice,
    producer,
    storage

#############################################################################################
# Private

# proc readStringWithLen(this : LimitedStream) : string = 
#     # Read string from string with len
#     let len = int this.readUint8()
#     result = this.readString(len)

# proc readVariant(this : LimitedStream, valueType : ValueType) : Variant = 
#     # Read value from stream
#     case valueType:
#     of INT:
#         result = newVariant(this.readInt32())
#     else:
#         raise newException(Exception, "Unknown type")

# template addStringWithLen(this : LimitedStream, value : string) : void = 
#     # Add string with len    
#     this.addUint8(uint8 value.len)
#     this.addString(value)

# template addOk(this : LimitedStream, packetId : uint8) : void = 
#     # Add Ok to response
#     this.addUint8(OK_RESPONSE)
#     this.addUint8(packetId)

# template addError(this : LimitedStream, packetId : uint8, errorCode : uint8) : void = 
#     # Add Error to response
#     this.addUint8(ERROR_RESPONSE)
#     this.addUint8(packetId)
#     this.addUint8(errorCode)

# proc addValue(this : LimitedStream, packetId : uint8, value : Value) : void =
#     # Add variant value to response
#     case value.valueType
#     of INT:
#         this.addInt32(value.value.get(int32))
#     else:
#         raise newException(Exception, "Unknown type")
#     discard

template throwError(packetId : int, errorCode : uint8) : void =
    # Throw simple error
    let error = newErrorResponse(packetId, errorCode)
    raise ioDevice.IoException(errorData : error)

#############################################################################################
# Workspace of packet processor
type Workspace = ref object
var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()

proc processAddNewClass(packet : AddClassRequest, response : LimitedStream) : Future[void] {.async.} = 
    # Process add new class packet
    let parent = storage.getClassById(packet.parentId)
    let nclass = producer.newClass(packet.name, parent)
    await storage.storeNewClass(nclass)
    response.packResponse(newOkResponse(packet.id))

proc processAddNewInstance(packet : AddInstanceRequest, response : LimitedStream) : Future[void] {.async.} = 
    # Process add new instance
    let class = storage.getClassById(packet.classId)
    if class.isNil: throwError(ADD_NEW_INSTANCE, CLASS_NOT_FOUND)
    let ninstance = producer.newInstance(packet.name, class)
    await storage.storeNewInstance(ninstance)
    response.packResponse(newOkResponse(packet.id))

proc processAddField(packet : AddFieldRequest, response : LimitedStream) : Future[void] {.async.} =
    # Process add class field    
    let class = storage.getClassById(packet.classId)    
    let nfield = producer.newField(packet.name, class,packet.isClassField)
    await storage.storeNewField(nfield)
    response.packResponse(newOkResponse(packet.id))

# proc processGetClassById(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} = 
#     # Process get class by id
#     let classId = packet.readUint64()
#     let class = storage.getClassById(classId)
#     if class.isNil: throwError(GET_CLASS_BY_ID, CLASS_NOT_FOUND)
#     response.addOk(GET_CLASS_BY_ID)
#     response.addUint64(classId)
#     response.addStringWithLen(class.name)
#     if not class.parent.isNil:
#         response.addUint64(class.parent.id)
#     else:
#         response.addUint64(0)

proc processGetFieldValue(packet : GetValueRequest, response : LimitedStream) : Future[void] {.async.} = 
    # Process get field value
    let fieldId = packet.readUint64()
    let field = storage.getFieldById(fieldId)
    if field.isNil: throwError(GET_FIELD_VALUE, FIELD_NOT_FOUND)        
    
    var value : Value = nil
    if field.isClassField:
        value = storage.getFieldValue(field)
    else:
        let instanceId = packet.readUint64()        
        let instance = storage.getInstanceById(instanceId)
        if instance.isNil: throwError(GET_FIELD_VALUE, INSTANCE_NOT_FOUND)
        value = storage.getFieldValue(field, instance)
        
    if value.isNil: throwError(GET_FIELD_VALUE, VALUE_NOT_FOUND)        
    response.addValue(GET_FIELD_VALUE, value)

proc processSetFieldValue(packet : SetValueRequest, response : LimitedStream) : Future[void] {.async.} = 
    # Process set field value
    let fieldId = packet.readUint64()
    var field : Field = nil
    field = storage.getFieldById(fieldId)

    if field.isNil: throwError(SET_FIELD_VALUE, FIELD_NOT_FOUND)
    let value = packet.readVariant(field.valueType)
    storage.setFieldValue(field, value)
    response.addOk(SET_FIELD_VALUE)

#############################################################################################
# Private

proc processPacket(client : ClientData, packet : LimitedStream) {.async.} =
    # Process packet from client
    let requestPacket = packager.unpackRequest(packet)
    var response : LimitedStream = newLimitedStream()

    case requestPacket.id
    of ADD_NEW_CLASS: await processAddNewClass(AddClassRequest(requestPacket), response)
    of ADD_NEW_INSTANCE: await processAddNewInstance(AddInstanceRequest(requestPacket), response)
    of ADD_NEW_FIELD: await processAddField(AddFieldRequest(requestPacket), response)
    else:
        raise newException(Exception, "Unknown command")

    # let packetId = packet.readUint8()
    # var response : LimitedStream = newLimitedStream()
    # case packetId
    # of ADD_NEW_CLASS:
    #     await processAddNewClass(packet, response)        
    # of GET_FIELD_VALUE:
    #     await processGetFieldValue(packet, response)
    # of SET_FIELD_VALUE:
    #     await processSetFieldValue(packet, response)
    # of GET_CLASS_BY_ID:
    #     await processGetClassById(packet, response)
    # else:
    #     raise newException(Exception, "Unknown command")
        
    await ioDevice.send(client, response)
    

#############################################################################################
# Public

proc init*() =
    # Init workspace
    echo "Init packet processor"
    workspace = newWorkspace()
    ioDevice.setOnPacket(processPacket)
    echo "Init packet processor complete"