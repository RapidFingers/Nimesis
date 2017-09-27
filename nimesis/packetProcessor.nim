import
    asyncdispatch,
    strutils,
    tables,
    times,    
    variant,
    ioDevice,    
    producer,
    storage

# Response codes
const OK_RESPONSE = 1
# Error response
const ERROR_RESPONSE = 2

# TODO possibility to iterate return data

# Add new class
const ADD_NEW_CLASS = 1
# Add new class field
const ADD_NEW_FIELD = 2
# Add new class
const ADD_NEW_INSTANCE = 3
# Get field value
const GET_FIELD_VALUE = 4
# Set field value
const SET_FIELD_VALUE = 5
# Get class by id
const GET_CLASS_BY_ID = 6
# Get instance by id
const GET_INSTANCE_BY_ID = 7
# Invoke method
const INVOKE_METHOD_BY_ID = 8

#############################################################################################
# Process errors

# Class not found in storage
const CLASS_NOT_FOUND = 1
# Instance not found in storage
const INSTANCE_NOT_FOUND = 2
# Field not found in storage
const FIELD_NOT_FOUND = 3
# Value not found in storage
const VALUE_NOT_FOUND = 4

#############################################################################################
# Private

type FieldInfo = object
    id : BiggestUInt
    parentId : BiggestUInt
    isClassField : bool

proc readStringWithLen(this : LimitedStream) : string = 
    # Read string from string with len
    let len = int this.readUint8()
    result = this.readString(len)

proc readFieldInfo(this : LimitedStream) : FieldInfo =
    # Read field info from stream
    result.id = this.readUint64()
    result.parentId = this.readUint64()
    result.isClassField = this.readBool()

proc readVariant(this : LimitedStream, valueType : ValueType) : Variant = 
    # Read value from stream
    case valueType:
    of INT:
        result = newVariant(this.readInt32())
    else:
        raise newException(Exception, "Unknown type")

template addStringWithLen(this : LimitedStream, value : string) : void = 
    # Add string with len    
    this.addUint8(uint8 value.len)
    this.addString(value)

template addOk(this : LimitedStream, packetId : uint8) : void = 
    # Add Ok to response
    this.addUint8(OK_RESPONSE)
    this.addUint8(packetId)

template addError(this : LimitedStream, packetId : uint8, errorCode : uint8) : void = 
    # Add Error to response
    this.addUint8(ERROR_RESPONSE)
    this.addUint8(packetId)
    this.addUint8(errorCode)

proc addValue(this : LimitedStream, packetId : uint8, value : Value) : void =
    # Add variant value to response
    case value.valueType
    of INT:
        this.addInt32(value.value.get(int32))
    else:
        raise newException(Exception, "Unknown type")
    discard

template throwError(packetId : int, errorCode : uint8) : void =
    # Throw simple error
    var stream = newLimitedStream()
    stream.addError(packetId, errorCode)
    raise ioDevice.IoException(errorData : stream)

#############################################################################################
# Workspace of packet processor
type Workspace = ref object
var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()

proc processAddNewClass(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} = 
    # Process add new class packet
    let name = packet.readStringWithLen()
    let parentId = packet.readUint64()
    let parent = storage.getClassById(parentId)
    let nclass = producer.newClass(name, parent)
    await storage.storeNewClass(nclass)
    response.addOk(ADD_NEW_CLASS)

proc processAddNewInstance(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} = 
    # Process add new instance
    let name = packet.readStringWithLen()
    let classId = packet.readUint64()
    let class = storage.getClassById(classId)
    if class.isNil: throwError(ADD_NEW_INSTANCE, CLASS_NOT_FOUND)
    let ninstance = producer.newInstance(name, class)
    await storage.storeNewInstance(ninstance)
    response.addOk(ADD_NEW_INSTANCE)

proc processAddField(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} =
    # Process add class field
    let name = packet.readStringWithLen()
    let parentId = packet.readUint64()
    let parent = storage.getClassById(parentId)
    let isClassField = packet.readBool() 
    let nfield = producer.newField(name, parent,isClassField)
    await storage.storeNewField(nfield)
    response.addOk(ADD_NEW_FIELD)

proc processGetClassById(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} = 
    # Process get class by id
    let classId = packet.readUint64()
    echo classId
    let class = storage.getClassById(classId)
    if class.isNil: throwError(GET_CLASS_BY_ID, CLASS_NOT_FOUND)
    response.addOk(GET_CLASS_BY_ID)
    response.addUint64(classId)
    response.addStringWithLen(class.name)
    if not class.parent.isNil:
        response.addUint64(class.parent.id)
    else:
        response.addUint64(0)

proc processGetFieldValue(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} = 
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

proc processSetFieldValue(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} = 
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
    let packetId = packet.readUint8()
    var response : LimitedStream = newLimitedStream()
    case packetId
    of ADD_NEW_CLASS:
        await processAddNewClass(packet, response)
    of ADD_NEW_INSTANCE:
        await processAddNewInstance(packet, response)
    of ADD_NEW_FIELD:
        await processAddField(packet, response)
    of GET_FIELD_VALUE:
        await processGetFieldValue(packet, response)
    of SET_FIELD_VALUE:
        await processSetFieldValue(packet, response)
    of GET_CLASS_BY_ID:
        await processGetClassById(packet, response)
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