import
    asyncdispatch,
    strutils,
    tables,
    times,
    ../../shared/packetPacker,
    ../../shared/streamProducer,
    ../../shared/valuePacker,
    ioDevice,
    entityProducer,
    storage

#############################################################################################
# Private

template throwError(packetId : ResponseType, errorCode : uint8) : void =
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

proc processAddClass(packet : AddClassRequest, response : LimitedStream) : Future[void] {.async.} = 
    # Process add new class packet
    let parent = storage.getClassById(packet.parentId)
    let nclass = entityProducer.newClass(packet.name, parent)
    await storage.storeNewClass(nclass)
    response.packResponse(newOkResponse(ADD_NEW_CLASS_RESPONSE))

proc processAddInstance(packet : AddInstanceRequest, response : LimitedStream) : Future[void] {.async.} = 
    # Process add new instance
    let class = storage.getClassById(packet.classId)
    if class.isNil: throwError(ADD_NEW_INSTANCE_RESPONSE, CLASS_NOT_FOUND)
    let ninstance = entityProducer.newInstance(packet.name, class)
    await storage.storeNewInstance(ninstance)
    response.packResponse(newOkResponse(ADD_NEW_INSTANCE_RESPONSE))

proc processAddField(packet : AddFieldRequest, response : LimitedStream) : Future[void] {.async.} =
    # Process add class field    
    let class = storage.getClassById(packet.classId)    
    let nfield = entityProducer.newField(packet.name, class,packet.isClassField)
    await storage.storeNewField(nfield)
    response.packResponse(newOkResponse(ADD_NEW_FIELD_RESPONSE))

# proc processGetFieldValue(packet : GetFieldValueRequest, response : LimitedStream) : Future[void] {.async.} = 
#     # Process get field value
#     let field = storage.getFieldById(packet.fieldId)
#     if field.isNil: throwError(packet.id, FIELD_NOT_FOUND)        
    
#     var value : Value
#     if field.isClassField and (packet of GetClassFieldValueRequest):
#         value = storage.getFieldValue(field)
#     elif (packet of GetInstanceFieldValueRequest):
#         let pack = GetInstanceFieldValueRequest(packet)
#         let instance = storage.getInstanceById(pack.instanceId)
#         if instance.isNil: throwError(packet.id, INSTANCE_NOT_FOUND)
#         value = storage.getFieldValue(field, instance)
#     else:
#         throwError(packet.id, VALUE_NOT_FOUND)

#     response.packResponse(newGetFieldValueResponse(packet.id, value))

# proc processSetFieldValue(packet : SetValueRequest, response : LimitedStream) : Future[void] {.async.} = 
#     # Process set field value    
#     # var field = storage.getFieldById(packet.fieldId)

#     # if field.isNil: throwError(SET_FIELD_VALUE, FIELD_NOT_FOUND)
#     # let value = packet.readVariant(field.valueType)
#     # storage.setFieldValue(field, value)
#     # response.addOk(SET_FIELD_VALUE)
#     discard

#############################################################################################
# Private

proc processPacket(client : ClientData, packet : LimitedStream) {.async.} =
    # Process packet from client
    let requestPacket = packetPacker.unpackRequest(packet)
    var response : LimitedStream = newLimitedStream()

    case requestPacket.id
    of ADD_NEW_CLASS: await processAddClass(AddClassRequest(requestPacket), response)
    of ADD_NEW_INSTANCE: await processAddInstance(AddInstanceRequest(requestPacket), response)
    of ADD_NEW_FIELD: await processAddField(AddFieldRequest(requestPacket), response)
    #of GET_FIELD_VALUE: await processGetFieldValue(packet, response)
    else:
        raise newException(Exception, "Unknown command")
        
    await ioDevice.send(client, response)
    

#############################################################################################
# Public

proc init*() =
    # Init workspace
    echo "Init packet processor"
    workspace = newWorkspace()
    ioDevice.setOnPacket(processPacket)
    echo "Init packet processor complete"