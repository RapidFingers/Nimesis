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

template throwError(packetId : ResponseType, errorCode : ErrorType, msg : string = "") : void =
    # Throw simple error
    let error = newErrorResponse(packetId, errorCode)
    raise newIoException(error, msg)

#############################################################################################
# Workspace of packet processor
type Workspace = ref object
var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()

proc processAddClass(client : ClientData, packet : AddClassRequest) : Future[void] {.async.} = 
    # Process add new class packet        
    let parent = storage.getClassById(packet.parentId)
    let nclass = entityProducer.newClass(packet.name, parent)
    await storage.storeNewClass(nclass)
    var response = newLimitedStream()
    response.packResponse(newAddClassResponse(nclass.id))
    await ioDevice.send(client, response)

proc processAddInstance(client : ClientData, packet : AddInstanceRequest) : Future[void] {.async.} = 
    # Process add new instance
    let class = storage.getClassById(packet.classId)
    if class.isNil: throwError(ADD_NEW_INSTANCE_RESPONSE, CLASS_NOT_FOUND)
    let ninstance = entityProducer.newInstance(packet.name, class)
    await storage.storeNewInstance(ninstance)
    var response = newLimitedStream()
    response.packResponse(newAddInstanceResponse(ninstance.id))
    await ioDevice.send(client, response)

proc processAddField(client : ClientData, packet : AddFieldRequest) : Future[void] {.async.} =
    # Process add class field
    let class = storage.getClassById(packet.classId)
    if class.isNil: throwError(ADD_NEW_FIELD_RESPONSE, CLASS_NOT_FOUND)
    let nfield = entityProducer.newField(packet.name, class, packet.isClassField, packet.valueType)
    await storage.storeNewField(nfield)
    var response = newLimitedStream()
    response.packResponse(newAddFieldResponse(nfield.id))
    await ioDevice.send(client, response)

proc processGetAllClasses(client : ClientData, packet : GetAllClassRequest) : Future[void] {.async.} =
    # Process get all classes
    var response = newLimitedStream()    
    for c in storage.allClasses():
        if c != nil:
            var resp = newGetAllClassResponse(
                isEnd = false,
                classId = c.id,
                parentId = c.parentId(),
                name = c.name
            )

            for f in c.classFields:
                resp.classFields.add(newFieldInfoResponse(f.id, f.name, f.valueType))
                        
            for f in c.instanceFields:
                resp.instanceFields.add(newFieldInfoResponse(f.id, f.name, f.valueType))

            response.packResponse(resp)
        else:
            response.packResponse(newGetAllClassResponse(
                isEnd = true
            ))
        await ioDevice.send(client, response)
        response.clear()

proc processGetAllInstances(client : ClientData, packet : GetAllInstanceRequest) : Future[void] {.async.} =
    # Process get all instances
    var response = newLimitedStream()    
    for c in storage.allInstances():
        if c != nil:
            let resp = newGetAllInstanceResponse(
                isEnd = false,
                instanceId = c.id,
                classId = c.class.id,
                name = c.name
            )
            response.packResponse(resp)
        else:
            response.packResponse(newGetAllInstanceResponse(
                isEnd = true
            ))
        await ioDevice.send(client, response)
        response.clear()

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

proc processPacket(client : ClientData, packet : LimitedStream) : Future[void] {.async.} =    
    # Process packet from client
    #echo "processPacket"
    #echo packet.len
    let requestPacket = packetPacker.unpackRequest(packet)    
    #echo requestPacket.id
    
    case requestPacket.id
    of ADD_NEW_CLASS: await processAddClass(client, AddClassRequest(requestPacket))
    of ADD_NEW_INSTANCE: await processAddInstance(client, AddInstanceRequest(requestPacket))
    of ADD_NEW_FIELD: await processAddField(client, AddFieldRequest(requestPacket))
    of GET_ALL_CLASSES: await processGetAllClasses(client, GetAllClassRequest(requestPacket))
    of GET_ALL_INSTANCES: await processGetAllInstances(client, GetAllInstanceRequest(requestPacket))
    #of GET_FIELD_VALUE: await processGetFieldValue(packet, response)
    else:
        raise newException(Exception, "Unknown command")
    

#############################################################################################
# Public

proc init*() =
    # Init workspace
    #echo "Init packet processor"
    workspace = newWorkspace()
    ioDevice.setOnPacket(processPacket)
    #echo "Init packet processor complete"